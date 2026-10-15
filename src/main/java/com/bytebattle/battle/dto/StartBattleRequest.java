package com.bytebattle.battle.dto;


import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.constraints.NotNull;

import java.util.UUID;

public record StartBattleRequest(
        @JsonProperty(access = JsonProperty.Access.READ_ONLY) UUID userId
) {
    /** userId is never read from the request body; controllers set it from the authenticated user. */
    public StartBattleRequest withUserId(UUID userId) {
        return new StartBattleRequest(userId);
    }
}
