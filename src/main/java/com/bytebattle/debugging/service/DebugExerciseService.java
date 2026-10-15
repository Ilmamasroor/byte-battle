package com.bytebattle.debugging.service;

import com.bytebattle.coding.dto.ExecutionRequest;
import com.bytebattle.coding.dto.ExecutionResult;
import com.bytebattle.coding.dto.TestCaseResultResponse;
import com.bytebattle.coding.enums.CodingSubmissionStatus;
import com.bytebattle.coding.execution.CodeExecutor;
import com.bytebattle.coding.testcase.CodingTestCase;
import com.bytebattle.coding.testcase.CodingTestCases;
import com.bytebattle.debugging.dto.DebugExerciseDtos.*;
import com.bytebattle.debugging.entity.DebugAttempt;
import com.bytebattle.debugging.entity.DebugExercise;
import com.bytebattle.debugging.enums.ErrorCategory;
import com.bytebattle.debugging.repository.DebugAttemptRepository;
import com.bytebattle.debugging.repository.DebugExerciseRepository;
import com.bytebattle.performance.dto.CreatePerformanceRecordRequest;
import com.bytebattle.performance.enums.ActivityType;
import com.bytebattle.learning.service.ActivityEvidenceEvent;
import com.bytebattle.learning.service.ProgressionService;
import com.bytebattle.ai.service.PersonalizationAiService.ActivityEvidence;
import org.springframework.context.ApplicationEventPublisher;
import com.bytebattle.performance.service.PerformanceService;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * Debugging-exercise flow: learner gets buggy code, submits a fix, it runs through the same Judge0 executor
 * as coding challenges (hidden-case rules apply), the attempt is recorded and a PerformanceRecord is written.
 * Deliberately not @Transactional: no DB transaction is held open while Judge0 runs.
 */
@Service
public class DebugExerciseService {

    private static final Logger log = LoggerFactory.getLogger(DebugExerciseService.class);

    public static final int DIAGNOSE_AFTER_FAILURES = 2;
    public static final int PERSISTENT_WEAKNESS_AFTER_FAILURES = 3;
    private static final int MAX_CODE_CHARS = 100_000;

    private final DebugExerciseRepository exerciseRepository;
    private final DebugAttemptRepository attemptRepository;
    private final CodeExecutor codeExecutor;
    private final PerformanceService performanceService;
    private final ObjectMapper objectMapper;
    private final ProgressionService progressionService;
    private final ApplicationEventPublisher eventPublisher;

    public DebugExerciseService(
            DebugExerciseRepository exerciseRepository,
            DebugAttemptRepository attemptRepository,
            CodeExecutor codeExecutor,
            PerformanceService performanceService,
            ObjectMapper objectMapper,
            ProgressionService progressionService,
            ApplicationEventPublisher eventPublisher) {
        this.exerciseRepository = exerciseRepository;
        this.attemptRepository = attemptRepository;
        this.codeExecutor = codeExecutor;
        this.performanceService = performanceService;
        this.objectMapper = objectMapper;
        this.progressionService = progressionService;
        this.eventPublisher = eventPublisher;
    }

    // ------------------------------------------------------------ learner

    public List<ExerciseSummary> list(UUID conceptId) {
        List<DebugExercise> exercises = conceptId == null
                ? exerciseRepository.findAllByOrderByCreatedAtAsc()
                : exerciseRepository.findByConceptIdOrderByCreatedAtAsc(conceptId);
        return exercises.stream()
                .map(e -> new ExerciseSummary(e.getId(), e.getConceptId(), e.getTitle(), e.getLanguage(),
                        e.getBugCategory(), e.getDifficulty()))
                .toList();
    }

    public ExerciseDetail get(UUID exerciseId) {
        DebugExercise e = require(exerciseId);
        List<CodingTestCase> cases = CodingTestCases.parseLenient(e.getTestCasesJson());
        List<SampleTest> samples = new ArrayList<>();
        for (int i = 0; i < cases.size(); i++) {
            if (!cases.get(i).hidden()) {
                samples.add(new SampleTest(i + 1, cases.get(i).input(), cases.get(i).expectedOutput()));
            }
        }
        return new ExerciseDetail(e.getId(), e.getConceptId(), e.getTitle(), e.getDescription(), e.getLanguage(),
                e.getBuggyCode(), e.getBugCategory(), e.getDifficulty(), cases.size(),
                (int) cases.stream().filter(CodingTestCase::hidden).count(),
                hintLadder(e).size(), samples);
    }

