package com.bytebattle.debugging.service;

import com.bytebattle.coding.entities.CodingSubmission;
import com.bytebattle.coding.enums.CodingSubmissionStatus;
import com.bytebattle.coding.repository.CodingSubmissionRepository;
import com.bytebattle.debugging.dto.DebugRequest;
import com.bytebattle.debugging.dto.DebugResponse;
import com.bytebattle.debugging.enums.ErrorCategory;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.Optional;

@Service
public class DebuggingService {

    private final CodingSubmissionRepository codingSubmissionRepository;

    public DebuggingService(CodingSubmissionRepository codingSubmissionRepository) {
        this.codingSubmissionRepository = codingSubmissionRepository;
    }

    // CHANGED: takes userId and only loads the caller's own submission
    public DebugResponse analyze(DebugRequest request, String userId) {
        CodingSubmission submission = codingSubmissionRepository
                .findByIdAndUserId(request.submissionId(), userId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Submission not found"));

        ErrorCategory category = categorize(submission);

        return DebugResponse.builder()
                .category(category)
                .diagnosis(diagnosisFor(category, submission))
                .aiExplanationAvailable(category != ErrorCategory.LOGIC_ERROR
                        || passedCount(submission) > 0)
                .build();
    }

    private ErrorCategory categorize(CodingSubmission submission) {
        // Deterministic classification — no AI involved, matching ScoringService's discipline.
        // CHANGED: a null status is treated as PENDING instead of throwing an NPE in the switch
        CodingSubmissionStatus status = Optional.ofNullable(submission.getStatus())
                .orElse(CodingSubmissionStatus.PENDING);

        return switch (status) {
            case PASSED -> null; // no error to categorize
            case COMPILATION_ERROR -> ErrorCategory.COMPILATION_ERROR;
            case RUNTIME_ERROR -> ErrorCategory.RUNTIME_ERROR;
            case TIMEOUT -> ErrorCategory.TIMEOUT;
            case FAILED -> ErrorCategory.LOGIC_ERROR; // ran fine, wrong output
            case PENDING, RUNNING -> ErrorCategory.RUNTIME_ERROR; // shouldn't reach here normally
        };
    }

    private String diagnosisFor(ErrorCategory category, CodingSubmission submission) {
        return Optional.ofNullable(category)
                .map(cat -> switch (cat) {
                    case SYNTAX_ERROR -> "Your code has a syntax error before it could even compile.";
                    case COMPILATION_ERROR -> "Compilation failed: " + submission.getErrorMessage();
                    case RUNTIME_ERROR -> "Your code crashed while running: " + submission.getErrorMessage();
                    case TIMEOUT -> "Your code took too long to run and hit the time limit.";
                    case MEMORY_ERROR -> "Your code used too much memory.";
                    // CHANGED: null-safe counts
                    case LOGIC_ERROR -> "Your code ran without crashing, but produced the wrong output on "
                            + (totalCount(submission) - passedCount(submission))
                            + " of " + totalCount(submission) + " test cases.";
                })
                .orElse("No errors detected — submission passed all test cases.");
    }

    private int passedCount(CodingSubmission s) {
        return Optional.ofNullable(s.getTestCasesPassed()).orElse(0);
    }

    private int totalCount(CodingSubmission s) {
        return Optional.ofNullable(s.getTestCasesTotal()).orElse(0);
    }
}