package com.bytebattle.coding.testcase;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.util.ArrayList;
import java.util.List;

/**
 * Tolerant parser for the test-case JSON stored on challenges and debug exercises:
 * {@code [{"input":"..","expectedOutput":"..","hidden":false}, ...]}.
 * {@code hidden} is optional (default false) and may be a boolean or the strings "true"/"false".
 */
public final class CodingTestCases {

    private static final ObjectMapper MAPPER = new ObjectMapper();

    private CodingTestCases() {
    }

    /** Parses and validates; throws IllegalArgumentException on malformed JSON or missing fields. */
    public static List<CodingTestCase> parse(String json) {
        if (json == null || json.isBlank()) {
            return List.of();
        }
        JsonNode node;
        try {
            node = MAPPER.readTree(json);
        } catch (Exception ex) {
            throw new IllegalArgumentException("Invalid testCases JSON");
        }
        if (node == null || !node.isArray()) {
            throw new IllegalArgumentException("testCases must be a JSON array");
        }
        List<CodingTestCase> cases = new ArrayList<>();
        for (JsonNode item : node) {
            if (!item.isObject() || !item.has("input") || !item.has("expectedOutput")) {
                throw new IllegalArgumentException("Each test case requires input and expectedOutput");
            }
            cases.add(new CodingTestCase(
                    item.get("input").asText(""),
                    item.get("expectedOutput").asText(""),
                    isTrue(item.get("hidden"))));
        }
        return cases;
    }

    /** Like {@link #parse} but returns an empty list instead of throwing (used on read paths). */
    public static List<CodingTestCase> parseLenient(String json) {
        try {
            return parse(json);
        } catch (IllegalArgumentException ex) {
            return List.of();
        }
    }

    private static boolean isTrue(JsonNode n) {
        if (n == null || n.isNull()) {
            return false;
        }
        if (n.isBoolean()) {
            return n.asBoolean();
        }
        return n.isTextual() && "true".equalsIgnoreCase(n.asText().trim());
    }
}
