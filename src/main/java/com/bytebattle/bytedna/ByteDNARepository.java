package com.bytebattle.bytedna;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface ByteDNARepository extends JpaRepository<ByteDNA, UUID> {
    Optional<ByteDNA> findByUser_Id(String userId);
    boolean existsByUser_Id(String userId);
}
