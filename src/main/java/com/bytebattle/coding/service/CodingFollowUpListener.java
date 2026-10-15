package com.bytebattle.coding.service;

import com.bytebattle.ai.dto.feature.CodingFeedbackResponse;
import com.bytebattle.ai.service.AiFeatureService;
import com.bytebattle.ai.service.PersonalizationAiService;
import com.bytebattle.coding.dto.ExecutionResult;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.event.EventListener;
import org.springframework.core.task.TaskExecutor;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;

/**
 * Best-effort follow-up after a coding submission is persisted: personalization, then AI feedback.
 * Runs off the request thread; failures are only logged and never affect the learner's result.
 */
@Component
public class CodingFollowUpListener {

    private static final Logger log = LoggerFactory.getLogger(CodingFollowUpListener.class);

    private final PersonalizationAiService personalizationAiService;
    private final AiFeatureService aiFeatureService;
    private final CodingSubmissionStore store;
    private final TaskExecutor aiCallExecutor;
    private final long feedbackTimeoutMs;

    public CodingFollowUpListener(
            PersonalizationAiService personalizationAiService,
            AiFeatureService aiFeatureService,
            CodingSubmissionStore store,
            @Qualifier("aiCallExecutor") TaskExecutor aiCallExecutor,
            @Value("${bytebattle.coding.ai-feedback-timeout-ms:8000}") long feedbackTimeoutMs) {
        this.personalizationAiService = personalizationAiService;
        this.aiFeatureService = aiFeatureService;
        this.store = store;
        this.aiCallExecutor = aiCallExecutor;
        this.feedbackTimeoutMs = feedbackTimeoutMs;
    }

    @Async("followUpExecutor")
    @EventListener
    public void onSubmissionCompleted(CodingSubmissionCompletedEvent event) {
        try {
            personalizationAiService.processCodingAttempt(event.userId(), event.conceptId(), event.result());
        } catch (RuntimeException e) {
            log.warn("Coding personalization failed for submission {}", event.submissionId(), e);
        }

        try {
            String feedback = generateFeedbackWithTimeout(event);
            if (feedback != null && !feedback.isBlank()) {
                store.saveAiFeedback(event.submissionId(), feedback);
            }
        } catch (RuntimeException e) {
            log.warn("Coding AI feedback failed for submission {}", event.submissionId(), e);
        }
    }

    private String generateFeedbackWithTimeout(CodingSubmissionCompletedEvent event) {
        CompletableFuture<String> future = CompletableFuture.supplyAsync(() -> generateFeedback(event), aiCallExecutor);
        try {
            return future.get(feedbackTimeoutMs, TimeUnit.MILLISECONDS);
        } catch (TimeoutException e) {
            future.cancel(true);
            log.info("Coding AI feedback timed out after {} ms for submission {}", feedbackTimeoutMs,
                    event.submissionId());
            return null;
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            return null;
        } catch (java.util.concurrent.ExecutionException e) {
            log.warn("Coding AI feedback failed for submission {}: {}", event.submissionId(),
                    e.getCause() == null ? e.getMessage() : e.getCause().getClass().getSimpleName());
            return null;
        }
    }

    private String generateFeedback(CodingSubmissionCompletedEvent event) {
        ExecutionResult result = event.result();

        Map<String, Object> concept = new LinkedHashMap<>();
        concept.put("conceptId", event.conceptId());
        concept.put("title", event.challengeTitle());
        concept.put("difficulty", event.difficulty());
        concept.put("language", event.language());

        Map<String, Object> diagnosis = new LinkedHashMap<>();
        diagnosis.put("activityType", "coding");
        diagnosis.put("executionStatus", result.status().name());
        diagnosis.put("executionTimeMs", result.executionTimeMs());
        diagnosis.put("testCasesPassed", result.testCasesPassed());
        diagnosis.put("testCasesTotal", result.testCasesTotal());
        diagnosis.put("errorMessage", result.errorMessage());
        diagnosis.put("sourceCode", event.sourceCode());

        CodingFeedbackResponse response = aiFeatureService.generateCodingFeedback(concept, diagnosis);
        return response == null ? null : response.feedback();
    }
}
