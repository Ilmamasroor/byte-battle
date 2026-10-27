package com.bytebattle.learning.service;

import com.bytebattle.ai.service.PersonalizationAiService;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

/**
 * Feeds the stored evidence into diagnosis, Byte DNA evolution and recommendations off the request thread.
 * Runs after the surrounding transaction commits (or immediately when there is none); never affects the result.
 */
@Component
public class ActivityFollowUpListener {

    private final PersonalizationAiService personalizationAiService;

    public ActivityFollowUpListener(PersonalizationAiService personalizationAiService) {
        this.personalizationAiService = personalizationAiService;
    }

    @Async("followUpExecutor")
    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT, fallbackExecution = true)
    public void onEvidence(ActivityEvidenceEvent event) {
        personalizationAiService.processActivity(event.evidence());
    }
}
