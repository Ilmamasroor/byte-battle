package com.bytebattle.coding.judge0;

import com.bytebattle.coding.dto.ExecutionRequest;
import com.bytebattle.coding.dto.ExecutionResult;
import com.bytebattle.coding.enums.CodingSubmissionStatus;
import com.bytebattle.coding.testcase.CodingTestCase;
import com.bytebattle.coding.testcase.CodingTestCases;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Base64;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.concurrent.TimeUnit;

/**
 * Runs a source file against every test case of a challenge using Judge0's batch API:
 * one POST /submissions/batch (base64 encoded) followed by polling GET /submissions/batch.
 * Source code, stdin and request bodies are never logged.
 */
@Component
public class Judge0Client {

    private static final Logger log = LoggerFactory.getLogger(Judge0Client.class);

    static final int STATUS_IN_QUEUE = 1;
    static final int STATUS_PROCESSING = 2;
    static final int STATUS_ACCEPTED = 3;
    static final int STATUS_WRONG_ANSWER = 4;
    static final int STATUS_TIME_LIMIT = 5;
    static final int STATUS_COMPILATION_ERROR = 6;
    static final int STATUS_INTERNAL_ERROR = 13;
    static final int STATUS_EXEC_FORMAT_ERROR = 14;

    private static final String RESULT_FIELDS = "token,status,stdout,stderr,compile_output,message,time,memory";
    private static final int MAX_ERROR_CHARS = 2000;

    private final RestClient restClient;
    private final Judge0Properties properties;

    public Judge0Client(RestClient judge0RestClient, Judge0Properties properties) {
        this.restClient = judge0RestClient;
        this.properties = properties;
    }

    /**
     * @return the execution result; {@link ExecutionResult#unavailable(String)} when Judge0 is disabled,
     *         unreachable, times out or reports an internal error (never throws for infrastructure problems)
     * @throws IllegalArgumentException for a malformed challenge (bad language, no/invalid test cases)
     */
    public ExecutionResult execute(ExecutionRequest request) {

        if (!properties.isEnabled()) {
            return ExecutionResult.unavailable("Code execution is disabled");
        }

        List<CodingTestCase> testCases = CodingTestCases.parse(request.testCasesJson());
        if (testCases.isEmpty()) {
            throw new IllegalArgumentException("Coding challenge has no test cases");
        }
        if (testCases.size() > properties.getMaxTestCases()) {
            throw new IllegalArgumentException("Coding challenge exceeds the maximum number of test cases");
        }

        int languageId = resolveLanguageId(request.language());
        int cpuTimeLimitMs = clampTimeLimit(request.timeLimitMs());
        int memoryLimitKb = clampMemoryLimitMb(request.memoryLimitMb()) * 1024;

        try {
            long deadlineNanos = System.nanoTime()
                    + TimeUnit.MILLISECONDS.toNanos(properties.getOverallDeadlineMs());
            List<Judge0Result> results = new ArrayList<>();
            int batchSize = Math.max(1, properties.getBatchSize());
            for (int from = 0; from < testCases.size(); from += batchSize) {
                List<CodingTestCase> chunk = testCases.subList(from, Math.min(testCases.size(), from + batchSize));
                results.addAll(runBatch(request.sourceCode(), languageId, chunk,
                        cpuTimeLimitMs, memoryLimitKb, deadlineNanos));
            }
            return toExecutionResult(results, testCases);
        } catch (Judge0UnavailableException ex) {
            log.warn("Judge0 unavailable: {}", ex.getMessage());
            return ExecutionResult.unavailable("Code execution service is temporarily unavailable");
        }
    }

    // ------------------------------------------------------------------ submit + poll

    private List<Judge0Result> runBatch(
            String sourceCode,
            int languageId,
            List<CodingTestCase> cases,
            int cpuTimeLimitMs,
            int memoryLimitKb,
            long deadlineNanos) {

        List<Map<String, Object>> submissions = new ArrayList<>();
        for (CodingTestCase testCase : cases) {
            submissions.add(buildSubmission(sourceCode, languageId, testCase, cpuTimeLimitMs, memoryLimitKb));
        }

        List<String> tokens = submitBatch(submissions);
        if (tokens.size() != cases.size()) {
            throw new Judge0UnavailableException("Judge0 returned an unexpected number of tokens");
        }
        return pollBatch(tokens, deadlineNanos);
    }

