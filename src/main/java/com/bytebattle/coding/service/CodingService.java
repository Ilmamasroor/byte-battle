package com.bytebattle.coding.service;

import com.bytebattle.coding.dto.*;
import com.bytebattle.coding.entities.CodingChallenge;
import com.bytebattle.coding.entities.CodingSubmission;
import com.bytebattle.coding.entities.CodingSubmissionTestResult;
import com.bytebattle.coding.testcase.CodingTestCase;
import com.bytebattle.coding.testcase.CodingTestCases;
import com.bytebattle.coding.enums.CodingSubmissionStatus;
import com.bytebattle.coding.execution.CodeExecutor;
import com.bytebattle.coding.repository.CodingChallengeRepository;
import com.bytebattle.coding.repository.CodingSubmissionRepository;
import com.bytebattle.performance.dto.CreatePerformanceRecordRequest;
import com.bytebattle.performance.enums.ActivityType;
import com.bytebattle.learning.service.ProgressionService;
import com.bytebattle.performance.service.PerformanceService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
public class CodingService {

    private static final Logger log = LoggerFactory.getLogger(CodingService.class);

    private final CodingChallengeRepository codingChallengeRepository;
    private final CodingSubmissionRepository codingSubmissionRepository;
    private final CodeExecutor codeExecutor;
    private final PerformanceService performanceService;
    private final CodingSubmissionStore submissionStore;
    private final ApplicationEventPublisher eventPublisher;
    private final ProgressionService progressionService;

    public CodingService(
            CodingChallengeRepository codingChallengeRepository,
            CodingSubmissionRepository codingSubmissionRepository,
            CodeExecutor codeExecutor,
            PerformanceService performanceService,
            CodingSubmissionStore submissionStore,
            ApplicationEventPublisher eventPublisher,
            ProgressionService progressionService) {
        this.codingChallengeRepository = codingChallengeRepository;
        this.codingSubmissionRepository = codingSubmissionRepository;
        this.codeExecutor = codeExecutor;
        this.performanceService = performanceService;
        this.submissionStore = submissionStore;
        this.eventPublisher = eventPublisher;
        this.progressionService = progressionService;
    }

    public CodingChallengeResponse getChallenge(UUID challengeId) {
        return codingChallengeRepository.findById(challengeId)
                .map(this::toChallengeResponse)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Coding challenge not found"));
    }

    public CodingChallengeResponse createChallenge(CreateCodingChallengeRequest request) {
        CodingTestCases.parse(request.testCases());
        CodingChallenge challenge = codingChallengeRepository.save(CodingChallenge.builder()
                .conceptId(request.conceptId())
                .title(request.title())
                .description(request.description())
                .difficulty(request.difficulty())
                .language(request.language())
                .inputDescription(request.inputDescription())
                .outputDescription(request.outputDescription())
                .constraints(request.constraints())
                .starterCode(request.starterCode())
                .solutionCode(request.solutionCode())
                .testCases(request.testCases())
                .timeLimitMs(request.timeLimitMs())
                .memoryLimitMb(request.memoryLimitMb())
                .createdAt(Instant.now())
                .updatedAt(Instant.now())
                .build());

        return toChallengeResponse(challenge);
    }

