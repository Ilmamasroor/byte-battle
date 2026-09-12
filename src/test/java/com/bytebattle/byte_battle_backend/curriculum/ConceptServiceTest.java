package com.bytebattle.curriculum;

import com.bytebattle.common.PageResponse;
import com.bytebattle.exception.ResourceNotFoundException;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;

import java.util.Collections;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ConceptServiceTest {

    @Mock
    private ConceptRepository conceptRepository;

    @Mock
    private TopicRepository topicRepository;

    @InjectMocks
    private ConceptService conceptService;

    private final Pageable pageable = PageRequest.of(0, 10);

    @Test
    void getConceptsByTopic_throwsWhenTopicNotFound() {
        UUID topicId = UUID.randomUUID();
        when(topicRepository.existsById(topicId)).thenReturn(false);

        assertThrows(ResourceNotFoundException.class,
                () -> conceptService.getConceptsByTopic(topicId, pageable));
    }

    @Test
    void getConceptsByTopic_returnsPagedConcepts() {
        UUID topicId = UUID.randomUUID();
        Concept concept = new Concept();
        concept.setId(UUID.randomUUID());
        concept.setName("Recursion");
        
        Topic parentTopic = new Topic();
        parentTopic.setId(topicId);
        concept.setTopic(parentTopic);

        when(topicRepository.existsById(topicId)).thenReturn(true);
        Page<Concept> page = new PageImpl<>(Collections.singletonList(concept));
        when(conceptRepository.findByTopic_IdAndActiveTrueOrderByDisplayOrderAsc(topicId, pageable))
                .thenReturn(page);

        PageResponse<ConceptResponseDTO> result = conceptService.getConceptsByTopic(topicId, pageable);

        assertEquals(1, result.getContent().size());
    }

    @Test
    void getConceptById_returnsConceptWhenFound() {
        UUID conceptId = UUID.randomUUID();
        Concept concept = new Concept();
        concept.setId(conceptId);
        concept.setName("Recursion");

        Topic parentTopic = new Topic();
        parentTopic.setId(conceptId);
        concept.setTopic(parentTopic);
        
        when(conceptRepository.findById(conceptId)).thenReturn(Optional.of(concept));

        ConceptResponseDTO result = conceptService.getConceptById(conceptId);

        assertEquals("Recursion", result.getName());
    }

    @Test
    void getConceptById_throwsWhenConceptNotFound() {
        UUID conceptId = UUID.randomUUID();
        when(conceptRepository.findById(conceptId)).thenReturn(Optional.empty());

        assertThrows(ResourceNotFoundException.class, () -> conceptService.getConceptById(conceptId));
    }
}
