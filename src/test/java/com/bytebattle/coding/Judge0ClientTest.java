package com.bytebattle.coding;

import com.bytebattle.coding.dto.ExecutionRequest;
import com.bytebattle.coding.dto.ExecutionResult;
import com.bytebattle.coding.enums.CodingSubmissionStatus;
import com.bytebattle.coding.judge0.Judge0Client;
import com.bytebattle.coding.judge0.Judge0Properties;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.client.RestClient;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.Base64;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.test.web.client.ExpectedCount.times;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.*;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withStatus;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess;

class Judge0ClientTest {

    private static final String SOURCE = "public class Main { public static void main(String[] a) { System.out.println(1); } }";
    private static final String TWO_CASES = "[{\"input\":\"1\",\"expectedOutput\":\"1\"},"
            + "{\"input\":\"2\",\"expectedOutput\":\"4\",\"hidden\":true}]";

    private MockRestServiceServer server;
    private Judge0Properties props;
    private Judge0Client client;

    @BeforeEach
    void setUp() {
        RestClient.Builder builder = RestClient.builder().baseUrl("http://judge0.test");
        server = MockRestServiceServer.bindTo(builder).build();
        props = new Judge0Properties();
        props.setPollIntervalMs(1);
        props.setMaxPollAttempts(5);
        client = new Judge0Client(builder.build(), props);
    }

    private static String b64(String s) {
        return Base64.getEncoder().encodeToString(s.getBytes(StandardCharsets.UTF_8));
    }

    /** Judge0 wraps base64 at 60 characters with newlines; reproduce that. */
    private static String b64Wrapped(String s) {
        return b64(s).replaceAll("(.{8})", "$1\\\\n");
    }

    private ExecutionRequest request(String cases) {
        return new ExecutionRequest(SOURCE, "JAVA", cases, null, null);
    }

    private void expectSubmit(String tokensJson) {
        server.expect(requestTo("http://judge0.test/submissions/batch?base64_encoded=true"))
                .andExpect(method(HttpMethod.POST))
                .andRespond(withSuccess(tokensJson, MediaType.APPLICATION_JSON));
    }

    private void expectPoll(String body) {
        server.expect(requestTo(org.hamcrest.Matchers.containsString("/submissions/batch?tokens=t1,t2")))
                .andExpect(method(HttpMethod.GET))
                .andExpect(queryParam("base64_encoded", "true"))
                .andRespond(withSuccess(body, MediaType.APPLICATION_JSON));
    }

    private static String result(int statusId, String stdout, String stderr, String compile, String time, int memory) {
        return "{\"status\":{\"id\":" + statusId + ",\"description\":\"x\"},"
                + "\"stdout\":" + (stdout == null ? "null" : "\"" + b64Wrapped(stdout) + "\"") + ","
                + "\"stderr\":" + (stderr == null ? "null" : "\"" + b64(stderr) + "\"") + ","
                + "\"compile_output\":" + (compile == null ? "null" : "\"" + b64(compile) + "\"") + ","
                + "\"message\":null,\"time\":" + (time == null ? "null" : "\"" + time + "\"") + ",\"memory\":" + memory + "}";
    }

