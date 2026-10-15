package com.bytebattle.ai.client;

import com.bytebattle.ai.config.AiProperties;
import com.fasterxml.jackson.databind.JsonNode;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

import java.util.Map;

/** Calls the AI service's deterministic code visualizer (/visualize, /visualize/flow). */
@Component
public class AiVisualizationClient {

    private final RestClient restClient;
    private final AiProperties props;

    public AiVisualizationClient(@Qualifier("aiRestClient") RestClient restClient, AiProperties props) {
        this.restClient = restClient;
        this.props = props;
    }

    public JsonNode visualize(Map<String, Object> request) {
        return AiHttp.post(restClient, props, "/visualize", request, JsonNode.class);
    }

    public JsonNode flow(Map<String, Object> request) {
        return AiHttp.post(restClient, props, "/visualize/flow", request, JsonNode.class);
    }
}
