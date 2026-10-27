package com.bytebattle.coding.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.bytebattle.coding.entities.CodingChallenge;

import java.util.List;
import java.util.UUID;

public interface CodingChallengeRepository extends JpaRepository<CodingChallenge, UUID> {
	// CodingChallengeRepository.java
	List<CodingChallenge> findByConceptId(UUID conceptId);
}