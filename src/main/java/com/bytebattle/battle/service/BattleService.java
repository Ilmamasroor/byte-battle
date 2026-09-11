package com.bytebattle.battle.service;

import com.bytebattle.battle.dto.*;
import com.bytebattle.battle.entity.Attempt;
import com.bytebattle.battle.entity.Battle;
import com.bytebattle.battle.entity.BattleQuestion;
import com.bytebattle.battle.entity.BattleSession;
import com.bytebattle.battle.enums.AttemptStatus;
import com.bytebattle.battle.enums.BattleSessionStatus;
import com.bytebattle.battle.enums.BattleStatus;
import com.bytebattle.battle.repository.AttemptRepository;
import com.bytebattle.battle.repository.BattleQuestionRepository;
import com.bytebattle.battle.repository.BattleRepository;
import com.bytebattle.battle.repository.BattleSessionRepository;
import com.bytebattle.battle.validator.BattleStateValidator;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
public class BattleService {

    private final BattleRepository battleRepository;
    private final BattleQuestionRepository battleQuestionRepository;
    private final BattleSessionRepository battleSessionRepository;
    private final AttemptRepository attemptRepository;
    private final BattleStateValidator battleStateValidator;
    private final ScoringService scoringService;

    public BattleService(BattleRepository battleRepository,
                          BattleQuestionRepository battleQuestionRepository,
                          BattleSessionRepository battleSessionRepository,
                          AttemptRepository attemptRepository,
                          BattleStateValidator battleStateValidator,
                          ScoringService scoringService) {
        this.battleRepository = battleRepository;
        this.battleQuestionRepository = battleQuestionRepository;
        this.battleSessionRepository = battleSessionRepository;
        this.attemptRepository = attemptRepository;
        this.battleStateValidator = battleStateValidator;
        this.scoringService = scoringService;
    }

    // ---- Lookup -------------------------------------------------------

    public BattleResponse getBattle(UUID battleId) {
        return battleRepository.findById(battleId)
                .map(this::toBattleResponse)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Battle not found"));
    }

    // ---- Start a session ------------------------------------------------

    public StartBattleResponse startBattle(UUID battleId, StartBattleRequest request) {
        Battle battle = battleRepository.findById(battleId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Battle not found"));

        BattleQuestion firstQuestion = battleQuestionRepository
                .findByBattleIdOrderByDisplayOrderAsc(battleId)
                .stream()
                .findFirst()
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.CONFLICT, "Battle has no questions configured"));

        BattleSession session = BattleSession.builder()
                .battleId(battleId)
                .userId(request.userId())
                .status(BattleSessionStatus.ACTIVE)
                .currentQuestionNumber(1)
                .score(0)
                .remainingLives(battle.getTotalLives())
                .startedAt(Instant.now())
                .expiresAt(Optional.ofNullable(battle.getTimeLimitSeconds())
                        .map(limit -> Instant.now().plusSeconds((long) limit * battle.getTotalQuestions()))
                        .orElse(null))
                .build();

        BattleSession saved = battleSessionRepository.save(session);

