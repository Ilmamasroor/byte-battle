package com.bytebattle.coding;

import com.bytebattle.coding.testcase.CodingTestCase;
import com.bytebattle.coding.testcase.CodingTestCases;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class CodingTestCasesTest {

    @Test
    void hiddenDefaultsToFalseForLegacyJson() {
        List<CodingTestCase> cases = CodingTestCases.parse("[{\"input\":\"1\",\"expectedOutput\":\"2\"}]");
        assertThat(cases).containsExactly(new CodingTestCase("1", "2", false));
    }

    @Test
    void parsesHiddenTolerantly() {
        List<CodingTestCase> cases = CodingTestCases.parse(
                "[{\"input\":\"a\",\"expectedOutput\":\"b\",\"hidden\":true},"
                        + "{\"input\":\"c\",\"expectedOutput\":\"d\",\"hidden\":\"TRUE\"},"
                        + "{\"input\":\"e\",\"expectedOutput\":\"f\",\"hidden\":null},"
                        + "{\"input\":\"g\",\"expectedOutput\":\"h\",\"hidden\":\"nope\"}]");
        assertThat(cases).extracting(CodingTestCase::hidden).containsExactly(true, true, false, false);
    }

    @Test
    void rejectsMalformedJsonAndMissingFields() {
        assertThatThrownBy(() -> CodingTestCases.parse("{}")).isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> CodingTestCases.parse("[{\"input\":\"1\"}]")).isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> CodingTestCases.parse("garbage")).isInstanceOf(IllegalArgumentException.class);
        assertThat(CodingTestCases.parseLenient("garbage")).isEmpty();
        assertThat(CodingTestCases.parse(null)).isEmpty();
    }
}
