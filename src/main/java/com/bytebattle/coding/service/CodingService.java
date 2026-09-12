package com.bytebattle.coding.service;


import com.bytebattle.coding.dto.*;
import com.bytebattle.coding.entities.CodingChallenge;
import com.bytebattle.coding.entities.CodingSubmission;
import com.bytebattle.coding.enums.CodingSubmissionStatus;
import com.bytebattle.coding.execution.CodeExecutor;

import com.bytebattle.coding.repository.CodingChallengeRepository;
import com.bytebattle.coding.repository.CodingSubmissionRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
public class CodingService {

    private final CodingChallengeRepository codingChallengeRepository;
    private final CodingSubmissionRepository codingSubmissionRepository;
    private final CodeExecutor codeExecutor;

    public CodingService(CodingChallengeRepository codingChallengeRepository,
                          CodingSubmissionRepository codingSubmissionRepository,
                          CodeExecutor codeExecutor) {
        this.codingChallengeRepository = codingChallengeRepository;
        this.codingSubmissionRepository = codingSubmissionRepository;
        this.codeExecutor = codeExecutor;
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

    public CodingChallengeResponse updateChallenge(UUID challengeId, UpdateCodingChallengeRequest request) {
        CodingChallenge challenge = codingChallengeRepository.findById(challengeId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Challenge not found"));

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
                        () -> { throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Challenge not found"); }
                );
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
    

    @Transactional
    public CodeSubmissionResponse submitCode(UUID challengeId, UUID userId, CodeSubmissionRequest request) {
        CodingChallenge challenge = codingChallengeRepository.findById(challengeId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Coding challenge not found"));

        ExecutionResult result = codeExecutor.execute(new ExecutionRequest(
                request.sourceCode(),
                request.language(),
                challenge.getTestCases(),
                challenge.getTimeLimitMs(),
                challenge.getMemoryLimitMb()));

        CodingSubmissionStatus status = result.passed()
                ? CodingSubmissionStatus.PASSED
                : CodingSubmissionStatus.FAILED;

        CodingSubmission submission = codingSubmissionRepository.save(CodingSubmission.builder()
                .codingChallengeId(challengeId)
                .userId(userId)
                .sourceCode(request.sourceCode())
                .language(request.language())
                .status(status)
                .executionTimeMs(result.executionTimeMs())
                .testCasesPassed(result.testCasesPassed())
                .testCasesTotal(result.testCasesTotal())
                .errorMessage(result.errorMessage())
                .submittedAt(Instant.now())
                .build());

        return CodeSubmissionResponse.builder()
                .submissionId(submission.getId())
                .status(status)
                .executionTimeMs(result.executionTimeMs())
                .testCasesPassed(result.testCasesPassed())
                .testCasesTotal(result.testCasesTotal())
                .errorMessage(result.errorMessage())
                .testCaseResults(result.testCaseOutcomes().stream()
                        .map(o -> new TestCaseResultResponse(o.testCaseNumber(), o.passed(), o.actualOutput(), o.expectedOutput()))
                        .toList())
                .build();
    }

    public CodeSubmissionResponse getSubmission(UUID submissionId, UUID userId) {
        CodingSubmission submission = codingSubmissionRepository.findByIdAndUserId(submissionId, userId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Submission not found"));

        return CodeSubmissionResponse.builder()
                .submissionId(submission.getId())
                .status(submission.getStatus())
                .executionTimeMs(submission.getExecutionTimeMs())
                .testCasesPassed(submission.getTestCasesPassed())
                .testCasesTotal(submission.getTestCasesTotal())
                .errorMessage(submission.getErrorMessage())
                .testCaseResults(List.of()) // per-test-case detail isn't persisted, only the summary
                .build();
    }

    private CodingChallengeResponse toChallengeResponse(CodingChallenge challenge) {
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