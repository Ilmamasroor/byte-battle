package com.bytebattle.ai.service;

import com.bytebattle.curriculum.Concept;
import com.bytebattle.curriculum.ConceptRepository;
import com.bytebattle.curriculum.Topic;
import com.bytebattle.curriculum.TopicRepository;
import org.springframework.stereotype.Service;

@Service
public class AiCurriculumResolver {

    private final TopicRepository topicRepository;
    private final ConceptRepository conceptRepository;

    public AiCurriculumResolver(
            TopicRepository topicRepository,
            ConceptRepository conceptRepository) {
        this.topicRepository = topicRepository;
        this.conceptRepository = conceptRepository;
    }

    public Topic resolveTopic(String aiTopic) {
        String slug = normalizeTopic(aiTopic);

        return topicRepository.findBySlugAndActiveTrue(slug)
                .orElseThrow(() ->
                        new IllegalArgumentException(
                                "AI returned unknown curriculum topic: " + aiTopic));
    }

    public Concept resolveConcept(String aiTopic) {
        Topic topic = resolveTopic(aiTopic);

        return conceptRepository
                .findFirstByTopic_IdAndActiveTrueOrderByDisplayOrderAsc(topic.getId())
                .orElseThrow(() ->
                        new IllegalArgumentException(
                                "No active concept found for AI topic: " + aiTopic));
    }

    private String normalizeTopic(String aiTopic) {
        if (aiTopic == null || aiTopic.isBlank()) {
            throw new IllegalArgumentException("AI topic cannot be null or blank");
        }

        return aiTopic
                .trim()
                .toLowerCase()
                .replace(' ', '_');
    }
}
