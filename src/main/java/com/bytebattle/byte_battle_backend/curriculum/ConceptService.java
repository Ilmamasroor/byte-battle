package com.bytebattle.byte_battle_backend.curriculum;

import com.bytebattle.byte_battle_backend.common.PageResponse;
import com.bytebattle.byte_battle_backend.exception.ResourceNotFoundException;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
public class ConceptService {

    private final ConceptRepository conceptRepository;
    private final TopicRepository topicRepository;

    public ConceptService(ConceptRepository conceptRepository, TopicRepository topicRepository) {
        this.conceptRepository = conceptRepository;
        this.topicRepository = topicRepository;
    }

    public PageResponse<ConceptResponseDTO> getConceptsByTopic(UUID topicId, Pageable pageable) {
        if (!topicRepository.existsById(topicId)) {
            throw new ResourceNotFoundException("Topic not found with id: " + topicId);
        }
        Page<ConceptResponseDTO> page = conceptRepository
                .findByTopic_IdAndActiveTrueOrderByDisplayOrderAsc(topicId, pageable)
                .map(ConceptResponseDTO::fromEntity);
        return PageResponse.fromPage(page);
    }

    public ConceptResponseDTO getConceptById(UUID conceptId) {
        Concept concept = conceptRepository.findById(conceptId)
                .orElseThrow(() -> new ResourceNotFoundException("Concept not found with id: " + conceptId));
        return ConceptResponseDTO.fromEntity(concept);
    }
}