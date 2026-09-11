package com.bytebattle.byte_battle_backend.curriculum;

import com.bytebattle.byte_battle_backend.common.PageResponse;
import com.bytebattle.byte_battle_backend.exception.ResourceNotFoundException;
import org.junit.jupiter.api.BeforeEach;
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
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class CurriculumServiceTest {

    @Mock
    private CurriculumDomainRepository domainRepository;

    @Mock
    private TopicRepository topicRepository;

    @InjectMocks
    private CurriculumService curriculumService;

    private final Pageable pageable = PageRequest.of(0, 10);

    @Test
    void getAllDomains_returnsPagedDomains() {
        CurriculumDomain domain = new CurriculumDomain();
        domain.setId(UUID.randomUUID());
        domain.setName("Java Basics");

        Page<CurriculumDomain> page = new PageImpl<>(Collections.singletonList(domain));
        when(domainRepository.findByActiveTrueOrderByDisplayOrderAsc(pageable)).thenReturn(page);

        PageResponse<CurriculumDomainResponseDTO> result = curriculumService.getAllDomains(pageable);

        assertEquals(1, result.getContent().size());
    }

    @Test
    void getTopicsByDomain_returnsPagedTopics() {
        UUID domainId = UUID.randomUUID();
        Topic topic = new Topic();
        topic.setId(UUID.randomUUID());
        topic.setName("Loops");
        
        CurriculumDomain parentDomain = new CurriculumDomain();
        parentDomain.setId(domainId);
        topic.setDomain(parentDomain);

        when(domainRepository.existsById(domainId)).thenReturn(true);
        Page<Topic> page = new PageImpl<>(Collections.singletonList(topic));
        when(topicRepository.findByDomain_IdAndActiveTrueOrderByDisplayOrderAsc(domainId, pageable))
                .thenReturn(page);

        PageResponse<TopicResponseDTO> result = curriculumService.getTopicsByDomain(domainId, pageable);

        assertEquals(1, result.getContent().size());
    }

    @Test
    void getTopicsByDomain_throwsWhenDomainNotFound() {
        UUID domainId = UUID.randomUUID();
        when(domainRepository.existsById(domainId)).thenReturn(false);

        assertThrows(ResourceNotFoundException.class,
                () -> curriculumService.getTopicsByDomain(domainId, pageable));
    }
}