    private Map<String, Object> buildSubmission(
            String sourceCode, int languageId, CodingTestCase testCase, int cpuTimeLimitMs, int memoryLimitKb) {

        int wallMs = Math.min(properties.getMaxWallTimeLimitMs(), cpuTimeLimitMs + properties.getWallTimeExtraMs());

        Map<String, Object> body = new LinkedHashMap<>();
        body.put("source_code", b64(sourceCode));
        body.put("language_id", languageId);
        body.put("stdin", b64(testCase.inputOrEmpty()));
        body.put("expected_output", b64(testCase.expectedOrEmpty()));
        body.put("cpu_time_limit", cpuTimeLimitMs / 1000.0);
        body.put("wall_time_limit", wallMs / 1000.0);
        body.put("memory_limit", memoryLimitKb);
        body.put("stack_limit", properties.getStackLimitKb());
        body.put("max_processes_and_or_threads", properties.getMaxProcessesAndOrThreads());
        body.put("enable_per_process_and_thread_time_limit", false);
        body.put("enable_per_process_and_thread_memory_limit", false);
        body.put("max_file_size", properties.getMaxFileSizeKb());
        body.put("number_of_runs", 1);
        body.put("enable_network", false);
        String compilerOptions = compilerOptionsFor(languageId);
        if (compilerOptions != null) {
            body.put("compiler_options", compilerOptions);
        }
        return body;
    }

    private static final ObjectMapper JSON = new ObjectMapper();

    private String compilerOptionsFor(int languageId) {
        Integer javaId = properties.getLanguageIds().get("JAVA");
        String options = properties.getJavaCompilerOptions();
        return javaId != null && javaId == languageId && options != null && !options.isBlank() ? options.trim() : null;
    }

    private List<String> submitBatch(List<Map<String, Object>> submissions) {
        // Send a fixed-length body: with a streamed (chunked) body Judge0's Puma sees an empty batch and answers
        // "there should be at least one submission in a batch".
        byte[] payload;
        try {
            payload = JSON.writeValueAsBytes(Map.of("submissions", submissions));
        } catch (JsonProcessingException ex) {
            throw new Judge0UnavailableException("Could not encode the Judge0 batch submission", ex);
        }
        try {
            JsonNode response = restClient.post()
                    .uri("/submissions/batch?base64_encoded=true")
                    .contentType(MediaType.APPLICATION_JSON)
                    .contentLength(payload.length)
                    .body(payload)
                    .retrieve()
                    .body(JsonNode.class);

            if (response == null || !response.isArray()) {
                throw new Judge0UnavailableException("Judge0 returned an invalid batch submission response");
            }
            List<String> tokens = new ArrayList<>();
            for (JsonNode item : response) {
                String token = item.path("token").asText(null);
                if (token == null || token.isBlank()) {
                    throw new Judge0UnavailableException("Judge0 rejected a submission in the batch");
                }
                tokens.add(token);
            }
            return tokens;
        } catch (RestClientException ex) {
            throw new Judge0UnavailableException("Judge0 batch submission failed: " + ex.getClass().getSimpleName()
                    + " " + safeMessage(ex), ex);
        }
    }

    private List<Judge0Result> pollBatch(List<String> tokens, long deadlineNanos) {
        String joined = String.join(",", tokens);
        int maxAttempts = Math.max(1, properties.getMaxPollAttempts());

        for (int attempt = 1; attempt <= maxAttempts; attempt++) {
            List<Judge0Result> results = fetchBatch(joined, tokens.size());
            boolean pending = results.stream().anyMatch(r -> r.statusId() == STATUS_IN_QUEUE
                    || r.statusId() == STATUS_PROCESSING);
            if (!pending) {
                return results;
            }
            if (attempt == maxAttempts || System.nanoTime() >= deadlineNanos) {
                break;
            }
            sleepQuietly(properties.getPollIntervalMs());
            if (System.nanoTime() >= deadlineNanos) {
                break;
            }
        }
        throw new Judge0UnavailableException("Timed out waiting for Judge0 results");
    }

