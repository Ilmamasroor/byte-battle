package com.bytebattle.coding.execution;

import com.bytebattle.coding.dto.ExecutionRequest;
import com.bytebattle.coding.dto.ExecutionResult;
import com.bytebattle.coding.judge0.Judge0Client;
import org.springframework.stereotype.Component;

@Component
public class Judge0CodeExecutor implements CodeExecutor {
    private final Judge0Client judge0Client;

    public Judge0CodeExecutor(Judge0Client judge0Client) {
        this.judge0Client = judge0Client;
    }

    @Override
    public ExecutionResult execute(ExecutionRequest request) {
        return judge0Client.execute(request);
    }
}
