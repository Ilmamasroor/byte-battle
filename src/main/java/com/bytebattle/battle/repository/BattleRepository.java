package com.bytebattle.battle.repository;


import com.bytebattle.battle.entity.Battle;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface BattleRepository extends JpaRepository<Battle, UUID> {
}