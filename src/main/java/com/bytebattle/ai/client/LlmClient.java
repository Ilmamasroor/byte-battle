package com.bytebattle.ai.client;


import com.bytebattle.ai.dto.AiRequest;
import com.bytebattle.ai.dto.AiResponse;

public interface LlmClient {
    AiResponse call(AiRequest request);
}
