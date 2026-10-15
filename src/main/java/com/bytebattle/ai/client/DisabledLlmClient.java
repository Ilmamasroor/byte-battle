package com.bytebattle.ai.client;

import com.bytebattle.ai.dto.AiRequest;
import com.bytebattle.ai.dto.AiResponse;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

import java.util.Map;

/** Used when bytebattle.ai.enabled=false: an explicit, honest "AI is off" fallback (never a fake success). */
@Component
@Profile("!stub")
@ConditionalOnProperty(name = "bytebattle.ai.enabled", havingValue = "false")
public class DisabledLlmClient implements LlmClient {

    @Override
    public AiResponse call(AiRequest request) {
        return AiResponse.builder()
                .success(false)
                .fallback(true)
                .operation(request.operation())
                .content("AI is disabled on this server.")
                .metadata(Map.of("fallback", true, "code", "AI_DISABLED"))
                .build();
    }
}
