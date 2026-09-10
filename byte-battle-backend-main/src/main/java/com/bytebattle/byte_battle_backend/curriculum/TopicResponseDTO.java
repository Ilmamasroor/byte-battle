package com.bytebattle.byte_battle_backend.curriculum;

import java.util.UUID;

public class TopicResponseDTO {
    private UUID id;
    private UUID domainId;
    private String name;
    private String description;
    private String slug;
    private Integer displayOrder;

    public TopicResponseDTO() {
    }

    public TopicResponseDTO(UUID id, UUID domainId, String name, String description, String slug, Integer displayOrder) {
        this.id = id;
        this.domainId = domainId;
        this.name = name;
        this.description = description;
        this.slug = slug;
        this.displayOrder = displayOrder;
    }

    public static TopicResponseDTO fromEntity(Topic topic) {
        return new TopicResponseDTO(
                topic.getId(), topic.getDomain().getId(), topic.getName(),
                topic.getDescription(), topic.getSlug(), topic.getDisplayOrder()
        );
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getDomainId() { return domainId; }
    public void setDomainId(UUID domainId) { this.domainId = domainId; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    public String getSlug() { return slug; }
    public void setSlug(String slug) { this.slug = slug; }
    public Integer getDisplayOrder() { return displayOrder; }
    public void setDisplayOrder(Integer displayOrder) { this.displayOrder = displayOrder; }
}