    public AttemptResponse attempt(UUID userId, UUID exerciseId, AttemptRequest request) {
        DebugExercise exercise = require(exerciseId);

        if (request.code().length() > MAX_CODE_CHARS) {
            throw new ResponseStatusException(HttpStatus.PAYLOAD_TOO_LARGE, "Source code exceeds the 100 KB limit");
        }

        ExecutionResult result;
        try {
            result = codeExecutor.execute(new ExecutionRequest(
                    request.code(), exercise.getLanguage(), exercise.getTestCasesJson(), null, null));
        } catch (IllegalArgumentException e) {
            throw e;
        } catch (RuntimeException e) {
            log.error("Unexpected code execution failure for debug exercise {}", exerciseId, e);
            result = ExecutionResult.unavailable("Code execution failed unexpectedly");
        }

        if (result.unavailable()) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE,
                    "Code execution is temporarily unavailable. Your attempt was not judged; please try again shortly.");
        }

        boolean passed = result.status() == CodingSubmissionStatus.PASSED;
        ErrorCategory category = passed ? null : categorize(result.status());

        DebugAttempt previousLatest = attemptRepository
                .findTopByUserIdAndExerciseIdOrderByCreatedAtDesc(userId, exerciseId).orElse(null);
        int carriedHints = previousLatest == null ? 0 : previousLatest.getHintsUsed();

        DebugAttempt saved = attemptRepository.save(DebugAttempt.builder()
                .userId(userId)
                .exerciseId(exerciseId)
                .submittedCode(request.code())
                .status(result.status().name())
                .testsPassed(result.testCasesPassed())
                .testsTotal(result.testCasesTotal())
                .errorCategory(category)
                .hintsUsed(carriedHints)
                .build());

        long attemptCount = attemptRepository.countByUserIdAndExerciseId(userId, exerciseId);
        int failures = consecutiveFailures(userId, exerciseId);

        recordPerformance(userId, exercise, result, passed, request.timeSpentSeconds(), attemptCount, saved.getHintsUsed());

        String nextAction = passed ? "CONTINUE" : failures >= DIAGNOSE_AFTER_FAILURES ? "DIAGNOSE" : "RETRY";

        return new AttemptResponse(
                saved.getId(),
                exerciseId,
                result.status().name(),
                passed,
                result.testCasesPassed(),
                result.testCasesTotal(),
                category,
                result.errorMessage(),
                saved.getHintsUsed(),
                failures,
                nextAction,
                !passed && failures >= PERSISTENT_WEAKNESS_AFTER_FAILURES,
                result.testCaseOutcomes().stream().map(TestCaseResultResponse::from).toList());
    }

    public HintResponse hint(UUID userId, UUID exerciseId, int level) {
        DebugExercise exercise = require(exerciseId);
        List<String> ladder = hintLadder(exercise);
        if (ladder.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "No hints are available for this exercise");
        }
        if (level < 1 || level > ladder.size()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Hint level must be between 1 and " + ladder.size());
        }

        DebugAttempt latest = attemptRepository
                .findTopByUserIdAndExerciseIdOrderByCreatedAtDesc(userId, exerciseId).orElse(null);
        int hintsUsed = 0;
        boolean counted = false;
        if (latest != null) {
            latest.setHintsUsed(Math.max(latest.getHintsUsed(), level));
            attemptRepository.save(latest);
            hintsUsed = latest.getHintsUsed();
            counted = true;
        }
        return new HintResponse(level, ladder.size(), ladder.get(level - 1), hintsUsed, counted);
    }

    // ------------------------------------------------------------ admin

    public List<AdminExerciseResponse> adminList() {
        return exerciseRepository.findAllByOrderByCreatedAtAsc().stream().map(this::toAdmin).toList();
    }

    public AdminExerciseResponse adminGet(UUID id) {
        return toAdmin(require(id));
    }

    public AdminExerciseResponse adminCreate(AdminExerciseRequest request) {
        validateTestCases(request.testCasesJson());
        validateHintLadder(request.hintLadderJson());
        return toAdmin(exerciseRepository.save(DebugExercise.builder()
                .conceptId(request.conceptId())
                .title(request.title())
                .description(request.description())
                .buggyCode(request.buggyCode())
                .language(request.language())
                .testCasesJson(request.testCasesJson())
                .hintLadderJson(request.hintLadderJson())
                .bugCategory(request.bugCategory())
                .difficulty(request.difficulty())
                .solutionCode(request.solutionCode())
                .build()));
    }

    public AdminExerciseResponse adminUpdate(UUID id, AdminExerciseUpdate update) {
        DebugExercise e = require(id);
        if (update.conceptId() != null) e.setConceptId(update.conceptId());
        if (update.title() != null) e.setTitle(update.title());
        if (update.description() != null) e.setDescription(update.description());
        if (update.buggyCode() != null) e.setBuggyCode(update.buggyCode());
        if (update.language() != null) e.setLanguage(update.language());
        if (update.testCasesJson() != null) {
            validateTestCases(update.testCasesJson());
            e.setTestCasesJson(update.testCasesJson());
        }
        if (update.hintLadderJson() != null) {
            validateHintLadder(update.hintLadderJson());
            e.setHintLadderJson(update.hintLadderJson());
        }
        if (update.bugCategory() != null) e.setBugCategory(update.bugCategory());
        if (update.difficulty() != null) e.setDifficulty(update.difficulty());
        if (update.solutionCode() != null) e.setSolutionCode(update.solutionCode());
        return toAdmin(exerciseRepository.save(e));
    }

    public void adminDelete(UUID id) {
        exerciseRepository.delete(require(id));
    }

    // ------------------------------------------------------------ helpers

    private DebugExercise require(UUID id) {
        return exerciseRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Debug exercise not found"));
    }

    private int consecutiveFailures(UUID userId, UUID exerciseId) {
        int failures = 0;
        for (DebugAttempt a : attemptRepository.findTop10ByUserIdAndExerciseIdOrderByCreatedAtDesc(userId, exerciseId)) {
            if (CodingSubmissionStatus.PASSED.name().equals(a.getStatus())) {
                break;
            }
            failures++;
        }
        return failures;
    }

    static ErrorCategory categorize(CodingSubmissionStatus status) {
        return switch (status) {
            case COMPILATION_ERROR -> ErrorCategory.COMPILATION_ERROR;
            case TIMEOUT -> ErrorCategory.TIMEOUT;
            case FAILED -> ErrorCategory.LOGIC_ERROR;
            default -> ErrorCategory.RUNTIME_ERROR;
        };
    }

    private void recordPerformance(UUID userId, DebugExercise exercise, ExecutionResult result, boolean passed,
                                   Integer timeSpentSeconds, long attemptCount, int hintsUsed) {
        double accuracy = result.testCasesTotal() > 0
                ? (double) result.testCasesPassed() / result.testCasesTotal() : 0.0;
        int time = timeSpentSeconds == null ? 0 : Math.max(0, Math.min(timeSpentSeconds, 86_400));
        performanceService.createRecord(new CreatePerformanceRecordRequest(
                userId,
                exercise.getConceptId(),
                ActivityType.DEBUGGING,
                (int) Math.round(accuracy * 100.0),
                accuracy,
                time,
                (int) Math.min(attemptCount, Integer.MAX_VALUE),
                passed));

        progressionService.onActivity(userId, exercise.getConceptId(), ActivityType.DEBUGGING, passed, false);
        eventPublisher.publishEvent(new ActivityEvidenceEvent(new ActivityEvidence(
                userId, exercise.getConceptId(), "debugging", accuracy, (int) Math.round(accuracy * 100.0),
                (int) Math.min(attemptCount, Integer.MAX_VALUE), time, hintsUsed,
                result.testCasesPassed(), result.testCasesTotal(), passed)));
    }

    private List<String> hintLadder(DebugExercise exercise) {
        List<String> hints = new ArrayList<>();
        String json = exercise.getHintLadderJson();
        if (json == null || json.isBlank()) {
            return hints;
        }
        try {
            JsonNode node = objectMapper.readTree(json);
            if (node.isArray()) {
                for (JsonNode item : node) {
                    String text = item.isTextual() ? item.asText() : item.path("text").asText("");
                    if (!text.isBlank()) {
                        hints.add(text);
                    }
                }
            }
        } catch (Exception e) {
            log.warn("Invalid hint ladder JSON on debug exercise {}", exercise.getId());
        }
        return hints;
    }

    private void validateTestCases(String json) {
        if (CodingTestCases.parse(json).isEmpty()) {
            throw new IllegalArgumentException("testCasesJson must contain at least one test case");
        }
    }

    private void validateHintLadder(String json) {
        if (json == null || json.isBlank()) {
            return;
        }
        try {
            if (!objectMapper.readTree(json).isArray()) {
                throw new IllegalArgumentException("hintLadderJson must be a JSON array");
            }
        } catch (IllegalArgumentException e) {
            throw e;
        } catch (Exception e) {
            throw new IllegalArgumentException("hintLadderJson is not valid JSON");
        }
    }

    private AdminExerciseResponse toAdmin(DebugExercise e) {
        return new AdminExerciseResponse(e.getId(), e.getConceptId(), e.getTitle(), e.getDescription(),
                e.getLanguage(), e.getBuggyCode(), e.getTestCasesJson(), e.getHintLadderJson(), e.getBugCategory(),
                e.getDifficulty(), e.getSolutionCode(), e.getCreatedAt());
    }
}
