package com.bytebattle.common;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.AsyncConfigurer;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;


/** Bounded executors for best-effort background work. Rejected tasks are dropped (and logged), never block a request. */
@Configuration
@EnableAsync
public class AsyncConfig implements AsyncConfigurer {

    private static final Logger log = LoggerFactory.getLogger(AsyncConfig.class);

    @Bean(name = "followUpExecutor")
    public ThreadPoolTaskExecutor followUpExecutor() {
        return build("follow-up-", 2, 4, 100);
    }

    /** Runs the (possibly slow) AI feedback call so the follow-up thread can enforce a timeout on it. */
    @Bean(name = "aiCallExecutor")
    public ThreadPoolTaskExecutor aiCallExecutor() {
        return build("ai-call-", 2, 4, 50);
    }

    @Override
    public java.util.concurrent.Executor getAsyncExecutor() {
        return followUpExecutor();
    }

    @Override
    public org.springframework.aop.interceptor.AsyncUncaughtExceptionHandler getAsyncUncaughtExceptionHandler() {
        return (ex, method, params) -> log.error("Async task {} failed", method.getName(), ex);
    }

    private static ThreadPoolTaskExecutor build(String prefix, int core, int max, int queue) {
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
        executor.setThreadNamePrefix(prefix);
        executor.setCorePoolSize(core);
        executor.setMaxPoolSize(max);
        executor.setQueueCapacity(queue);
        executor.setRejectedExecutionHandler((task, pool) ->
                log.warn("Background queue '{}' is full; dropping a best-effort task", prefix));
        executor.setWaitForTasksToCompleteOnShutdown(false);
        return executor;
    }
}
