package com.bytebattle.battle.repository;


import com.bytebattle.battle.entity.BattleSession;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface BattleSessionRepository extends JpaRepository<BattleSession, UUID> {



	Optional<BattleSession> findByIdAndUserId(UUID sessionId, UUID userId);
}
