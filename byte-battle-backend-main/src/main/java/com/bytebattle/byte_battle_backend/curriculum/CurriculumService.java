package com.bytebattle.byte_battle_backend.curriculum;

import com.bytebattle.byte_battle_backend.exception.ResourceNotFoundException;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class CurriculumService {

    private final CurriculumDomainRepository domainRepository;
    private final TopicRepository topicRepository;

    public CurriculumService(CurriculumDomainRepository domainRepository, TopicRepository topicRepository) {
        this.domainRepository = domainRepository;
        this.topicRepository = topicRepository;
    }

    public List<CurriculumDomainResponseDTO> getAllDomains() {
        return domainRepository.findByActiveTrueOrderByDisplayOrderAsc()
                .stream().map(CurriculumDomainResponseDTO::fromEntity).collect(Collectors.toList());
    }

    public List<TopicResponseDTO> getTopicsByDomain(UUID domainId) {
        if (!domainRepository.existsById(domainId)) {
            throw new ResourceNotFoundException("Curriculum domain not found with id: " + domainId);
        }
        return topicRepository.findByDomain_IdAndActiveTrueOrderByDisplayOrderAsc(domainId)
                .stream().map(TopicResponseDTO::fromEntity).collect(Collectors.toList());
    }
}