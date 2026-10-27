package com.bytebattle.visualization;

import com.bytebattle.visualization.VisualizationDtos.*;
import com.fasterxml.jackson.databind.JsonNode;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/visualize")
public class VisualizationController {

    private final VisualizationService visualizationService;

    public VisualizationController(VisualizationService visualizationService) {
        this.visualizationService = visualizationService;
    }

    /** Thread interleavings, hazards (race / deadlock), step-by-step values, SVG and a fix suggestion. */
    @PostMapping
    public ResponseEntity<JsonNode> visualize(@RequestBody @Valid VisualizeRequest request) {
        return ResponseEntity.ok(visualizationService.visualize(request));
    }

    /** Control-flow graph of the code (or of one method). */
    @PostMapping("/flow")
    public ResponseEntity<JsonNode> flow(@RequestBody @Valid FlowRequest request) {
        return ResponseEntity.ok(visualizationService.flow(request));
    }

    /** Ready-made visualization for a concept; 404 when none exists. */
    @GetMapping("/concepts/{conceptId}")
    public ResponseEntity<ConceptVisualization> forConcept(@PathVariable UUID conceptId) {
        return ResponseEntity.ok(visualizationService.forConcept(conceptId));
    }
}
