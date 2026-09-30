package com.bytebattle.coding.service;

<<<<<<< HEAD
import com.bytebattle.ai.dto.feature.CodingFeedbackResponse;
import com.bytebattle.ai.service.AiFeatureService;
import com.bytebattle.ai.service.PersonalizationAiService;
=======
>>>>>>> a2ff2d8 (Update backend)
import com.bytebattle.coding.dto.*;
import com.bytebattle.coding.entities.CodingChallenge;
import com.bytebattle.coding.entities.CodingSubmission;
import com.bytebattle.coding.enums.CodingSubmissionStatus;
import com.bytebattle.coding.execution.CodeExecutor;
import com.bytebattle.coding.repository.CodingChallengeRepository;
import com.bytebattle.coding.repository.CodingSubmissionRepository;
import com.bytebattle.performance.dto.CreatePerformanceRecordRequest;
import com.bytebattle.performance.enums.ActivityType;
import com.bytebattle.performance.service.PerformanceService;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

@Service
public class CodingService {

    private final CodingChallengeRepository codingChallengeRepository;
    private final CodingSubmissionRepository codingSubmissionRepository;
    private final CodeExecutor codeExecutor;
    private final AiFeatureService aiFeatureService;
    private final PerformanceService performanceService;
    private final PersonalizationAiService personalizationAiService;

    public CodingService(
            CodingChallengeRepository codingChallengeRepository,
            CodingSubmissionRepository codingSubmissionRepository,
            CodeExecutor codeExecutor,
            AiFeatureService aiFeatureService,
            PerformanceService performanceService,
            PersonalizationAiService personalizationAiService) {
        this.codingChallengeRepository = codingChallengeRepository;
        this.codingSubmissionRepository = codingSubmissionRepository;
        this.codeExecutor = codeExecutor;
        this.aiFeatureService = aiFeatureService;
        this.performanceService = performanceService;
        this.personalizationAiService = personalizationAiService;
    }

    public CodingChallengeResponse getChallenge(UUID challengeId) {
        return codingChallengeRepository.findById(challengeId)
                .map(this::toChallengeResponse)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Coding challenge not found"));
    }

    public CodingChallengeResponse createChallenge(CreateCodingChallengeRequest request) {
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
        Optional.ofNullable(request.testCases()).ifPresent(challenge::setTestCases);

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

<<<<<<< HEAD
    public CodeSubmissionResponse submitCode(
            UUID challengeId,
            UUID userId,
            CodeSubmissionRequest request) {

=======
    @Transactional
    public CodeSubmissionResponse submitCode(UUID challengeId, String string, CodeSubmissionRequest request) {
>>>>>>> a2ff2d8 (Update backend)
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

        /*
         * Judge0 remains the source of truth for execution and correctness.
         */
        ExecutionResult result = codeExecutor.execute(new ExecutionRequest(
                request.sourceCode(),
                request.language(),
                challenge.getTestCases(),
                challenge.getTimeLimitMs(),
                challenge.getMemoryLimitMb()));

        CodingSubmissionStatus status = result.status();

<<<<<<< HEAD
        CodingSubmission submission = codingSubmissionRepository.save(
                CodingSubmission.builder()
                        .codingChallengeId(challengeId)
                        .userId(userId)
                        .sourceCode(request.sourceCode())
                        .language(request.language())
                        .status(status)
                        .executionTimeMs(result.executionTimeMs())
                        .memoryUsedBytes(result.memoryUsedBytes())
                        .testCasesPassed(result.testCasesPassed())
                        .testCasesTotal(result.testCasesTotal())
                        .errorMessage(result.errorMessage())
                        .submittedAt(Instant.now())
                        .build());

        /*
         * Persist coding performance independently of AI feedback.
         *
         * Judge0 is the source of truth for correctness. AI feedback is
         * explanatory only and must never influence this record.
         */
        saveCodingPerformance(userId, challenge, result);

        /*
         * Personalization AI consumes the completed coding event.
         *
         * This is deliberately non-blocking from the correctness perspective:
         * Judge0 and PerformanceService remain the source of truth. If the
         * personalization service is unavailable or returns invalid data,
         * the coding submission itself must still succeed.
         */
        try {
            personalizationAiService.processCodingAttempt(
                    userId,
                    challenge.getConceptId(),
                    result);
        } catch (RuntimeException e) {
            // Personalization failure must never invalidate a valid submission.
            System.err.println(
                    "Coding personalization failed for submission "
                            + submission.getId()
                            + ": "
                            + e.getMessage());
        }

        /*
         * AI feedback is explanatory only.
         *
         * If the AI service is unavailable, the coding submission must still
         * succeed because Judge0 has already determined the execution result.
         */
        String aiFeedback = generateAiFeedback(
                challenge,
                request.sourceCode(),
                request.language(),
                result);

        submission.setAiFeedback(aiFeedback);
        codingSubmissionRepository.save(submission);
=======
        CodingSubmission submission = codingSubmissionRepository.save(CodingSubmission.builder()
                .codingChallengeId(challengeId)
                .userId(string)
                .sourceCode(request.sourceCode())
                .language(request.language())
                .status(status)
                .executionTimeMs(result.executionTimeMs())
                .testCasesPassed(result.testCasesPassed())
                .testCasesTotal(result.testCasesTotal())
                .errorMessage(result.errorMessage())
                .submittedAt(Instant.now())
                .build());
>>>>>>> a2ff2d8 (Update backend)

        return CodeSubmissionResponse.builder()
                .submissionId(submission.getId())
                .status(status)
                .executionTimeMs(result.executionTimeMs())
                .memoryUsedBytes(result.memoryUsedBytes())
                .testCasesPassed(result.testCasesPassed())
                .testCasesTotal(result.testCasesTotal())
                .errorMessage(result.errorMessage())
<<<<<<< HEAD
                .aiFeedback(aiFeedback)
                .testCaseResults(result.testCaseOutcomes().stream()
                        // Never return expected outputs to the learner.
=======
                // CHANGED: expected output is only revealed for failed test cases
                .testCaseResults(result.testCaseOutcomes().stream()
>>>>>>> a2ff2d8 (Update backend)
                        .map(o -> new TestCaseResultResponse(
                                o.testCaseNumber(),
                                o.passed(),
                                o.actualOutput(),
<<<<<<< HEAD
                                null))
=======
                                o.passed() ? null : o.expectedOutput()))
>>>>>>> a2ff2d8 (Update backend)
                        .toList())
                .build();
    }

<<<<<<< HEAD
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
    }

