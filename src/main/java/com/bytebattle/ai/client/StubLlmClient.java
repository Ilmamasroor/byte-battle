package com.bytebattle.ai.client;

import com.bytebattle.ai.dto.AiRequest;
import com.bytebattle.ai.dto.AiResponse;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

import java.util.Map;

/** Canned responses for local UI work. Only active with SPRING_PROFILES_ACTIVE=stub; never the default. */
@Component
@Profile("stub")
public class StubLlmClient implements LlmClient {

    @Override
    public AiResponse call(AiRequest request) {
        return AiResponse.builder()
                .success(true)
                .operation(request.operation())
                .content("[stub AI response for operation=" + request.operation() + "]")
                .metadata(Map.of("stub", true))
                .build();
    }
}