    @Test
    void sendsOneBase64BatchWithSafeLimitsAndDecodesWrappedBase64Output() {
        server.expect(requestTo("http://judge0.test/submissions/batch?base64_encoded=true"))
                .andExpect(method(HttpMethod.POST))
                .andExpect(jsonPath("$.submissions.length()").value(2))
                .andExpect(jsonPath("$.submissions[0].source_code").value(b64(SOURCE)))
                .andExpect(jsonPath("$.submissions[0].stdin").value(b64("1")))
                .andExpect(jsonPath("$.submissions[0].expected_output").value(b64("1")))
                .andExpect(jsonPath("$.submissions[0].language_id").value(62))
                .andExpect(jsonPath("$.submissions[0].cpu_time_limit").value(5.0))
                .andExpect(jsonPath("$.submissions[0].wall_time_limit").value(10.0))
                .andExpect(jsonPath("$.submissions[0].memory_limit").value(256 * 1024))
                .andExpect(jsonPath("$.submissions[0].number_of_runs").value(1))
                .andExpect(jsonPath("$.submissions[0].max_processes_and_or_threads").value(60))
                .andExpect(jsonPath("$.submissions[0].enable_per_process_and_thread_time_limit").value(false))
                .andExpect(jsonPath("$.submissions[0].enable_network").value(false))
                .andExpect(jsonPath("$.submissions[1].stdin").value(b64("2")))
                .andRespond(withSuccess("[{\"token\":\"t1\"},{\"token\":\"t2\"}]", MediaType.APPLICATION_JSON));
        expectPoll("{\"submissions\":[" + result(3, "1\n", null, null, "0.123", 20480) + ","
                + result(3, "a-fairly-long-output-that-needs-wrapping-in-base64\n", null, null, "0.050", 30000) + "]}");

        ExecutionResult r = client.execute(request(TWO_CASES));

        assertThat(r.status()).isEqualTo(CodingSubmissionStatus.PASSED);
        assertThat(r.passed()).isTrue();
        assertThat(r.testCasesPassed()).isEqualTo(2);
        assertThat(r.executionTimeMs()).isEqualTo(173);
        assertThat(r.memoryUsedBytes()).isEqualTo(30000L * 1024);
        assertThat(r.testCaseOutcomes().get(0).actualOutput()).isEqualTo("1\n");
        assertThat(r.testCaseOutcomes().get(1).actualOutput())
                .isEqualTo("a-fairly-long-output-that-needs-wrapping-in-base64\n");
        assertThat(r.testCaseOutcomes().get(0).hidden()).isFalse();
        assertThat(r.testCaseOutcomes().get(1).hidden()).isTrue();
        assertThat(r.testCaseOutcomes().get(0).status()).isEqualTo("ACCEPTED");
        server.verify();
    }

    @Test
    void pollsUntilJudge0FinishesProcessing() {
        expectSubmit("[{\"token\":\"t1\"},{\"token\":\"t2\"}]");
        expectPoll("{\"submissions\":[" + result(1, null, null, null, null, 0) + "," + result(2, null, null, null, null, 0) + "]}");
        expectPoll("{\"submissions\":[" + result(3, "1", null, null, "0.1", 1000) + "," + result(2, null, null, null, null, 0) + "]}");
        expectPoll("{\"submissions\":[" + result(3, "1", null, null, "0.1", 1000) + "," + result(3, "4", null, null, "0.1", 1000) + "]}");

        ExecutionResult r = client.execute(request(TWO_CASES));

        assertThat(r.status()).isEqualTo(CodingSubmissionStatus.PASSED);
        server.verify();
    }

    @Test
    void mapsWrongAnswerTimeoutCompileAndRuntimeStatuses() {
        String cases = "[{\"input\":\"\",\"expectedOutput\":\"1\"},{\"input\":\"\",\"expectedOutput\":\"1\"}]";

        expectSubmit("[{\"token\":\"t1\"},{\"token\":\"t2\"}]");
        expectPoll("{\"submissions\":[" + result(3, "1", null, null, "0.1", 1) + "," + result(4, "9", null, null, "0.1", 1) + "]}");
        ExecutionResult wrong = client.execute(request(cases));
        assertThat(wrong.status()).isEqualTo(CodingSubmissionStatus.FAILED);
        assertThat(wrong.testCasesPassed()).isEqualTo(1);
        assertThat(wrong.testCaseOutcomes().get(1).status()).isEqualTo("WRONG_ANSWER");
        server.reset();

        expectSubmit("[{\"token\":\"t1\"},{\"token\":\"t2\"}]");
        expectPoll("{\"submissions\":[" + result(3, "1", null, null, "0.1", 1) + "," + result(5, null, null, null, "5.0", 1) + "]}");
        ExecutionResult tle = client.execute(request(cases));
        assertThat(tle.status()).isEqualTo(CodingSubmissionStatus.TIMEOUT);
        assertThat(tle.testCaseOutcomes().get(1).status()).isEqualTo("TIME_LIMIT_EXCEEDED");
        server.reset();

        expectSubmit("[{\"token\":\"t1\"},{\"token\":\"t2\"}]");
        expectPoll("{\"submissions\":[" + result(6, null, null, "Main.java:1: error: ';' expected", null, 0) + ","
                + result(6, null, null, "Main.java:1: error: ';' expected", null, 0) + "]}");
        ExecutionResult compile = client.execute(request(cases));
        assertThat(compile.status()).isEqualTo(CodingSubmissionStatus.COMPILATION_ERROR);
        assertThat(compile.errorMessage()).contains("';' expected");
        server.reset();

        for (int runtimeStatus : new int[]{7, 8, 9, 10, 11, 12, 14}) {
            expectSubmit("[{\"token\":\"t1\"},{\"token\":\"t2\"}]");
            expectPoll("{\"submissions\":[" + result(3, "1", null, null, "0.1", 1) + ","
                    + result(runtimeStatus, null, "Exception in thread main", null, "0.1", 1) + "]}");
            ExecutionResult runtime = client.execute(request(cases));
            assertThat(runtime.status()).as("status " + runtimeStatus).isEqualTo(CodingSubmissionStatus.RUNTIME_ERROR);
            assertThat(runtime.errorMessage()).contains("Exception in thread main");
            server.reset();
        }
    }

