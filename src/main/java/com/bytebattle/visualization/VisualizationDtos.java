package com.bytebattle.visualization;

import com.fasterxml.jackson.databind.JsonNode;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.util.UUID;

public final class VisualizationDtos {

    private VisualizationDtos() {
    }

    public enum Mode { AUTO, RACE, SAFE, DEADLOCK }

    /**
     * @param allowAiFallback when the parser finds no threads, let the AI service try to extract the model with
     *                        the LLM. Off by default: the normal path is deterministic and free.
     */
    public record VisualizeRequest(
            @NotBlank @Size(max = 20000) String code,
            Mode mode,
            @Size(max = 80) String concept,
            Boolean allowAiFallback) {
    }

    public record FlowRequest(
            @NotBlank @Size(max = 20000) String code,
            @Size(max = 100) String method) {
    }

    /** A ready-made visualization for a concept (the buggy code of a seeded debugging exercise). */
    public record ConceptVisualization(
            UUID conceptId, UUID exerciseId, String title, String bugCategory, JsonNode visualization) {
    }
}
