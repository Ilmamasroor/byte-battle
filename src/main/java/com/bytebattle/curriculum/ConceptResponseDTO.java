package com.bytebattle.curriculum;

import java.util.UUID;

public class ConceptResponseDTO {
    private UUID id;
    private UUID topicId;
    private String name;
    private String description;
    private String slug;
    private Concept.DifficultyLevel difficulty;
    private Integer displayOrder;

    public ConceptResponseDTO() {
    }

    public ConceptResponseDTO(UUID id, UUID topicId, String name, String description,
                               String slug, Concept.DifficultyLevel difficulty, Integer displayOrder) {
        this.id = id;
        this.topicId = topicId;
        this.name = name;
        this.description = description;
        this.slug = slug;
        this.difficulty = difficulty;
        this.displayOrder = displayOrder;
    }

    public static ConceptResponseDTO fromEntity(Concept concept) {
        return new ConceptResponseDTO(
                concept.getId(), concept.getTopic().getId(), concept.getName(),
                concept.getDescription(), concept.getSlug(), concept.getDifficulty(),
                concept.getDisplayOrder()
        );
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getTopicId() { return topicId; }
    public void setTopicId(UUID topicId) { this.topicId = topicId; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    public String getSlug() { return slug; }
    public void setSlug(String slug) { this.slug = slug; }
    public Concept.DifficultyLevel getDifficulty() { return difficulty; }
    public void setDifficulty(Concept.DifficultyLevel difficulty) { this.difficulty = difficulty; }
    public Integer getDisplayOrder() { return displayOrder; }
    public void setDisplayOrder(Integer displayOrder) { this.displayOrder = displayOrder; }
}