    private List<Judge0Result> fetchBatch(String joinedTokens, int expected) {
        try {
            JsonNode response = restClient.get()
                    .uri(uriBuilder -> uriBuilder.path("/submissions/batch")
                            .queryParam("tokens", joinedTokens)
                            .queryParam("base64_encoded", "true")
                            .queryParam("fields", RESULT_FIELDS)
                            .build())
                    .retrieve()
                    .body(JsonNode.class);

            JsonNode array = response == null ? null : response.path("submissions");
            if (array == null || !array.isArray() || array.size() != expected) {
                throw new Judge0UnavailableException("Judge0 returned an invalid batch result");
            }
            List<Judge0Result> results = new ArrayList<>();
            for (JsonNode item : array) {
                JsonNode status = item.path("status");
                results.add(new Judge0Result(
                        status.path("id").asInt(STATUS_INTERNAL_ERROR),
                        status.path("description").asText("Unknown"),
                        decode(item, "stdout"),
                        decode(item, "stderr"),
                        decode(item, "compile_output"),
                        decode(item, "message"),
                        item.path("time").isNull() ? null : item.path("time").asText(null),
                        item.path("memory").isNumber() ? item.path("memory").asLong() : null));
            }
            return results;
        } catch (RestClientException ex) {
            throw new Judge0UnavailableException("Judge0 polling failed: " + ex.getClass().getSimpleName()
                    + " " + safeMessage(ex), ex);
        }
    }

    private void sleepQuietly(int millis) {
        try {
            Thread.sleep(Math.max(0, millis));
        } catch (InterruptedException ie) {
            Thread.currentThread().interrupt();
            throw new Judge0UnavailableException("Interrupted while waiting for Judge0");
        }
    }

    // ------------------------------------------------------------------ result mapping

    private ExecutionResult toExecutionResult(List<Judge0Result> results, List<CodingTestCase> testCases) {

        if (results.size() != testCases.size()) {
            throw new Judge0UnavailableException("Judge0 returned an unexpected number of results");
        }

        int passed = 0;
        int totalExecutionMs = 0;
        long maxMemoryKb = 0;
        String errorMessage = null;
        CodingSubmissionStatus overall = CodingSubmissionStatus.PASSED;
        List<ExecutionResult.TestCaseOutcome> outcomes = new ArrayList<>();

        for (int i = 0; i < results.size(); i++) {
            Judge0Result result = results.get(i);
            CodingTestCase testCase = testCases.get(i);
            boolean accepted = result.statusId() == STATUS_ACCEPTED;
            CodingSubmissionStatus mapped = mapStatus(result.statusId());

            if (mapped == CodingSubmissionStatus.EXECUTION_UNAVAILABLE) {
                throw new Judge0UnavailableException("Judge0 reported an internal error (status "
                        + result.statusId() + ")");
            }
            if (result.statusId() == STATUS_COMPILATION_ERROR && isCompilerResourceFailure(result.compileOutput())) {
                // The sandbox ran out of time compiling (e.g. a busy worker): that is not the learner's mistake
                throw new Judge0UnavailableException("Judge0 compiler hit its own time limit; submission not judged");
            }
            if (accepted) {
                passed++;
            }

            Integer timeMs = parseTimeMs(result.time());
            if (timeMs != null) {
                totalExecutionMs += timeMs;
            }
            Integer memoryKb = result.memoryKb() == null ? null : (int) Math.min(Integer.MAX_VALUE, result.memoryKb());
            if (result.memoryKb() != null) {
                maxMemoryKb = Math.max(maxMemoryKb, result.memoryKb());
            }

            if (!accepted && errorMessage == null && mapped != CodingSubmissionStatus.FAILED) {
                errorMessage = truncate(firstNonBlank(
                        result.compileOutput(), result.stderr(), result.message(), result.statusDescription()));
            }

            if (priority(mapped) > priority(overall)) {
                overall = mapped;
            }

            outcomes.add(new ExecutionResult.TestCaseOutcome(
                    i + 1,
                    accepted,
                    result.stdout(),
                    testCase.expectedOutput(),
                    testCase.input(),
                    testCase.hidden(),
                    caseStatusName(result.statusId()),
                    timeMs,
                    memoryKb));
        }

        if (overall == CodingSubmissionStatus.FAILED && errorMessage == null) {
            errorMessage = "Wrong answer on " + (results.size() - passed) + " of " + results.size() + " test cases";
        }

        return new ExecutionResult(
                passed == results.size(),
                passed,
                results.size(),
                totalExecutionMs,
                maxMemoryKb == 0 ? null : maxMemoryKb * 1024,
                errorMessage,
                outcomes,
                overall);
    }

    static boolean isCompilerResourceFailure(String compileOutput) {
        return compileOutput != null && compileOutput.toLowerCase(Locale.ROOT).contains("compilation time limit exceeded");
    }

