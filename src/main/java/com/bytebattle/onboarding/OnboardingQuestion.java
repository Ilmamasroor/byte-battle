package com.bytebattle.onboarding;

import java.util.List;

/** One onboarding question, as served to the client (the client renders it; the server validates the answer). */
public record OnboardingQuestion(
        String id,                 // also the field name in the POST /api/onboarding body
        String prompt,
        String type,               // SINGLE_CHOICE | MULTI_SELECT | NUMBER_CHOICE
        boolean required,
        Integer maxSelections,     // MULTI_SELECT only
        boolean allowCustom,       // the learner may type a value that is not in the options
        List<Option> options) {

    public record Option(String value, String label) {
    }
}
