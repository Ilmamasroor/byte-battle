package com.bytebattle.security.repository;


import com.bytebattle.security.entity.PasswordResetToken;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface PasswordResetTokenRepository extends JpaRepository<PasswordResetToken, UUID> {
    Optional<PasswordResetToken> findByToken(String token);

    // invalidates older unused tokens when a new one is requested
    List<PasswordResetToken> findByUser_IdAndUsedFalse(String userId);
}