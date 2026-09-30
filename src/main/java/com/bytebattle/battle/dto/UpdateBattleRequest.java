package com.bytebattle.battle.dto;


import com.bytebattle.battle.enums.BattleStatus;

public record UpdateBattleRequest(
        String title,
        String description,
        String difficulty,
        BattleStatus status
) {}