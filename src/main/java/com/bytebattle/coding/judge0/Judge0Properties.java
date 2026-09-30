package com.bytebattle.coding.judge0;

import org.springframework.boot.context.properties.ConfigurationProperties;

import java.util.HashMap;
import java.util.Map;

@ConfigurationProperties(prefix = "bytebattle.judge0")
public class Judge0Properties {
    private boolean enabled = true;
    private String baseUrl = "http://localhost:2358";
    private String authToken;
    private int pollIntervalMs = 500;
    private int maxPollAttempts = 60;
    private int defaultTimeLimitMs = 2000;
    private int defaultMemoryLimitMb = 128;
    private int maxTimeLimitMs = 10000;
    private int maxMemoryLimitMb = 512;
    private int maxTestCases = 50;
    private Map<String, Integer> languageIds = new HashMap<>(Map.of(
            "C", 50,
            "CPP", 54,
            "JAVA", 62,
            "JAVASCRIPT", 63,
            "PYTHON", 71
    ));

    public boolean isEnabled() { return enabled; }
    public void setEnabled(boolean enabled) { this.enabled = enabled; }
    public String getBaseUrl() { return baseUrl; }
    public void setBaseUrl(String baseUrl) { this.baseUrl = baseUrl; }
    public String getAuthToken() { return authToken; }
    public void setAuthToken(String authToken) { this.authToken = authToken; }
    public int getPollIntervalMs() { return pollIntervalMs; }
    public void setPollIntervalMs(int pollIntervalMs) { this.pollIntervalMs = pollIntervalMs; }
    public int getMaxPollAttempts() { return maxPollAttempts; }
    public void setMaxPollAttempts(int maxPollAttempts) { this.maxPollAttempts = maxPollAttempts; }
    public int getDefaultTimeLimitMs() { return defaultTimeLimitMs; }
    public void setDefaultTimeLimitMs(int defaultTimeLimitMs) { this.defaultTimeLimitMs = defaultTimeLimitMs; }
    public int getDefaultMemoryLimitMb() { return defaultMemoryLimitMb; }
    public void setDefaultMemoryLimitMb(int defaultMemoryLimitMb) { this.defaultMemoryLimitMb = defaultMemoryLimitMb; }
    public int getMaxTimeLimitMs() { return maxTimeLimitMs; }
    public void setMaxTimeLimitMs(int maxTimeLimitMs) { this.maxTimeLimitMs = maxTimeLimitMs; }
    public int getMaxMemoryLimitMb() { return maxMemoryLimitMb; }
    public void setMaxMemoryLimitMb(int maxMemoryLimitMb) { this.maxMemoryLimitMb = maxMemoryLimitMb; }
    public int getMaxTestCases() { return maxTestCases; }
    public void setMaxTestCases(int maxTestCases) { this.maxTestCases = maxTestCases; }
    public Map<String, Integer> getLanguageIds() { return languageIds; }
    public void setLanguageIds(Map<String, Integer> languageIds) { this.languageIds = languageIds; }
}
