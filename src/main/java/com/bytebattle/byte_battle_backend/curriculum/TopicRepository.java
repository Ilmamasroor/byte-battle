package com.bytebattle.byte_battle_backend.curriculum;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface TopicRepository extends JpaRepository<Topic, UUID> {
    Page<Topic> findByDomain_IdAndActiveTrueOrderByDisplayOrderAsc(UUID domainId, Pageable pageable);
}