    @Test
    void compileErrorOutranksTimeoutAndWrongAnswer() {
        expectSubmit("[{\"token\":\"t1\"},{\"token\":\"t2\"}]");
        expectPoll("{\"submissions\":[" + result(4, "x", null, null, "0.1", 1) + "," + result(6, null, null, "boom", null, 0) + "]}");
        assertThat(client.execute(request(TWO_CASES)).status()).isEqualTo(CodingSubmissionStatus.COMPILATION_ERROR);
    }

    @Test
    void judge0CompileTimeoutIsInfrastructureNotALearnerCompilationError() {
        expectSubmit("[{\"token\":\"t1\"},{\"token\":\"t2\"}]");
        expectPoll("{\"submissions\":[" + result(3, "1", null, null, "0.1", 1) + ","
                + result(6, null, null, "Compilation time limit exceeded.", null, 0) + "]}");

        ExecutionResult r = client.execute(request(TWO_CASES));

        assertThat(r.unavailable()).isTrue(); // -> HTTP 503, nothing persisted as learner evidence
    }

    @Test
    void javaSubmissionsAskForACheapJavacButOtherSettingsAreUntouched() {
        server.expect(requestTo("http://judge0.test/submissions/batch?base64_encoded=true"))
                .andExpect(jsonPath("$.submissions[0].compiler_options").value(
                        org.hamcrest.Matchers.containsString("-J-XX:+UseSerialGC")))
                .andRespond(withSuccess("[{\"token\":\"t1\"},{\"token\":\"t2\"}]", MediaType.APPLICATION_JSON));
        expectPoll("{\"submissions\":[" + result(3, "1", null, null, "0.1", 1) + "," + result(3, "4", null, null, "0.1", 1) + "]}");

        client.execute(request(TWO_CASES));

        server.verify();
    }

    @Test
    void clampsRequestedLimitsToConfiguredMaximum() {
        server.expect(requestTo("http://judge0.test/submissions/batch?base64_encoded=true"))
                .andExpect(jsonPath("$.submissions[0].cpu_time_limit").value(15.0))
                .andExpect(jsonPath("$.submissions[0].wall_time_limit").value(20.0))
                .andExpect(jsonPath("$.submissions[0].memory_limit").value(512 * 1024))
                .andRespond(withSuccess("[{\"token\":\"t1\"},{\"token\":\"t2\"}]", MediaType.APPLICATION_JSON));
        expectPoll("{\"submissions\":[" + result(3, "1", null, null, "0.1", 1) + "," + result(3, "4", null, null, "0.1", 1) + "]}");

        client.execute(new ExecutionRequest(SOURCE, "java", TWO_CASES, 999_999, 99_999));

        server.verify();
    }

    @Test
    void honoursPerChallengeLimitsBelowTheMaximum() {
        server.expect(requestTo("http://judge0.test/submissions/batch?base64_encoded=true"))
                .andExpect(jsonPath("$.submissions[0].cpu_time_limit").value(2.0))
                .andExpect(jsonPath("$.submissions[0].memory_limit").value(64 * 1024))
                .andRespond(withSuccess("[{\"token\":\"t1\"},{\"token\":\"t2\"}]", MediaType.APPLICATION_JSON));
        expectPoll("{\"submissions\":[" + result(3, "1", null, null, "0.1", 1) + "," + result(3, "4", null, null, "0.1", 1) + "]}");

        client.execute(new ExecutionRequest(SOURCE, "JAVA", TWO_CASES, 2000, 64));

        server.verify();
    }

