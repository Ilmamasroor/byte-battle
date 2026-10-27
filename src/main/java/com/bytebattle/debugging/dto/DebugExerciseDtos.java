package com.bytebattle.debugging.dto;

import com.bytebattle.coding.dto.TestCaseResultResponse;
import com.bytebattle.debugging.enums.ErrorCategory;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

/** Request/response shapes of the debugging-exercise flow. Learner shapes never carry solution code or hidden tests. */
public final class DebugExerciseDtos {

    private DebugExerciseDtos() {
    }

    public record ExerciseSummary(
            UUID id, UUID conceptId, String title, String language, String bugCategory, String difficulty) {}

    public record SampleTest(int caseNumber, String input, String expectedOutput) {}

    public record ExerciseDetail(
            UUID id,
            UUID conceptId,
            String title,
            String description,
            String language,
            String buggyCode,
            String bugCategory,
            String difficulty,
            int totalTests,
            int hiddenTests,
            int hintCount,
            List<SampleTest> sampleTests) {}

    public record AttemptRequest(@NotBlank String code, Integer timeSpentSeconds) {}

    public record AttemptResponse(
            UUID attemptId,
            UUID exerciseId,
            String status,
            boolean passed,
            int testsPassed,
            int testsTotal,
            ErrorCategory errorCategory,
            String errorMessage,
            int hintsUsed,
            int consecutiveFailures,
            /** CONTINUE (passed), RETRY, or DIAGNOSE (two or more failures in a row). */
            String nextAction,
            /** True after three consecutive failures: stop looping, flag the weakness and move on. */
            boolean persistentWeakness,
            List<TestCaseResultResponse> testCaseResults) {}

    public record HintResponse(int level, int totalLevels, String hint, int hintsUsed, boolean counted) {}

    public record AdminExerciseRequest(
            @NotNull UUID conceptId,
            @NotBlank String title,
            String description,
            @NotBlank String buggyCode,
            @NotBlank String language,
            @NotBlank String testCasesJson,
            String hintLadderJson,
            String bugCategory,
            String difficulty,
            @NotBlank String solutionCode) {}

    public record AdminExerciseUpdate(
            UUID conceptId,
            String title,
            String description,
            String buggyCode,
            String language,
            String testCasesJson,
            String hintLadderJson,
            String bugCategory,
            String difficulty,
            String solutionCode) {}

    public record AdminExerciseResponse(
            UUID id,
            UUID conceptId,
            String title,
            String description,
            String language,
            String buggyCode,
            String testCasesJson,
            String hintLadderJson,
            String bugCategory,
            String difficulty,
            String solutionCode,
            Instant createdAt) {}
}
