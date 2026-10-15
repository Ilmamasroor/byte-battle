package com.bytebattle.learning.service;

import com.bytebattle.ai.service.PersonalizationAiService.ActivityEvidence;

/** Published once a graded activity (battle, debugging, interview) has been stored; handled asynchronously. */
public record ActivityEvidenceEvent(ActivityEvidence evidence) {
}