    @Test
    void splitsLargeChallengesIntoBatchesOfConfiguredSize() {
        props.setBatchSize(1);
        String cases = "[{\"input\":\"1\",\"expectedOutput\":\"1\"},{\"input\":\"2\",\"expectedOutput\":\"2\"}]";
        server.expect(times(2), requestTo("http://judge0.test/submissions/batch?base64_encoded=true"))
                .andExpect(jsonPath("$.submissions.length()").value(1))
                .andRespond(withSuccess("[{\"token\":\"t1\"}]", MediaType.APPLICATION_JSON));
        server.expect(times(2), requestTo(org.hamcrest.Matchers.containsString("/submissions/batch?tokens=t1")))
                .andRespond(withSuccess("{\"submissions\":[" + result(3, "1", null, null, "0.1", 1) + "]}", MediaType.APPLICATION_JSON));

        ExecutionResult r = client.execute(request(cases));

        assertThat(r.testCasesTotal()).isEqualTo(2);
        server.verify();
    }

    @Test
    void disabledJudge0IsUnavailableAndMakesNoHttpCall() {
        props.setEnabled(false);

        ExecutionResult r = client.execute(request(TWO_CASES));

        assertThat(r.unavailable()).isTrue();
        assertThat(r.status()).isEqualTo(CodingSubmissionStatus.EXECUTION_UNAVAILABLE);
        server.verify();
    }

    @Test
    void submitServerErrorIsUnavailableNotAnException() {
        server.expect(requestTo("http://judge0.test/submissions/batch?base64_encoded=true"))
                .andRespond(withStatus(HttpStatus.INTERNAL_SERVER_ERROR));

        assertThat(client.execute(request(TWO_CASES)).unavailable()).isTrue();
    }

    @Test
    void unauthorizedIsUnavailable() {
        server.expect(requestTo("http://judge0.test/submissions/batch?base64_encoded=true"))
                .andRespond(withStatus(HttpStatus.UNAUTHORIZED));

        assertThat(client.execute(request(TWO_CASES)).unavailable()).isTrue();
    }

    @Test
    void connectionFailureIsUnavailable() {
        server.expect(requestTo("http://judge0.test/submissions/batch?base64_encoded=true"))
                .andRespond(request -> {
                    throw new IOException("Connection refused");
                });

        assertThat(client.execute(request(TWO_CASES)).unavailable()).isTrue();
    }

    @Test
    void pollingGivesUpAfterMaxAttempts() {
        props.setMaxPollAttempts(3);
        expectSubmit("[{\"token\":\"t1\"},{\"token\":\"t2\"}]");
        for (int i = 0; i < 3; i++) {
            expectPoll("{\"submissions\":[" + result(2, null, null, null, null, 0) + "," + result(1, null, null, null, null, 0) + "]}");
        }

        assertThat(client.execute(request(TWO_CASES)).unavailable()).isTrue();
        server.verify();
    }

    @Test
    void overallDeadlineStopsPollingEarly() {
        props.setOverallDeadlineMs(0);
        props.setMaxPollAttempts(50);
        expectSubmit("[{\"token\":\"t1\"},{\"token\":\"t2\"}]");
        expectPoll("{\"submissions\":[" + result(2, null, null, null, null, 0) + "," + result(2, null, null, null, null, 0) + "]}");

        assertThat(client.execute(request(TWO_CASES)).unavailable()).isTrue();
        server.verify();
    }

    @Test
    void internalErrorStatusMakesTheWholeRunUnavailable() {
        expectSubmit("[{\"token\":\"t1\"},{\"token\":\"t2\"}]");
        expectPoll("{\"submissions\":[" + result(3, "1", null, null, "0.1", 1) + "," + result(13, null, null, null, null, 0) + "]}");

        assertThat(client.execute(request(TWO_CASES)).unavailable()).isTrue();
    }

    @Test
    void malformedChallengeIsAnIllegalArgument() {
        assertThatThrownBy(() -> client.execute(request("[]"))).isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> client.execute(request("not json"))).isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> client.execute(new ExecutionRequest(SOURCE, "cobol", TWO_CASES, null, null)))
                .isInstanceOf(IllegalArgumentException.class);
    }
}
