package com.bytebattle.curriculum;

import java.util.UUID;

public class CurriculumDomainResponseDTO {
    private UUID id;
    private String name;
    private String description;
    private String slug;
    private Integer displayOrder;

    public CurriculumDomainResponseDTO() {
    }

    public CurriculumDomainResponseDTO(UUID id, String name, String description, String slug, Integer displayOrder) {
        this.id = id;
        this.name = name;
        this.description = description;
        this.slug = slug;
        this.displayOrder = displayOrder;
    }

    public static CurriculumDomainResponseDTO fromEntity(CurriculumDomain domain) {
        return new CurriculumDomainResponseDTO(
                domain.getId(), domain.getName(), domain.getDescription(),
                domain.getSlug(), domain.getDisplayOrder()
        );
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    public String getSlug() { return slug; }
    public void setSlug(String slug) { this.slug = slug; }
    public Integer getDisplayOrder() { return displayOrder; }
    public void setDisplayOrder(Integer displayOrder) { this.displayOrder = displayOrder; }
}