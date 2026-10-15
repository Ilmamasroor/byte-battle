package com.bytebattle.ai.client;

import com.bytebattle.ai.config.AiProperties;
import com.bytebattle.ai.dto.AiRequest;
import com.bytebattle.ai.dto.AiResponse;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

/**
 * The real, default LlmClient: POST /ai/process on the Python FastAPI service. Replaced only by the
 * explicit "stub" profile or by bytebattle.ai.enabled=false (see DisabledLlmClient).
 */
@Component
@Profile("!stub")
@ConditionalOnProperty(name = "bytebattle.ai.enabled", havingValue = "true", matchIfMissing = true)
public class FastApiLlmClient implements LlmClient {

    private final RestClient restClient;
    private final AiProperties props;

    public FastApiLlmClient(@Qualifier("aiRestClient") RestClient restClient, AiProperties props) {
        this.restClient = restClient;
        this.props = props;
    }

    @Override
    public AiResponse call(AiRequest request) {
        return AiHttp.post(restClient, props, "/ai/process", request, AiResponse.class);
    }
}
