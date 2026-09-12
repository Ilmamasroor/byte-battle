package com.bytebattle.battle.repository;


import com.bytebattle.battle.entity.BattleQuestion;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface BattleQuestionRepository extends JpaRepository<BattleQuestion, UUID> {

    List<BattleQuestion> findByBattleIdOrderByDisplayOrderAsc(UUID battleId);
}