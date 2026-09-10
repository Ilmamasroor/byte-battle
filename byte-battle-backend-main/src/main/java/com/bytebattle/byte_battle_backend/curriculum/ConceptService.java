package com.bytebattle.byte_battle_backend.curriculum;

import com.bytebattle.byte_battle_backend.exception.ResourceNotFoundException;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class ConceptService {

    private final ConceptRepository conceptRepository;
    private final TopicRepository topicRepository;

    public ConceptService(ConceptRepository conceptRepository, TopicRepository topicRepository) {
        this.conceptRepository = conceptRepository;
        this.topicRepository = topicRepository;
    }

    public List<ConceptResponseDTO> getConceptsByTopic(UUID topicId) {
        if (!topicRepository.existsById(topicId)) {
            throw new ResourceNotFoundException("Topic not found with id: " + topicId);
        }
        return conceptRepository.findByTopic_IdAndActiveTrueOrderByDisplayOrderAsc(topicId)
                .stream().map(ConceptResponseDTO::fromEntity).collect(Collectors.toList());
    }

    public ConceptResponseDTO getConceptById(UUID conceptId) {
        Concept concept = conceptRepository.findById(conceptId)
                .orElseThrow(() -> new ResourceNotFoundException("Concept not found with id: " + conceptId));
        return ConceptResponseDTO.fromEntity(concept);
    }
}