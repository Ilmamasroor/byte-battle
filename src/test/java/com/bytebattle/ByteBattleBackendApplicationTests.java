package com.bytebattle;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

/** Smoke test: the whole context wires up (in-memory H2, no Flyway, no PostgreSQL required). */
@SpringBootTest
@ActiveProfiles("test")
class ByteBattleBackendApplicationTests {

	@Test
	void contextLoads() {
	}

}
