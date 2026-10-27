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
    private int defaultTimeLimitMs = 5000;
    private int defaultMemoryLimitMb = 256;
    private int maxTimeLimitMs = 15000;
    private int maxMemoryLimitMb = 512;
    private int maxTestCases = 50;
    /** Overall wall-clock budget for one execute() call (submit + polling), in milliseconds. */
    private int overallDeadlineMs = 60000;
    private int connectTimeoutMs = 3000;
    private int readTimeoutMs = 10000;
    /** Judge0 rejects batches larger than MAX_SUBMISSION_BATCH_SIZE (default 20). */
    private int batchSize = 20;
    private int maxProcessesAndOrThreads = 60;
    private int stackLimitKb = 64000;

    /**
     * JVM flags for javac, sent as Judge0 compiler_options for Java submissions. Judge0 compiles once per test
     * case, so a cheap (serial GC, C1 only) javac matters: without it parallel compiles hit Judge0's compile
     * time limit ("Compilation time limit exceeded"). Blank disables it.
     */
    private String javaCompilerOptions =
            "-J-XX:+UseSerialGC -J-XX:TieredStopAtLevel=1 -J-Xshare:auto -J-Xmx128m";
    private int maxFileSizeKb = 1024;
    /** Extra wall-clock allowance on top of the CPU limit (sleeping/blocked threads do not use CPU). */
    private int wallTimeExtraMs = 5000;
    private int maxWallTimeLimitMs = 20000;
    private Map<String, Integer> languageIds = new HashMap<>(Map.of(
            "C", 50,
            "CPP", 54,
            "JAVA", 62,
            "JAVASCRIPT", 63,
            "PYTHON", 71
    ));

    public int getOverallDeadlineMs() { return overallDeadlineMs; }
    public void setOverallDeadlineMs(int v) { this.overallDeadlineMs = v; }
    public int getConnectTimeoutMs() { return connectTimeoutMs; }
    public void setConnectTimeoutMs(int v) { this.connectTimeoutMs = v; }
    public int getReadTimeoutMs() { return readTimeoutMs; }
    public void setReadTimeoutMs(int v) { this.readTimeoutMs = v; }
    public int getBatchSize() { return batchSize; }
    public void setBatchSize(int v) { this.batchSize = v; }
    public int getMaxProcessesAndOrThreads() { return maxProcessesAndOrThreads; }
    public void setMaxProcessesAndOrThreads(int v) { this.maxProcessesAndOrThreads = v; }
    public String getJavaCompilerOptions() { return javaCompilerOptions; }
    public void setJavaCompilerOptions(String v) { this.javaCompilerOptions = v; }
    public int getStackLimitKb() { return stackLimitKb; }
    public void setStackLimitKb(int v) { this.stackLimitKb = v; }
    public int getMaxFileSizeKb() { return maxFileSizeKb; }
    public void setMaxFileSizeKb(int v) { this.maxFileSizeKb = v; }
    public int getWallTimeExtraMs() { return wallTimeExtraMs; }
    public void setWallTimeExtraMs(int v) { this.wallTimeExtraMs = v; }
    public int getMaxWallTimeLimitMs() { return maxWallTimeLimitMs; }
    public void setMaxWallTimeLimitMs(int v) { this.maxWallTimeLimitMs = v; }
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