        return StartBattleResponse.builder()
                .sessionId(saved.getId())
                .firstQuestion(toQuestionResponse(firstQuestion))
                .remainingLives(saved.getRemainingLives())
                .timeLimitSeconds(battle.getTimeLimitSeconds())
                .build();
    }

    // ---- Submit an answer (single transactional boundary — doc §48) ----

    @Transactional
    public SubmitAnswerResponse submitAnswer(UUID sessionId, UUID userId, SubmitAnswerRequest request) {

        BattleSession session = battleStateValidator.requireOwnedSession(sessionId, userId);
        battleStateValidator.requireActiveSession(session);

        BattleQuestion question = battleQuestionRepository.findById(request.battleQuestionId())
                .map(q -> battleStateValidator.requireQuestionInBattle(q, session.getBattleId()))
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Question not found"));

        battleStateValidator.requireNotAlreadyAnswered(sessionId, question.getId());

        Battle battle = battleRepository.findById(session.getBattleId())
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Battle not found"));

        boolean correct = Optional.ofNullable(question.getCorrectAnswer())
                .map(expected -> expected.trim().equalsIgnoreCase(request.answer().trim()))
                .orElse(false);

        int pointsEarned = scoringService.calculatePoints(
                correct,
                battle.getDifficulty(),
                request.timeTakenSeconds(),
                battle.getTimeLimitSeconds(),
                question.getPoints());

        attemptRepository.save(Attempt.builder()
                .battleSessionId(sessionId)
                .battleQuestionId(question.getId())
                .answer(request.answer())
                .correct(correct)
                .pointsEarned(pointsEarned)
                .timeTakenSeconds(request.timeTakenSeconds())
                .status(AttemptStatus.SUBMITTED)
                .attemptedAt(Instant.now())
                .build());

        int remainingLives = correct ? session.getRemainingLives() : session.getRemainingLives() - 1;
        int currentScore = session.getScore() + pointsEarned;

        Optional<BattleQuestion> nextQuestion = battleQuestionRepository
                .findByBattleIdOrderByDisplayOrderAsc(session.getBattleId())
                .stream()
                .filter(q -> q.getDisplayOrder() > question.getDisplayOrder())
                .findFirst();

        boolean sessionCompleted = remainingLives <= 0 || nextQuestion.isEmpty();

        session.setScore(currentScore);
        session.setRemainingLives(remainingLives);
        session.setCurrentQuestionNumber(session.getCurrentQuestionNumber() + 1);
        session.setStatus(sessionCompleted ? BattleSessionStatus.COMPLETED : BattleSessionStatus.ACTIVE);

        Optional.of(sessionCompleted)
                .filter(Boolean::booleanValue)
                .ifPresent(done -> session.setCompletedAt(Instant.now()));

        battleSessionRepository.save(session);

        return SubmitAnswerResponse.builder()
                .correct(correct)
                .pointsEarned(pointsEarned)
                .remainingLives(remainingLives)
                .currentScore(currentScore)
                .sessionCompleted(sessionCompleted)
                .nextQuestion(nextQuestion.map(this::toQuestionResponse).orElse(null))
                .build();
    }

    // ---- Result -----------------------------------------------------

    public BattleResultResponse getResult(UUID sessionId, UUID userId) {
        BattleSession session = battleStateValidator.requireOwnedSession(sessionId, userId);

        long correctAnswers = attemptRepository.findByBattleSessionId(sessionId)
                .stream()
                .filter(Attempt::getCorrect)
                .count();

        Battle battle = battleRepository.findById(session.getBattleId())
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Battle not found"));

        return BattleResultResponse.builder()
                .sessionId(sessionId)
                .finalScore(session.getScore())
                .totalQuestions(battle.getTotalQuestions())
                .correctAnswers((int) correctAnswers)
                .won(session.getRemainingLives() > 0)
                .build();
    }

    // ---- Mapping helpers ---------------------------------------------

    private BattleResponse toBattleResponse(Battle battle) {
        return BattleResponse.builder()
                .id(battle.getId())
                .conceptId(battle.getConceptId())
                .title(battle.getTitle())
                .description(battle.getDescription())
                .battleType(battle.getBattleType())
                .difficulty(battle.getDifficulty())
                .totalQuestions(battle.getTotalQuestions())
                .timeLimitSeconds(battle.getTimeLimitSeconds())
                .totalLives(battle.getTotalLives())
                .status(battle.getStatus())
                .build();
    }

    private BattleQuestionResponse toQuestionResponse(BattleQuestion question) {
        return BattleQuestionResponse.builder()
                .id(question.getId())
                .questionText(question.getQuestionText())
                .questionType(question.getQuestionType())
                .options(question.getOptions())
                .points(question.getPoints())
                .displayOrder(question.getDisplayOrder())
                .build();
    }
    
    @Transactional
    public BattleResponse createBattle(CreateBattleRequest request) {
        Battle battle = battleRepository.save(Battle.builder()
                .conceptId(request.conceptId())
                .title(request.title())
                .description(request.description())
                .battleType(request.battleType())
                .difficulty(request.difficulty())
                .totalQuestions(request.totalQuestions())
                .timeLimitSeconds(request.timeLimitSeconds())
                .totalLives(request.totalLives())
                .status(BattleStatus.DRAFT)
                .build());
        return toBattleResponse(battle);
    }

    @Transactional
    public BattleResponse updateBattle(UUID battleId, UpdateBattleRequest request) {
        Battle battle = battleRepository.findById(battleId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Battle not found"));

        Optional.ofNullable(request.title()).ifPresent(battle::setTitle);
        Optional.ofNullable(request.description()).ifPresent(battle::setDescription);
        Optional.ofNullable(request.difficulty()).ifPresent(battle::setDifficulty);
        Optional.ofNullable(request.status()).ifPresent(battle::setStatus);

        return toBattleResponse(battleRepository.save(battle));
    }

    @Transactional
    public void deleteBattle(UUID battleId) {
        battleRepository.findById(battleId)
                .ifPresentOrElse(
                        battleRepository::delete,
                        () -> { throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Battle not found"); }
                );
    }

    public List<BattleResponse> listBattles() {
        return battleRepository.findAll().stream()
                .map(this::toBattleResponse)
                .toList();
    }

    @Transactional
    public BattleQuestionResponse addQuestion(UUID battleId, CreateBattleQuestionRequest request) {
        battleRepository.findById(battleId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Battle not found"));

        BattleQuestion question = battleQuestionRepository.save(BattleQuestion.builder()
                .battleId(battleId)
                .questionText(request.questionText())
                .questionType(request.questionType())
                .options(request.options())
                .correctAnswer(request.correctAnswer())
                .explanation(request.explanation())
                .points(request.points())
                .displayOrder(request.displayOrder())
                .build());

        return toQuestionResponse(question);
    }

    public List<BattleQuestionResponse> listQuestions(UUID battleId) {
        return battleQuestionRepository.findByBattleIdOrderByDisplayOrderAsc(battleId).stream()
                .map(this::toQuestionResponse)
                .toList();
    }
}