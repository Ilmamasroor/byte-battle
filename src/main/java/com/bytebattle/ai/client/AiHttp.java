package com.bytebattle.ai.client;

import com.bytebattle.ai.config.AiProperties;
import com.bytebattle.ai.exception.AiServiceException;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

import java.net.SocketTimeoutException;
import java.net.http.HttpTimeoutException;

/** Shared POST helper: honours bytebattle.ai.enabled and maps transport failures to AiServiceException. */
final class AiHttp {

    private AiHttp() {
    }

    static <T> T post(RestClient client, AiProperties props, String path, Object request, Class<T> type) {
        if (!props.enabled()) {
            throw new AiServiceException("AI_DISABLED", 0, "AI service is disabled (bytebattle.ai.enabled=false)");
        }
        try {
            T body = client.post().uri(path).body(request).retrieve().body(type);
            if (body == null) {
                throw new AiServiceException("AI_EMPTY_RESPONSE", 0, "AI service returned an empty response for " + path);
            }
            return body;
        } catch (AiServiceException e) {
            throw e;
        } catch (ResourceAccessException e) {
            if (isTimeout(e)) {
                throw new AiServiceException("AI_TIMEOUT", 0, "AI service timed out for " + path, e);
            }
            throw new AiServiceException("AI_UNAVAILABLE", 0, "AI service is unreachable for " + path, e);
        } catch (RestClientException e) {
            throw new AiServiceException("AI_CLIENT_ERROR", 0, "AI call failed for " + path, e);
        }
    }

    private static boolean isTimeout(Throwable t) {
        for (Throwable c = t; c != null; c = c.getCause()) {
            if (c instanceof HttpTimeoutException || c instanceof SocketTimeoutException) {
                return true;
            }
            if (c.getCause() == c) {
                break;
            }
        }
        return false;
    }
}
