package com.bytebattle.coding.judge0;

import com.bytebattle.coding.dto.ExecutionRequest;
import com.bytebattle.coding.dto.ExecutionResult;
import com.bytebattle.coding.enums.CodingSubmissionStatus;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;
import com.fasterxml.jackson.core.JsonProcessingException;

import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Map;

@Component
public class Judge0Client {

    private final RestClient restClient;
    private final Judge0Properties properties;
    private final ObjectMapper objectMapper;

    public Judge0Client(
            RestClient judge0RestClient,
            Judge0Properties properties,
            ObjectMapper objectMapper) {
        this.restClient = judge0RestClient;
        this.properties = properties;
        this.objectMapper = objectMapper;
    }

    public ExecutionResult execute(ExecutionRequest request) {

        if (!properties.isEnabled()) {
            throw new IllegalStateException("Judge0 execution is disabled");
        }

        List<TestCase> testCases = parseTestCases(request.testCasesJson());

        if (testCases.isEmpty()) {
            throw new IllegalArgumentException("Coding challenge has no test cases");
        }

        if (testCases.size() > properties.getMaxTestCases()) {
            throw new IllegalArgumentException(
                    "Coding challenge exceeds the maximum number of test cases");
        }

        int languageId = resolveLanguageId(request.language());
        int cpuTimeLimitMs = boundedTimeLimit(request.timeLimitMs());
        int memoryLimitKb = boundedMemoryLimit(request.memoryLimitMb());

        List<Judge0Submission> results = new ArrayList<>();

        for (TestCase testCase : testCases) {

            Judge0Submission result = executeSingle(
                    request,
                    testCase,
                    languageId,
                    cpuTimeLimitMs,
                    memoryLimitKb
            );

            results.add(result);
        }

        return toExecutionResult(results, testCases);
    }

    private Judge0Submission executeSingle(
            ExecutionRequest request,
            TestCase testCase,
            int languageId,
            int cpuTimeLimitMs,
            int memoryLimitKb) {

        Map<String, Object> submission = Map.of(
                "source_code", request.sourceCode(),
                "language_id", languageId,
                "stdin", nullToEmpty(testCase.input()),
                "expected_output", nullToEmpty(testCase.expectedOutput()),
                "cpu_time_limit", cpuTimeLimitMs / 1000.0,
                "wall_time_limit", Math.max(
                        1.0,
                        cpuTimeLimitMs / 1000.0 + 1.0
                ),
                "memory_limit", memoryLimitKb,
                "enable_network", false,
                "max_file_size", 1024
        );

        try {
            String requestJson = objectMapper.writeValueAsString(submission);

            System.out.println("===== JUDGE0 JSON BODY =====");
            System.out.println(requestJson);
            System.out.println("============================");

            JsonNode response = restClient.post()
                    .uri("/submissions?base64_encoded=false&wait=true")
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(requestJson)
                    .retrieve()
                    .body(JsonNode.class);

            if (response == null || !response.isObject()) {
                throw new IllegalStateException(
                        "Judge0 returned an invalid submission response");
            }

            JsonNode statusNode = response.path("status");

            return new Judge0Submission(
                    response.path("token").asText(null),
                    statusNode.path("id").asInt(13),
                    statusNode.path("description").asText("Unknown"),
                    nullableText(response, "stdout"),
                    nullableText(response, "stderr"),
                    nullableText(response, "compile_output"),
                    nullableText(response, "message"),
                    response.path("time").asText(null),
                    response.path("memory").isNumber()
                            ? response.path("memory").asLong()
                            : null
            );

        } catch (JsonProcessingException ex) {
            throw new IllegalStateException(
                    "Failed to serialize Judge0 submission",
                    ex
            );
        } catch (RestClientException ex) {
            throw new IllegalStateException(
                    "Judge0 submission failed: " + ex.getMessage(),
                    ex
            );
        }
    }

    private ExecutionResult toExecutionResult(
            List<Judge0Submission> results,
            List<TestCase> testCases) {

        if (results.size() != testCases.size()) {
            throw new IllegalStateException(
                    "Judge0 returned an unexpected number of results");
        }

        int passed = 0;
        int totalExecutionMs = 0;
        long maxMemoryBytes = 0;

        String errorMessage = null;

        CodingSubmissionStatus overallStatus =
                CodingSubmissionStatus.PASSED;

        List<ExecutionResult.TestCaseOutcome> outcomes =
                new ArrayList<>();

        for (int i = 0; i < results.size(); i++) {

            Judge0Submission result = results.get(i);

            boolean accepted = result.statusId() == 3;

            if (accepted) {
                passed++;
            }

            if (result.time() != null) {
                try {
                    totalExecutionMs +=
                            (int) Math.round(
                                    Double.parseDouble(result.time()) * 1000
                            );
                } catch (NumberFormatException ignored) {
                }
            }

            if (result.memoryBytes() != null) {
                maxMemoryBytes = Math.max(
                        maxMemoryBytes,
                        result.memoryBytes() * 1024
                );
            }

            if (!accepted && errorMessage == null) {
                errorMessage = firstNonBlank(
                        result.compileOutput(),
                        result.stderr(),
                        result.message(),
                        result.statusDescription()
                );
            }

            overallStatus = mergeStatus(
                    overallStatus,
                    result.statusId()
            );

            outcomes.add(
                    new ExecutionResult.TestCaseOutcome(
                            i + 1,
                            accepted,
                            result.stdout(),
                            testCases.get(i).expectedOutput()
                    )
            );
        }

        return new ExecutionResult(
                passed == results.size(),
                passed,
                results.size(),
                totalExecutionMs,
                maxMemoryBytes == 0 ? null : maxMemoryBytes,
                errorMessage,
                outcomes,
                overallStatus
        );
    }

