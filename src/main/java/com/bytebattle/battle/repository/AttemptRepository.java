package com.bytebattle.battle.repository;

import com.bytebattle.battle.entity.Attempt;
import com.bytebattle.battle.entity.BattleSession;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface AttemptRepository extends JpaRepository<Attempt, UUID> {

    List<Attempt> findByBattleSessionId(UUID battleSessionId);

   

	Optional<BattleSession> findByBattleSessionIdAndBattleQuestionId(UUID sessionId, UUID questionId);
}