package com.bytebattle.debugging;

import com.bytebattle.coding.controller.CodingController;
import com.bytebattle.coding.service.CodingService;
import com.bytebattle.debugging.controller.AdminDebugExerciseController;
import com.bytebattle.debugging.controller.DebuggingController;
import com.bytebattle.debugging.dto.DebugExerciseDtos.*;
import com.bytebattle.debugging.service.DebugExerciseService;
import com.bytebattle.debugging.service.DebuggingService;
import com.bytebattle.exception.GlobalExceptionHandler;
import com.bytebattle.security.*;
import com.bytebattle.user.User;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(controllers = {DebuggingController.class, AdminDebugExerciseController.class, CodingController.class})
@Import({SecurityConfig.class, ApiErrorWriter.class, RestAuthenticationEntryPoint.class,
        RestAccessDeniedHandler.class, CurrentUser.class, GlobalExceptionHandler.class})
class DebuggingEndpointsWebMvcTest {

    @Autowired MockMvc mvc;

    @MockitoBean JwtUtil jwtUtil;
    @MockitoBean CustomUserDetailsService userDetailsService;
    @MockitoBean DebuggingService debuggingService;
    @MockitoBean DebugExerciseService exerciseService;
    @MockitoBean CodingService codingService;
    @MockitoBean OnboardingStatusProvider onboardingStatusProvider;

    @BeforeEach
    void setUp() {
        org.mockito.Mockito.when(onboardingStatusProvider.isOnboardingCompleted(org.mockito.ArgumentMatchers.any())).thenReturn(true);
        for (String[] t : new String[][]{{"admin-token", "admin@x.io", "ADMIN"}, {"user-token", "learner@x.io", "USER"}}) {
            User u = new User();
            u.setId(UUID.randomUUID());
            u.setEmail(t[1]);
            u.setName("n");
            u.setPasswordHash("h");
            u.setRole(User.Role.valueOf(t[2]));
            u.setActive(true);
            when(jwtUtil.extractEmail(t[0])).thenReturn(t[1]);
            when(jwtUtil.isTokenValid(t[0], t[1])).thenReturn(true);
            when(userDetailsService.loadUserByUsername(t[1])).thenReturn(new CustomUserDetails(u));
        }
    }

    @Test
    void learnerCanListExercisesButNotUseAdminCrud() throws Exception {
        when(exerciseService.list(any())).thenReturn(List.of());
        mvc.perform(get("/api/debugging/exercises").header("Authorization", "Bearer user-token"))
                .andExpect(status().isOk());
        mvc.perform(get("/api/admin/debugging/exercises").header("Authorization", "Bearer user-token"))
                .andExpect(status().isForbidden());
        mvc.perform(post("/api/admin/debugging/exercises").header("Authorization", "Bearer user-token")
                        .contentType(MediaType.APPLICATION_JSON).content("{}"))
                .andExpect(status().isForbidden());
        mvc.perform(delete("/api/admin/debugging/exercises/" + UUID.randomUUID()).header("Authorization", "Bearer user-token"))
                .andExpect(status().isForbidden());
    }

    @Test
    void adminCanUseCrud() throws Exception {
        when(exerciseService.adminList()).thenReturn(List.of());
        mvc.perform(get("/api/admin/debugging/exercises").header("Authorization", "Bearer admin-token"))
                .andExpect(status().isOk());
    }

    @Test
    void anonymousIsRejected() throws Exception {
        mvc.perform(get("/api/debugging/exercises")).andExpect(status().isUnauthorized());
    }

    @Test
    void attemptAcceptsCodeOnlyAndRejectsBlankCode() throws Exception {
        mvc.perform(post("/api/debugging/exercises/" + UUID.randomUUID() + "/attempts")
                        .header("Authorization", "Bearer user-token")
                        .contentType(MediaType.APPLICATION_JSON).content("{\"code\":\"\"}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void codingSubmissionWhenExecutionUnavailableIs503WithApiResponseMessage() throws Exception {
        when(codingService.submitCode(any(), any(), any())).thenThrow(new ResponseStatusException(
                HttpStatus.SERVICE_UNAVAILABLE, "Code execution is temporarily unavailable."));

        mvc.perform(post("/api/coding/challenges/" + UUID.randomUUID() + "/submissions")
                        .header("Authorization", "Bearer user-token")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"sourceCode\":\"class Main {}\",\"language\":\"JAVA\"}"))
                .andExpect(status().isServiceUnavailable())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.message").value("Code execution is temporarily unavailable."));
    }
}
