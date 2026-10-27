package com.bytebattle.ai;

import com.bytebattle.ai.client.AiFeatureClient;
import com.bytebattle.ai.client.DisabledLlmClient;
import com.bytebattle.ai.client.FastApiLlmClient;
import com.bytebattle.ai.config.AiHttpConfig;
import com.bytebattle.ai.config.AiProperties;
import com.bytebattle.ai.dto.AiRequest;
import com.bytebattle.ai.dto.AiResponse;
import com.bytebattle.ai.dto.feature.AnalogyRequest;
import com.bytebattle.ai.exception.AiServiceException;
import com.bytebattle.ai.service.AiService;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.sun.net.httpserver.HttpServer;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.web.client.RestClient;

import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

/** Real HTTP against an in-process server: timeouts, structured errors, disabled mode. */
class AiClientsTest {

    private HttpServer server;
    private String baseUrl;
    private final ObjectMapper mapper = new ObjectMapper();
    private volatile long processDelayMs = 0;

    @BeforeEach
    void start() throws Exception {
        server = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
        server.createContext("/ai/process", ex -> {
            try {
                Thread.sleep(processDelayMs);
            } catch (InterruptedException ignored) {
                Thread.currentThread().interrupt();
            }
            byte[] body = "{\"success\":true,\"operation\":\"EXPLANATION\",\"content\":\"hi\",\"metadata\":{}}"
                    .getBytes(StandardCharsets.UTF_8);
            ex.getResponseHeaders().add("Content-Type", "application/json");
            ex.sendResponseHeaders(200, body.length);
            ex.getResponseBody().write(body);
            ex.close();
        });
        server.createContext("/ai/analogy", ex -> {
            byte[] body = "{\"code\":\"LLM_BAD_OUTPUT\",\"message\":\"model returned junk\"}".getBytes(StandardCharsets.UTF_8);
            ex.getResponseHeaders().add("Content-Type", "application/json");
            ex.sendResponseHeaders(502, body.length);
            ex.getResponseBody().write(body);
            ex.close();
        });
        server.start();
        baseUrl = "http://127.0.0.1:" + server.getAddress().getPort();
    }

    @AfterEach
    void stop() {
        server.stop(0);
    }

    private AiProperties props(String url, boolean enabled, int readMs) {
        return new AiProperties(url, url, enabled, 500, readMs);
    }

    private RestClient client(AiProperties p) {
        return AiHttpConfig.buildClient(AiHttpConfig.createRequestFactory(p), p.baseUrl(), mapper);
    }

    private AiRequest request() {
        return AiRequest.builder().operation("EXPLANATION").build();
    }

    @Test
    void fastApiClientCallsAiProcessAndParsesResponse() {
        AiProperties p = props(baseUrl, true, 2000);
        AiResponse r = new FastApiLlmClient(client(p), p).call(request());
        assertTrue(r.success());
        assertEquals("hi", r.content());
        assertFalse(r.fallback());
    }

    @Test
    void structuredErrorBodyBecomesTypedException() {
        AiProperties p = props(baseUrl, true, 2000);
        AiFeatureClient feature = new AiFeatureClient(client(p), p);

        AiServiceException e = assertThrows(AiServiceException.class,
                () -> feature.generateAnalogy(new AnalogyRequest(Map.of(), Map.of(), Map.of())));

        assertEquals("LLM_BAD_OUTPUT", e.getCode());
        assertEquals(502, e.getStatus());
        assertEquals("model returned junk", e.getMessage());
    }

    @Test
    void readTimeoutFromPropertiesIsEnforced() {
        processDelayMs = 1500;
        AiProperties p = props(baseUrl, true, 200);
        long t0 = System.nanoTime();
        AiServiceException e = assertThrows(AiServiceException.class,
                () -> new FastApiLlmClient(client(p), p).call(request()));
        long ms = (System.nanoTime() - t0) / 1_000_000;
        assertEquals("AI_TIMEOUT", e.getCode());
        assertTrue(ms < 1400, "should give up after ~200ms, took " + ms);
    }

    @Test
    void connectionRefusedIsAiUnavailable() {
        server.stop(0);
        AiProperties p = props(baseUrl, true, 500);
        AiServiceException e = assertThrows(AiServiceException.class,
                () -> new FastApiLlmClient(client(p), p).call(request()));
        assertEquals("AI_UNAVAILABLE", e.getCode());
    }

    @Test
    void disabledPropertyShortCircuitsWithoutNetwork() {
        AiProperties p = props("http://127.0.0.1:1", false, 500);
        AiServiceException e = assertThrows(AiServiceException.class,
                () -> new FastApiLlmClient(client(p), p).call(request()));
        assertEquals("AI_DISABLED", e.getCode());
    }

    @Test
    void aiServiceReturnsExplicitFallbackNeverFakeSuccess() {
        AiProperties p = props("http://127.0.0.1:1", true, 300);
        AiResponse r = new AiService(new FastApiLlmClient(client(p), p)).process(request());
        assertFalse(r.success());
        assertTrue(r.fallback());

        AiResponse disabled = new AiService(new DisabledLlmClient()).process(request());
        assertFalse(disabled.success());
        assertTrue(disabled.fallback());
        assertEquals("EXPLANATION", disabled.operation());
    }

    @Test
    void errorParserHandlesFastApiDetailWrapperAndNonJson() {
        AiServiceException nested = AiHttpConfig.toException(422,
                "{\"detail\":{\"code\":\"BAD\",\"message\":\"nope\"}}".getBytes(StandardCharsets.UTF_8), mapper);
        assertEquals("BAD", nested.getCode());
        assertEquals("nope", nested.getMessage());

        AiServiceException html = AiHttpConfig.toException(500, "<html>boom</html>".getBytes(StandardCharsets.UTF_8), mapper);
        assertEquals("AI_HTTP_500", html.getCode());
        assertEquals(500, html.getStatus());
    }

    @Test
    void propertiesCarryTimeoutsAndPersonalizationDefaultsToBaseUrl() {
        AiProperties p = new AiProperties("http://ai:9000", "http://ai:9000", true, 2000, 20000);
        assertEquals(2000, p.connectTimeoutMs());
        assertEquals(20000, p.readTimeoutMs());
        assertEquals(p.baseUrl(), p.personalizationBaseUrl());
    }
}
