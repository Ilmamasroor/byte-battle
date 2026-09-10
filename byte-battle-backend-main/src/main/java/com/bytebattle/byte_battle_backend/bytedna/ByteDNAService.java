package com.bytebattle.byte_battle_backend.bytedna;

import com.bytebattle.byte_battle_backend.exception.ResourceNotFoundException;
import com.bytebattle.byte_battle_backend.security.CustomUserDetails;
import com.bytebattle.byte_battle_backend.user.User;
import com.bytebattle.byte_battle_backend.user.UserRepository;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.UUID;

@Service
public class ByteDNAService {

    private final ByteDNARepository byteDNARepository;
    private final UserRepository userRepository;

    public ByteDNAService(ByteDNARepository byteDNARepository, UserRepository userRepository) {
        this.byteDNARepository = byteDNARepository;
        this.userRepository = userRepository;
    }

    private UUID getCurrentUserId() {
        CustomUserDetails userDetails =
                (CustomUserDetails) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        return userDetails.getUser().getId();
    }

    public ByteDNAResponseDTO getMyByteDNA() {
        UUID userId = getCurrentUserId();
        ByteDNA dna = byteDNARepository.findByUser_Id(userId)
                .orElseThrow(() -> new ResourceNotFoundException("Byte DNA profile not found for this user"));
        return ByteDNAResponseDTO.fromEntity(dna);
    }

    public ByteDNAResponseDTO createByteDNA(CreateByteDNARequestDTO request) {
        UUID userId = getCurrentUserId();

        if (byteDNARepository.existsByUser_Id(userId)) {
            throw new IllegalArgumentException("Byte DNA profile already exists for this user");
        }

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        ByteDNA dna = new ByteDNA();
        dna.setUser(user);
        dna.setLearningStyle(request.getLearningStyle());
        dna.setStrengthProfile(request.getStrengthProfile());
        dna.setWeaknessProfile(request.getWeaknessProfile());
        dna.setPreferredDifficulty(request.getPreferredDifficulty());
        dna.setConsistencyScore(BigDecimal.ZERO); // starts at 0, builds up over time

        ByteDNA saved = byteDNARepository.save(dna);
        return ByteDNAResponseDTO.fromEntity(saved);
    }

    public ByteDNAResponseDTO updateByteDNA(UpdateByteDNARequestDTO request) {
        UUID userId = getCurrentUserId();
        ByteDNA dna = byteDNARepository.findByUser_Id(userId)
                .orElseThrow(() -> new ResourceNotFoundException("Byte DNA profile not found for this user"));

        if (request.getLearningStyle() != null) {
            dna.setLearningStyle(request.getLearningStyle());
        }
        if (request.getStrengthProfile() != null) {
            dna.setStrengthProfile(request.getStrengthProfile());
        }
        if (request.getWeaknessProfile() != null) {
            dna.setWeaknessProfile(request.getWeaknessProfile());
        }
        if (request.getPreferredDifficulty() != null) {
            dna.setPreferredDifficulty(request.getPreferredDifficulty());
        }

        ByteDNA saved = byteDNARepository.save(dna);
        return ByteDNAResponseDTO.fromEntity(saved);
    }
}