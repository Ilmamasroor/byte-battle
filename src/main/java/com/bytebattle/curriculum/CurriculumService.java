package com.bytebattle.curriculum;

import com.bytebattle.common.PageResponse;
import com.bytebattle.exception.ResourceNotFoundException;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
public class CurriculumService {

    private final CurriculumDomainRepository domainRepository;
    private final TopicRepository topicRepository;

    public CurriculumService(CurriculumDomainRepository domainRepository, TopicRepository topicRepository) {
        this.domainRepository = domainRepository;
        this.topicRepository = topicRepository;
    }

    public PageResponse<CurriculumDomainResponseDTO> getAllDomains(Pageable pageable) {
        Page<CurriculumDomainResponseDTO> page = domainRepository
                .findByActiveTrueOrderByDisplayOrderAsc(pageable)
                .map(CurriculumDomainResponseDTO::fromEntity);
        return PageResponse.fromPage(page);
    }

    public PageResponse<TopicResponseDTO> getTopicsByDomain(UUID domainId, Pageable pageable) {
        if (!domainRepository.existsById(domainId)) {
            throw new ResourceNotFoundException("Curriculum domain not found with id: " + domainId);
        }
        Page<TopicResponseDTO> page = topicRepository
                .findByDomain_IdAndActiveTrueOrderByDisplayOrderAsc(domainId, pageable)
                .map(TopicResponseDTO::fromEntity);
        return PageResponse.fromPage(page);
    }
}