    /** 3 accepted, 4 wrong answer, 5 TLE, 6 compile error, 7-12 runtime errors, 13 internal, 14 exec format. */
    static CodingSubmissionStatus mapStatus(int judge0StatusId) {
        return switch (judge0StatusId) {
            case STATUS_ACCEPTED -> CodingSubmissionStatus.PASSED;
            case STATUS_WRONG_ANSWER -> CodingSubmissionStatus.FAILED;
            case STATUS_TIME_LIMIT -> CodingSubmissionStatus.TIMEOUT;
            case STATUS_COMPILATION_ERROR -> CodingSubmissionStatus.COMPILATION_ERROR;
            case 7, 8, 9, 10, 11, 12, STATUS_EXEC_FORMAT_ERROR -> CodingSubmissionStatus.RUNTIME_ERROR;
            default -> CodingSubmissionStatus.EXECUTION_UNAVAILABLE; // 13 internal error, unknown ids
        };
    }

    static String caseStatusName(int judge0StatusId) {
        return switch (judge0StatusId) {
            case STATUS_ACCEPTED -> "ACCEPTED";
            case STATUS_WRONG_ANSWER -> "WRONG_ANSWER";
            case STATUS_TIME_LIMIT -> "TIME_LIMIT_EXCEEDED";
            case STATUS_COMPILATION_ERROR -> "COMPILATION_ERROR";
            case 7, 8, 9, 10, 11, 12 -> "RUNTIME_ERROR";
            case STATUS_EXEC_FORMAT_ERROR -> "EXEC_FORMAT_ERROR";
            default -> "INTERNAL_ERROR";
        };
    }

    private static int priority(CodingSubmissionStatus status) {
        return switch (status) {
            case EXECUTION_UNAVAILABLE -> 6;
            case COMPILATION_ERROR -> 5;
            case TIMEOUT -> 4;
            case RUNTIME_ERROR -> 3;
            case FAILED -> 2;
            case PASSED -> 1;
            default -> 0;
        };
    }

    // ------------------------------------------------------------------ helpers

    private int resolveLanguageId(String language) {
        if (language == null || language.isBlank()) {
            throw new IllegalArgumentException("Language is required");
        }
        Integer id = properties.getLanguageIds().get(language.trim().toUpperCase(Locale.ROOT));
        if (id == null) {
            throw new IllegalArgumentException("Unsupported coding language: " + language);
        }
        return id;
    }

    /** Per-challenge limit when given, otherwise the default; always clamped into [100, configured max]. */
    private int clampTimeLimit(Integer requestedMs) {
        int value = requestedMs == null ? properties.getDefaultTimeLimitMs() : requestedMs;
        return Math.max(100, Math.min(value, properties.getMaxTimeLimitMs()));
    }

    private int clampMemoryLimitMb(Integer requestedMb) {
        int value = requestedMb == null ? properties.getDefaultMemoryLimitMb() : requestedMb;
        return Math.max(16, Math.min(value, properties.getMaxMemoryLimitMb()));
    }

    private static Integer parseTimeMs(String seconds) {
        if (seconds == null) {
            return null;
        }
        try {
            return (int) Math.round(Double.parseDouble(seconds) * 1000);
        } catch (NumberFormatException ex) {
            return null;
        }
    }

    private static String b64(String value) {
        return Base64.getEncoder().encodeToString((value == null ? "" : value).getBytes(StandardCharsets.UTF_8));
    }

    /** Judge0 wraps base64 output at 60 chars with newlines, hence the MIME decoder. */
    private static String decode(JsonNode node, String field) {
        JsonNode value = node.get(field);
        if (value == null || value.isNull()) {
            return null;
        }
        String text = value.asText();
        try {
            return new String(Base64.getMimeDecoder().decode(text), StandardCharsets.UTF_8);
        } catch (IllegalArgumentException ex) {
            return text;
        }
    }

    private static String firstNonBlank(String... values) {
        for (String value : values) {
            if (value != null && !value.isBlank()) {
                return value;
            }
        }
        return "Execution failed";
    }

    private static String truncate(String value) {
        return value.length() <= MAX_ERROR_CHARS ? value : value.substring(0, MAX_ERROR_CHARS);
    }

    private static String safeMessage(Exception ex) {
        String message = ex.getMessage();
        if (message == null) {
            return "";
        }
        return message.length() > 200 ? message.substring(0, 200) : message;
    }

    private record Judge0Result(
            int statusId,
            String statusDescription,
            String stdout,
            String stderr,
            String compileOutput,
            String message,
            String time,
            Long memoryKb) {
    }

    /** Infrastructure problem (disabled, unreachable, timeout, internal error); mapped to EXECUTION_UNAVAILABLE. */
    static class Judge0UnavailableException extends RuntimeException {
        Judge0UnavailableException(String message) {
            super(message);
        }

        Judge0UnavailableException(String message, Throwable cause) {
            super(message, cause);
        }
    }
}
