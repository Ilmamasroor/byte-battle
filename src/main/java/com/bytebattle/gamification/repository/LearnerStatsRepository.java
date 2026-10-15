package com.bytebattle.gamification.repository;

import com.bytebattle.gamification.entity.LearnerStats;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface LearnerStatsRepository extends JpaRepository<LearnerStats, UUID> {
}
