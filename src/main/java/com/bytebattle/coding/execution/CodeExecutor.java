package com.bytebattle.coding.execution;

import com.bytebattle.coding.dto.ExecutionRequest;
import com.bytebattle.coding.dto.ExecutionResult;

//Real implementations must run in an isolated sandbox — see doc §21.
//Never implement this by invoking a compiler/runtime directly in this JVM.
public interface CodeExecutor {
 ExecutionResult execute(ExecutionRequest request);
}