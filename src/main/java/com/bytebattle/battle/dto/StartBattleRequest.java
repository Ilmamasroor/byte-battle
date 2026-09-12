package com.bytebattle.battle.dto;


import jakarta.validation.constraints.NotNull;

import java.util.UUID;

public record StartBattleRequest(
        @NotNull UUID userId
) {}