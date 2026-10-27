package com.bytebattle.visualization;

import com.bytebattle.ai.client.AiVisualizationClient;
import com.bytebattle.debugging.entity.DebugExercise;
import com.bytebattle.debugging.repository.DebugExerciseRepository;
import com.bytebattle.exception.ResourceNotFoundException;
import com.bytebattle.visualization.VisualizationDtos.*;
import com.fasterxml.jackson.databind.JsonNode;
import org.springframework.stereotype.Service;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.HexFormat;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;
import java.util.function.Supplier;

/**
 * Code visualizations. The AI service does the work deterministically (parse -> simulate interleavings -> SVG);
 * this service validates the input, caches results (same code = same answer, so the common path never waits)
 * and serves ready-made demos per concept. The response carries the structured steps so the Flutter client can
 * animate them itself; the server-rendered SVG is the fallback.
 */
@Service
public class VisualizationService {

    static final int CACHE_SIZE = 200;

    private final AiVisualizationClient client;
    private final DebugExerciseRepository exerciseRepository;
    private final Map<String, JsonNode> cache = new LinkedHashMap<>(16, 0.75f, true) {
        @Override
        protected boolean removeEldestEntry(Map.Entry<String, JsonNode> eldest) {
            return size() > CACHE_SIZE;
        }
    };

    public VisualizationService(AiVisualizationClient client, DebugExerciseRepository exerciseRepository) {
        this.client = client;
        this.exerciseRepository = exerciseRepository;
    }

    public JsonNode visualize(VisualizeRequest request) {
        Mode mode = request.mode() == null ? Mode.AUTO : request.mode();
        boolean llm = Boolean.TRUE.equals(request.allowAiFallback());
        String concept = request.concept() == null || request.concept().isBlank() ? null : request.concept().trim();
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("code", request.code());
        body.put("language", "java");
        body.put("mode", mode.name().toLowerCase());
        body.put("useLlm", llm);
        if (concept != null) {
            body.put("concept", concept);
        }
        return cached(key("viz", request.code(), mode.name(), String.valueOf(llm), concept), () -> client.visualize(body));
    }

    public JsonNode flow(FlowRequest request) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("code", request.code());
        body.put("language", "java");
        if (request.method() != null && !request.method().isBlank()) {
            body.put("method", request.method().trim());
        }
        return cached(key("flow", request.code(), request.method()), () -> client.flow(body));
    }

    public ConceptVisualization forConcept(UUID conceptId) {
        DebugExercise exercise = exerciseRepository.findByConceptIdOrderByCreatedAtAsc(conceptId).stream()
                .filter(e -> e.getBuggyCode() != null && !e.getBuggyCode().isBlank())
                .findFirst()
                .orElseThrow(() -> new ResourceNotFoundException("No visualization is available for this concept yet"));
        JsonNode viz = visualize(new VisualizeRequest(exercise.getBuggyCode(), Mode.AUTO, null, false));
        return new ConceptVisualization(conceptId, exercise.getId(), exercise.getTitle(), exercise.getBugCategory(), exercise.getBuggyCode(), viz);
    }

    private JsonNode cached(String key, Supplier<JsonNode> loader) {
        synchronized (cache) {
            JsonNode hit = cache.get(key);
            if (hit != null) {
                return hit;
            }
        }
        JsonNode fresh = loader.get(); // outside the lock: the AI call can be slow; failures are never cached
        synchronized (cache) {
            cache.put(key, fresh);
        }
        return fresh;
    }

    static String key(String... parts) {
        try {
            MessageDigest sha = MessageDigest.getInstance("SHA-256");
            for (String part : parts) {
                sha.update((part == null ? "\u0000" : part).getBytes(StandardCharsets.UTF_8));
                sha.update((byte) 0x1f);
            }
            return HexFormat.of().formatHex(sha.digest());
        } catch (java.security.NoSuchAlgorithmException e) {
            throw new IllegalStateException(e);
        }
    }
}