    public CodingChallengeResponse updateChallenge(
            UUID challengeId,
            UpdateCodingChallengeRequest request) {

        CodingChallenge challenge = codingChallengeRepository.findById(challengeId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Challenge not found"));

        Optional.ofNullable(request.title()).ifPresent(challenge::setTitle);
        Optional.ofNullable(request.description()).ifPresent(challenge::setDescription);
        Optional.ofNullable(request.difficulty()).ifPresent(challenge::setDifficulty);
        Optional.ofNullable(request.starterCode()).ifPresent(challenge::setStarterCode);
        Optional.ofNullable(request.solutionCode()).ifPresent(challenge::setSolutionCode);
        Optional.ofNullable(request.testCases()).ifPresent(tc -> {
            CodingTestCases.parse(tc);
            challenge.setTestCases(tc);
        });

        challenge.setUpdatedAt(Instant.now());

        return toChallengeResponse(codingChallengeRepository.save(challenge));
    }

    public void deleteChallenge(UUID challengeId) {
        codingChallengeRepository.findById(challengeId)
                .ifPresentOrElse(
                        codingChallengeRepository::delete,
                        () -> {
                            throw new ResponseStatusException(
                                    HttpStatus.NOT_FOUND,
                                    "Challenge not found");
                        });
    }

    public List<CodingChallengeResponse> listChallenges() {
        return codingChallengeRepository.findAll().stream()
                .map(this::toChallengeResponse)
                .toList();
    }

    public List<CodingChallengeResponse> listChallengesByConcept(UUID conceptId) {
        return codingChallengeRepository.findByConceptId(conceptId).stream()
                .map(this::toChallengeResponse)
                .toList();
    }

    /**
     * Not transactional on purpose: the PENDING row and the result are saved in separate short
     * transactions (CodingSubmissionStore) so no DB transaction is held open while Judge0 runs.
     */
    public CodeSubmissionResponse submitCode(
            UUID challengeId,
            UUID userId,
            CodeSubmissionRequest request) {

        CodingChallenge challenge = codingChallengeRepository.findById(challengeId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Coding challenge not found"));

        if (request.sourceCode().length() > 100_000) {
            throw new ResponseStatusException(
                    HttpStatus.PAYLOAD_TOO_LARGE,
                    "Source code exceeds the 100 KB limit");
        }

        if (challenge.getLanguage() == null
                || !challenge.getLanguage().equalsIgnoreCase(request.language())) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Unsupported language for this challenge");
        }

        UUID submissionId = submissionStore.createPending(
                challengeId, userId, request.sourceCode(), request.language());

        /*
         * Judge0 remains the source of truth for execution and correctness.
         */
        ExecutionResult result;
        try {
            result = codeExecutor.execute(new ExecutionRequest(
                    request.sourceCode(),
                    request.language(),
                    challenge.getTestCases(),
                    challenge.getTimeLimitMs(),
                    challenge.getMemoryLimitMb()));
        } catch (IllegalArgumentException e) {
            submissionStore.discard(submissionId);
            throw e;
        } catch (RuntimeException e) {
            log.error("Unexpected code execution failure for challenge {}", challengeId, e);
            result = ExecutionResult.unavailable("Code execution failed unexpectedly");
        }

        if (result.unavailable()) {
            // Nothing was judged: do not keep a bogus submission, and never count it as learner evidence.
            submissionStore.discard(submissionId);
            throw new ResponseStatusException(
                    HttpStatus.SERVICE_UNAVAILABLE,
                    "Code execution is temporarily unavailable. Your submission was not judged; please try again shortly.");
        }

        submissionStore.complete(submissionId, result);

        /*
         * Judge0 is the source of truth for correctness; the performance record is cheap and written
         * synchronously. Personalization and AI feedback run asynchronously after this method returns.
         */
        saveCodingPerformance(userId, challenge, result);

        eventPublisher.publishEvent(new CodingSubmissionCompletedEvent(
                submissionId,
                userId,
                challengeId,
                challenge.getConceptId(),
                challenge.getTitle(),
                challenge.getDifficulty(),
                request.language(),
                request.sourceCode(),
                result));

        return CodeSubmissionResponse.builder()
                .submissionId(submissionId)
                .status(result.status())
                .executionTimeMs(result.executionTimeMs())
                .memoryUsedBytes(result.memoryUsedBytes())
                .testCasesPassed(result.testCasesPassed())
                .testCasesTotal(result.testCasesTotal())
                .errorMessage(result.errorMessage())
                .aiFeedback(null)
                .testCaseResults(result.testCaseOutcomes().stream()
                        .map(TestCaseResultResponse::from)
                        .toList())
                .build();
    }

    private void saveCodingPerformance(
            UUID userId,
            CodingChallenge challenge,
            ExecutionResult result) {

        int total = result.testCasesTotal();
        int passed = result.testCasesPassed();

        double accuracy = total > 0
                ? (double) passed / total
                : 0.0;

        int score = (int) Math.round(accuracy * 100.0);

        performanceService.createRecord(
                new CreatePerformanceRecordRequest(
                        userId,
                        challenge.getConceptId(),
                        ActivityType.CODING,
                        score,
                        accuracy,
                        0,
                        1,
                        result.status() == CodingSubmissionStatus.PASSED));

        progressionService.onActivity(userId, challenge.getConceptId(), ActivityType.CODING,
                result.status() == CodingSubmissionStatus.PASSED, false);
    }

    public CodeSubmissionResponse getSubmission(
            UUID submissionId,
            UUID userId) {

        CodingSubmission submission = codingSubmissionRepository
                .findByIdAndUserId(submissionId, userId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Submission not found"));

        List<CodingTestCase> currentCases = codingChallengeRepository
                .findById(submission.getCodingChallengeId())
                .map(c -> CodingTestCases.parseLenient(c.getTestCases()))
                .orElse(List.of());

        List<TestCaseResultResponse> caseResults = submissionStore.results(submissionId).stream()
                .map(row -> toLearnerView(row, currentCases))
                .toList();

        return CodeSubmissionResponse.builder()
                .submissionId(submission.getId())
                .status(submission.getStatus())
                .executionTimeMs(submission.getExecutionTimeMs())
                .memoryUsedBytes(submission.getMemoryUsedBytes())
                .testCasesPassed(submission.getTestCasesPassed())
                .testCasesTotal(submission.getTestCasesTotal())
                .errorMessage(submission.getErrorMessage())
                .aiFeedback(submission.getAiFeedback())
                .testCaseResults(caseResults)
                .build();
    }

    private TestCaseResultResponse toLearnerView(CodingSubmissionTestResult row, List<CodingTestCase> currentCases) {
        int index = row.getCaseNumber() - 1;
        boolean stillVisible = index >= 0 && index < currentCases.size() && !currentCases.get(index).hidden();
        if (Boolean.TRUE.equals(row.getHidden()) || !stillVisible) {
            return TestCaseResultResponse.hiddenCase(
                    row.getCaseNumber(), Boolean.TRUE.equals(row.getPassed()), row.getStatus(), row.getTimeMs());
        }
        CodingTestCase testCase = currentCases.get(index);
        return new TestCaseResultResponse(
                row.getCaseNumber(), row.getPassed(), row.getStatus(), false, row.getTimeMs(),
                testCase.input(), testCase.expectedOutput(), row.getStdoutSnippet());
    }

    private CodingChallengeResponse toChallengeResponse(
            CodingChallenge challenge) {

        List<CodingTestCase> cases = CodingTestCases.parseLenient(challenge.getTestCases());
        List<CodingChallengeResponse.SampleTestCase> samples = new java.util.ArrayList<>();
        for (int i = 0; i < cases.size(); i++) {
            if (!cases.get(i).hidden()) {
                samples.add(new CodingChallengeResponse.SampleTestCase(
                        i + 1, cases.get(i).input(), cases.get(i).expectedOutput()));
            }
        }

        return CodingChallengeResponse.builder()
                .id(challenge.getId())
                .conceptId(challenge.getConceptId())
                .title(challenge.getTitle())
                .description(challenge.getDescription())
                .difficulty(challenge.getDifficulty())
                .language(challenge.getLanguage())
                .inputDescription(challenge.getInputDescription())
                .outputDescription(challenge.getOutputDescription())
                .constraints(challenge.getConstraints())
                .starterCode(challenge.getStarterCode())
                .timeLimitMs(challenge.getTimeLimitMs())
                .memoryLimitMb(challenge.getMemoryLimitMb())
                .sampleTestCases(samples)
                .totalTestCases(cases.size())
                .hiddenTestCases((int) cases.stream().filter(CodingTestCase::hidden).count())
                .build();
    }
}
