package com.bytebattle.ai.client;

import com.bytebattle.ai.dto.AiRequest;
import com.bytebattle.ai.dto.AiResponse;
import org.springframework.context.annotation.Primary;
import org.springframework.stereotype.Component;

import java.util.Map;

/**
 * TEMPORARY STUB — for local testing only. Returns a canned response
 * without calling FastAPI. @Primary makes Spring inject this one by
 * default. Remove @Primary (and make FastApiLlmClient primary instead,
 * or delete this class) once the real FastAPI service is running.
 */
@Primary
@Component
public class StubLlmClient implements LlmClient {

    @Override
    public AiResponse call(AiRequest request) {
        return AiResponse.builder()
                .success(true)
                .operation(request.operation())
                .content("[stub AI response for operation=" + request.operation() + "]")
                .metadata(Map.of())
                .build();
    }
}