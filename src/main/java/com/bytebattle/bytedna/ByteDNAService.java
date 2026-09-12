package com.bytebattle.bytedna;

import com.bytebattle.bytedna.dto.ByteDNAResponseDTO;
import com.bytebattle.bytedna.dto.CreateByteDNARequestDTO;
import com.bytebattle.bytedna.dto.UpdateByteDNARequestDTO;
import com.bytebattle.exception.ResourceNotFoundException;
import com.bytebattle.security.CustomUserDetails;
import com.bytebattle.user.User;
import com.bytebattle.user.UserRepository;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

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
        dna.setTechnicalExperience(request.getTechnicalExperience());
        dna.setCareerGoal(request.getCareerGoal());
        dna.setInterests(request.getInterests());
        dna.setPreferredLanguage(request.getPreferredLanguage());
        dna.setLearningPreferences(request.getLearningPreferences());
        dna.setConfidenceAreas(request.getConfidenceAreas());
        dna.setDifficultyAreas(request.getDifficultyAreas());
        dna.setExplanationPreferences(request.getExplanationPreferences());
        dna.setRepeatedMistakes(request.getRepeatedMistakes());
        dna.setTopicAccuracy(request.getTopicAccuracy());
        dna.setDifficultyProgression(request.getDifficultyProgression());

        ByteDNA saved = byteDNARepository.save(dna);
        return ByteDNAResponseDTO.fromEntity(saved);
    }

    public ByteDNAResponseDTO updateByteDNA(UpdateByteDNARequestDTO request) {
        UUID userId = getCurrentUserId();
        ByteDNA dna = byteDNARepository.findByUser_Id(userId)
                .orElseThrow(() -> new ResourceNotFoundException("Byte DNA profile not found for this user"));

        if (request.getTechnicalExperience() != null) dna.setTechnicalExperience(request.getTechnicalExperience());
        if (request.getCareerGoal() != null) dna.setCareerGoal(request.getCareerGoal());
        if (request.getInterests() != null) dna.setInterests(request.getInterests());
        if (request.getPreferredLanguage() != null) dna.setPreferredLanguage(request.getPreferredLanguage());
        if (request.getLearningPreferences() != null) dna.setLearningPreferences(request.getLearningPreferences());
        if (request.getConfidenceAreas() != null) dna.setConfidenceAreas(request.getConfidenceAreas());
        if (request.getDifficultyAreas() != null) dna.setDifficultyAreas(request.getDifficultyAreas());
        if (request.getExplanationPreferences() != null) dna.setExplanationPreferences(request.getExplanationPreferences());
        if (request.getRepeatedMistakes() != null) dna.setRepeatedMistakes(request.getRepeatedMistakes());
        if (request.getTopicAccuracy() != null) dna.setTopicAccuracy(request.getTopicAccuracy());
        if (request.getDifficultyProgression() != null) dna.setDifficultyProgression(request.getDifficultyProgression());

        ByteDNA saved = byteDNARepository.save(dna);
        return ByteDNAResponseDTO.fromEntity(saved);
    }
}