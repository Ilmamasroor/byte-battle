package com.bytebattle.security;

import com.bytebattle.battle.controller.AttemptController;
import com.bytebattle.battle.controller.BattleController;
import com.bytebattle.battle.dto.BattleResultResponse;
import com.bytebattle.battle.dto.StartBattleResponse;
import com.bytebattle.battle.service.BattleService;
import com.bytebattle.coding.controller.CodingController;
import com.bytebattle.coding.service.CodingService;
import com.bytebattle.exception.GlobalExceptionHandler;
import com.bytebattle.user.User;
import com.bytebattle.user.UserController;
import com.bytebattle.user.UserService;
import com.bytebattle.user.UserResponseDTO;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/** Real SecurityConfig + JwtAuthFilter + controllers; only services/DB-facing beans are mocked. */
@WebMvcTest(controllers = {BattleController.class, AttemptController.class, CodingController.class, UserController.class})
@Import({SecurityConfig.class, ApiErrorWriter.class, RestAuthenticationEntryPoint.class,
        RestAccessDeniedHandler.class, CurrentUser.class, GlobalExceptionHandler.class})
class SecurityRulesWebMvcTest {

    @Autowired MockMvc mvc;

    @MockitoBean JwtUtil jwtUtil;
    @MockitoBean CustomUserDetailsService userDetailsService;
    @MockitoBean BattleService battleService;
    @MockitoBean CodingService codingService;
    @MockitoBean UserService userService;
    @MockitoBean OnboardingStatusProvider onboardingStatusProvider;

    private User admin;
    private User learner;

    @BeforeEach
    void setUp() {
        admin = user("admin@x.io", User.Role.ADMIN);
        learner = user("learner@x.io", User.Role.USER);
        when(jwtUtil.extractEmail("admin-token")).thenReturn("admin@x.io");
        when(jwtUtil.isTokenValid("admin-token", "admin@x.io")).thenReturn(true);
        when(jwtUtil.extractEmail("user-token")).thenReturn("learner@x.io");
        when(jwtUtil.isTokenValid("user-token", "learner@x.io")).thenReturn(true);
        when(userDetailsService.loadUserByUsername("admin@x.io")).thenReturn(new CustomUserDetails(admin));
        when(userDetailsService.loadUserByUsername("learner@x.io")).thenReturn(new CustomUserDetails(learner));
        when(onboardingStatusProvider.isOnboardingCompleted(org.mockito.ArgumentMatchers.any())).thenReturn(true);
        when(jwtUtil.extractEmail("garbage")).thenThrow(new io.jsonwebtoken.MalformedJwtException("bad"));
    }

    private static User user(String email, User.Role role) {
        User u = new User();
        u.setId(UUID.randomUUID());
        u.setEmail(email);
        u.setName("n");
        u.setPasswordHash("h");
        u.setRole(role);
        u.setActive(true);
        return u;
    }

    @Test
    void learnerWhoHasNotOnboardedIsBlockedFromLearningEndpointsButNotFromOnboarding() throws Exception {
        when(onboardingStatusProvider.isOnboardingCompleted(learner.getId())).thenReturn(false);
        UUID battle = UUID.randomUUID();

        mvc.perform(post("/api/battles/" + battle + "/start").header("Authorization", "Bearer user-token"))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.message").value(org.hamcrest.Matchers.startsWith("ONBOARDING_REQUIRED")));
        mvc.perform(post("/api/coding/challenges/" + battle + "/submissions").header("Authorization", "Bearer user-token")
                        .contentType(MediaType.APPLICATION_JSON).content("{}"))
                .andExpect(status().isForbidden());
        // reading the catalogue and the user's own account stay open so the app can show the onboarding flow
        mvc.perform(get("/api/users/me").header("Authorization", "Bearer user-token"))
                .andExpect(status().is(org.hamcrest.Matchers.not(403))); // not gated
        org.mockito.Mockito.verifyNoInteractions(battleService);
    }

    @Test
    void adminsAreNeverBlockedByTheOnboardingGuard() throws Exception {
        when(onboardingStatusProvider.isOnboardingCompleted(admin.getId())).thenReturn(false);
        when(battleService.startBattle(any(), any())).thenReturn(null);

        mvc.perform(post("/api/battles/" + UUID.randomUUID() + "/start").header("Authorization", "Bearer admin-token"))
                .andExpect(status().is(org.hamcrest.Matchers.not(403)));
    }

