package com.bytebattle.exception;

import com.bytebattle.ai.exception.AiServiceException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

class GlobalExceptionHandlerTest {

    @RestController
    static class Boom {
        @GetMapping("/ai-timeout")
        String ai() {
            throw new AiServiceException("AI_TIMEOUT", 0, "AI service timed out");
        }

        @GetMapping("/ai-bad")
        String aiBad() {
            throw new AiServiceException("BAD_INPUT", 422, "bad input");
        }

        @GetMapping("/rse")
        String rse() {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Session not found");
        }

        @GetMapping("/npe")
        String npe() {
            throw new IllegalStateException("secret internal detail jdbc:postgresql://db/password");
        }

        @GetMapping("/unauth")
        String unauth() {
            throw new UnauthorizedException("Authentication required");
        }
    }

    private MockMvc mvc;

    @BeforeEach
    void setUp() {
        mvc = MockMvcBuilders.standaloneSetup(new Boom()).setControllerAdvice(new GlobalExceptionHandler()).build();
    }

    @Test
    void aiServiceExceptionBecomes503WithFallbackBody() throws Exception {
        mvc.perform(get("/ai-timeout"))
                .andExpect(status().isServiceUnavailable())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.fallback").value(true))
                .andExpect(jsonPath("$.code").value("AI_TIMEOUT"))
                .andExpect(jsonPath("$.message").value("AI service timed out"));
    }

    @Test
    void aiClientErrorStatusIsMapped() throws Exception {
        mvc.perform(get("/ai-bad"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("BAD_INPUT"))
                .andExpect(jsonPath("$.fallback").value(true));
    }

    @Test
    void responseStatusExceptionUsesApiResponseEnvelope() throws Exception {
        mvc.perform(get("/rse"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.message").value("Session not found"));
    }

    @Test
    void catchAllDoesNotLeakInternalMessage() throws Exception {
        mvc.perform(get("/npe"))
                .andExpect(status().isInternalServerError())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.message").value(org.hamcrest.Matchers.not(org.hamcrest.Matchers.containsString("jdbc"))))
                .andExpect(jsonPath("$.message").value(org.hamcrest.Matchers.containsString("Reference:")));
    }

    @Test
    void unauthorizedExceptionIs401() throws Exception {
        mvc.perform(get("/unauth")).andExpect(status().isUnauthorized());
    }
}