    private CodingSubmissionStatus mergeStatus(
            CodingSubmissionStatus current,
            int judge0StatusId) {

        CodingSubmissionStatus candidate;

        if (judge0StatusId == 6) {
            candidate = CodingSubmissionStatus.COMPILATION_ERROR;

        } else if (judge0StatusId == 5) {
            candidate = CodingSubmissionStatus.TIMEOUT;

        } else if (
                judge0StatusId == 7
                        || judge0StatusId == 8
                        || judge0StatusId == 9
                        || judge0StatusId == 10
                        || judge0StatusId >= 11
        ) {
            candidate = CodingSubmissionStatus.RUNTIME_ERROR;

        } else if (judge0StatusId == 4) {
            candidate = CodingSubmissionStatus.FAILED;

        } else {
            candidate = current;
        }

        return statusPriority(candidate) > statusPriority(current)
                ? candidate
                : current;
    }

    private int statusPriority(CodingSubmissionStatus status) {

        return switch (status) {
            case COMPILATION_ERROR -> 5;
            case TIMEOUT -> 4;
            case RUNTIME_ERROR -> 3;
            case FAILED -> 2;
            case PASSED -> 1;
            default -> 0;
        };
    }

    private int resolveLanguageId(String language) {

        if (language == null || language.isBlank()) {
            throw new IllegalArgumentException("Language is required");
        }

        Integer id = properties
                .getLanguageIds()
                .get(language.trim().toUpperCase(Locale.ROOT));

        if (id == null) {
            throw new IllegalArgumentException(
                    "Unsupported coding language: " + language);
        }

        return id;
    }

    private int boundedTimeLimit(Integer requestedMs) {

        int value = requestedMs == null
                ? properties.getDefaultTimeLimitMs()
                : requestedMs;

        int max = properties.getMaxTimeLimitMs();

        if (value < 100 || value > max) {
            throw new IllegalArgumentException(
                    "Time limit must be between 100ms and " + max + "ms");
        }

        return value;
    }

    private int boundedMemoryLimit(Integer requestedMb) {

        int value = requestedMb == null
                ? properties.getDefaultMemoryLimitMb()
                : requestedMb;

        int max = properties.getMaxMemoryLimitMb();

        if (value < 16 || value > max) {
            throw new IllegalArgumentException(
                    "Memory limit must be between 16MB and " + max + "MB");
        }

        return value * 1024;
    }

    private List<TestCase> parseTestCases(String json) {

        try {

            JsonNode node = objectMapper.readTree(json);

            if (!node.isArray()) {
                throw new IllegalArgumentException(
                        "testCases must be a JSON array");
            }

            List<TestCase> cases = new ArrayList<>();

            for (JsonNode item : node) {

                if (!item.has("input")
                        || !item.has("expectedOutput")) {

                    throw new IllegalArgumentException(
                            "Each test case requires input and expectedOutput");
                }

                cases.add(
                        new TestCase(
                                item.get("input").asText(),
                                item.get("expectedOutput").asText()
                        )
                );
            }

            return cases;

        } catch (Exception ex) {

            if (ex instanceof IllegalArgumentException iae) {
                throw iae;
            }

            throw new IllegalArgumentException(
                    "Invalid coding challenge testCases JSON",
                    ex
            );
        }
    }

    private static String nullableText(
            JsonNode node,
            String field) {

        JsonNode value = node.get(field);

        return value == null || value.isNull()
                ? null
                : value.asText();
    }

    private static String firstNonBlank(String... values) {

        for (String value : values) {

            if (value != null && !value.isBlank()) {
                return value;
            }
        }

        return "Execution failed";
    }

    private static String nullToEmpty(String value) {
        return value == null ? "" : value;
    }

    private record TestCase(
            String input,
            String expectedOutput) {
    }

    private record Judge0Submission(
            String token,
            int statusId,
            String statusDescription,
            String stdout,
            String stderr,
            String compileOutput,
            String message,
            String time,
            Long memoryBytes) {
    }
}