    private String generateAiFeedback(
            CodingChallenge challenge,
            String sourceCode,
            String language,
            ExecutionResult result) {

        Map<String, Object> concept = new LinkedHashMap<>();
        concept.put("conceptId", challenge.getConceptId());
        concept.put("title", challenge.getTitle());
        concept.put("difficulty", challenge.getDifficulty());
        concept.put("language", language);

        Map<String, Object> diagnosis = new LinkedHashMap<>();
        diagnosis.put("activityType", "coding");
        diagnosis.put("executionStatus", result.status().name());
        diagnosis.put("executionTimeMs", result.executionTimeMs());
        diagnosis.put("testCasesPassed", result.testCasesPassed());
        diagnosis.put("testCasesTotal", result.testCasesTotal());
        diagnosis.put("errorMessage", result.errorMessage());
        diagnosis.put("sourceCode", sourceCode);

        try {
            CodingFeedbackResponse response =
                    aiFeatureService.generateCodingFeedback(concept, diagnosis);

            return response == null ? null : response.feedback();

        } catch (RuntimeException ex) {
            /*
             * AI failure must never turn a successfully executed submission
             * into a failed coding submission.
             */
            return null;
        }
    }

    public CodeSubmissionResponse getSubmission(
            UUID submissionId,
            UUID userId) {

        CodingSubmission submission = codingSubmissionRepository
                .findByIdAndUserId(submissionId, userId)
=======
    public CodeSubmissionResponse getSubmission(UUID submissionId, String string) {
        CodingSubmission submission = codingSubmissionRepository.findByIdAndUserId(submissionId, string)
>>>>>>> a2ff2d8 (Update backend)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Submission not found"));

        return CodeSubmissionResponse.builder()
                .submissionId(submission.getId())
                .status(submission.getStatus())
                .executionTimeMs(submission.getExecutionTimeMs())
                .memoryUsedBytes(submission.getMemoryUsedBytes())
                .testCasesPassed(submission.getTestCasesPassed())
                .testCasesTotal(submission.getTestCasesTotal())
                .errorMessage(submission.getErrorMessage())
                .aiFeedback(submission.getAiFeedback())
                .testCaseResults(List.of())
                .build();
    }

    private CodingChallengeResponse toChallengeResponse(
            CodingChallenge challenge) {

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
                .build();
    }
}