    @Test
    void missingTokenIs401WithApiResponseBody() throws Exception {
        mvc.perform(get("/api/battles"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.message").exists());
    }

    @Test
    void garbageTokenIs401() throws Exception {
        mvc.perform(get("/api/battles").header("Authorization", "Bearer garbage"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.success").value(false));
    }

    @Test
    void userCannotCreateBattleButAdminCan() throws Exception {
        String body = "{}";
        mvc.perform(post("/api/battles").header("Authorization", "Bearer user-token")
                        .contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.success").value(false));
        // admin passes the role rule (body validation then rejects the empty payload with 400, not 403)
        mvc.perform(post("/api/battles").header("Authorization", "Bearer admin-token")
                        .contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isBadRequest());
    }

    @Test
    void userCannotPutOrDeleteBattlesOrAddQuestions() throws Exception {
        UUID id = UUID.randomUUID();
        mvc.perform(put("/api/battles/" + id).header("Authorization", "Bearer user-token")
                        .contentType(MediaType.APPLICATION_JSON).content("{}"))
                .andExpect(status().isForbidden());
        mvc.perform(delete("/api/battles/" + id).header("Authorization", "Bearer user-token"))
                .andExpect(status().isForbidden());
        mvc.perform(post("/api/battles/" + id + "/questions").header("Authorization", "Bearer user-token")
                        .contentType(MediaType.APPLICATION_JSON).content("{}"))
                .andExpect(status().isForbidden());
        mvc.perform(delete("/api/battles/" + id).header("Authorization", "Bearer admin-token"))
                .andExpect(status().isNoContent());
    }

    @Test
    void userCannotManageCodingChallenges() throws Exception {
        UUID id = UUID.randomUUID();
        mvc.perform(post("/api/coding/challenges").header("Authorization", "Bearer user-token")
                        .contentType(MediaType.APPLICATION_JSON).content("{}"))
                .andExpect(status().isForbidden());
        mvc.perform(put("/api/coding/challenges/" + id).header("Authorization", "Bearer user-token")
                        .contentType(MediaType.APPLICATION_JSON).content("{}"))
                .andExpect(status().isForbidden());
        mvc.perform(delete("/api/coding/challenges/" + id).header("Authorization", "Bearer user-token"))
                .andExpect(status().isForbidden());
    }

    @Test
    void adminOnlyAdminPrefix() throws Exception {
        // no controller mapped under /api/admin yet: user gets 403 (rule), admin gets past the rule (404)
        mvc.perform(get("/api/admin/anything").header("Authorization", "Bearer user-token"))
                .andExpect(status().isForbidden());
        mvc.perform(get("/api/admin/anything").header("Authorization", "Bearer admin-token"))
                .andExpect(status().isNotFound());
    }

    @Test
    void learnerCanStillStartBattleAndSubmitCode() throws Exception {
        UUID id = UUID.randomUUID();
        when(battleService.startBattle(any(), any())).thenReturn(StartBattleResponse.builder().build());
        // userId in the body is ignored; the session is created for the authenticated caller
        mvc.perform(post("/api/battles/" + id + "/start").header("Authorization", "Bearer user-token")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"userId\":\"" + UUID.randomUUID() + "\"}"))
                .andExpect(status().isCreated());
        org.mockito.ArgumentCaptor<com.bytebattle.battle.dto.StartBattleRequest> cap =
                org.mockito.ArgumentCaptor.forClass(com.bytebattle.battle.dto.StartBattleRequest.class);
        org.mockito.Mockito.verify(battleService).startBattle(org.mockito.ArgumentMatchers.eq(id), cap.capture());
        org.junit.jupiter.api.Assertions.assertEquals(learner.getId(), cap.getValue().userId());

        // coding submission is a POST under /challenges/** but must stay open to learners (validation -> 400, not 403)
        mvc.perform(post("/api/coding/challenges/" + id + "/submissions").header("Authorization", "Bearer user-token")
                        .contentType(MediaType.APPLICATION_JSON).content("{}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void battleAttemptUsesAuthenticatedUserUuidNotEmail() throws Exception {
        UUID session = UUID.randomUUID();
        when(battleService.completeSession(any(), any())).thenReturn(BattleResultResponse.builder().build());

        mvc.perform(post("/api/battle-sessions/" + session + "/complete").header("Authorization", "Bearer user-token"))
                .andExpect(status().isOk());
        org.mockito.Mockito.verify(battleService).completeSession(session, learner.getId());
    }

    @Test
    void getUserByIdIsAdminOrSelfOnly() throws Exception {
        UUID other = UUID.randomUUID();
        when(userService.getUserById(any())).thenReturn(new UserResponseDTO());

        mvc.perform(get("/api/users/" + other).header("Authorization", "Bearer user-token"))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.success").value(false));
        mvc.perform(get("/api/users/" + learner.getId()).header("Authorization", "Bearer user-token"))
                .andExpect(status().isOk());
        mvc.perform(get("/api/users/" + other).header("Authorization", "Bearer admin-token"))
                .andExpect(status().isOk());
    }

    @Test
    void corsPreflightAllowsConfiguredOriginOnly() throws Exception {
        mvc.perform(options("/api/battles")
                        .header("Origin", "http://localhost:3000")
                        .header("Access-Control-Request-Method", "GET"))
                .andExpect(status().isOk())
                .andExpect(header().string("Access-Control-Allow-Origin", "http://localhost:3000"));
        mvc.perform(options("/api/battles")
                        .header("Origin", "http://evil.example")
                        .header("Access-Control-Request-Method", "GET"))
                .andExpect(status().isForbidden());
    }
}
