  package com.bytebattle.byte_battle_backend.curriculum;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface ConceptRepository extends JpaRepository<Concept, UUID> {
    List<Concept> findByTopic_IdAndActiveTrueOrderByDisplayOrderAsc(UUID topicId);
}