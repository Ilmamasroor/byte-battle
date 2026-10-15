package com.bytebattle.coding.service;

import com.bytebattle.coding.dto.ExecutionResult;
import com.bytebattle.coding.dto.TestCaseResultResponse;
import com.bytebattle.coding.entities.CodingSubmission;
import com.bytebattle.coding.entities.CodingSubmissionTestResult;
import com.bytebattle.coding.enums.CodingSubmissionStatus;
import com.bytebattle.coding.repository.CodingSubmissionRepository;
import com.bytebattle.coding.repository.CodingSubmissionTestResultRepository;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * Short, independent transactions around coding submissions. Lives in its own bean so the calls made from
 * {@link CodingService} go through the Spring proxy, and no DB transaction is ever open while Judge0 runs.
 */
@Component
public class CodingSubmissionStore {

    private final CodingSubmissionRepository submissionRepository;
    private final CodingSubmissionTestResultRepository testResultRepository;

    public CodingSubmissionStore(
            CodingSubmissionRepository submissionRepository,
            CodingSubmissionTestResultRepository testResultRepository) {
        this.submissionRepository = submissionRepository;
        this.testResultRepository = testResultRepository;
    }

    @Transactional
    public UUID createPending(UUID challengeId, UUID userId, String sourceCode, String language) {
        return submissionRepository.save(CodingSubmission.builder()
                .codingChallengeId(challengeId)
                .userId(userId)
                .sourceCode(sourceCode)
                .language(language)
                .status(CodingSubmissionStatus.PENDING)
                .submittedAt(Instant.now())
                .build()).getId();
    }

    @Transactional
    public void complete(UUID submissionId, ExecutionResult result) {
        CodingSubmission submission = submissionRepository.findById(submissionId).orElseThrow();
        submission.setStatus(result.status());
        submission.setExecutionTimeMs(result.executionTimeMs());
        submission.setMemoryUsedBytes(result.memoryUsedBytes());
        submission.setTestCasesPassed(result.testCasesPassed());
        submission.setTestCasesTotal(result.testCasesTotal());
        submission.setErrorMessage(result.errorMessage());
        submissionRepository.save(submission);

        List<CodingSubmissionTestResult> rows = new ArrayList<>();
        for (ExecutionResult.TestCaseOutcome o : result.testCaseOutcomes()) {
            rows.add(CodingSubmissionTestResult.builder()
                    .submissionId(submissionId)
                    .caseNumber(o.testCaseNumber())
                    .hidden(o.hidden())
                    .passed(o.passed())
                    .status(o.status() == null ? "UNKNOWN" : o.status())
                    .timeMs(o.timeMs())
                    .memoryKb(o.memoryKb())
                    .stdoutSnippet(o.hidden() ? null : TestCaseResultResponse.truncate(o.actualOutput()))
                    .build());
        }
        testResultRepository.saveAll(rows);
    }

    /** Removes a PENDING submission whose execution never happened (Judge0 unavailable). */
    @Transactional
    public void discard(UUID submissionId) {
        submissionRepository.deleteById(submissionId);
    }

    @Transactional
    public void saveAiFeedback(UUID submissionId, String feedback) {
        submissionRepository.findById(submissionId).ifPresent(s -> {
            s.setAiFeedback(feedback);
            submissionRepository.save(s);
        });
    }

    @Transactional(readOnly = true)
    public List<CodingSubmissionTestResult> results(UUID submissionId) {
        return testResultRepository.findBySubmissionIdOrderByCaseNumberAsc(submissionId);
    }
}
