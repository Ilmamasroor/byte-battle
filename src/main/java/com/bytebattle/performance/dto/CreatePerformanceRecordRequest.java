package com.bytebattle.performance.dto;

import com.bytebattle.performance.enums.ActivityType;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

import java.util.UUID;

public record CreatePerformanceRecordRequest(

        @NotNull
        UUID conceptId,

        @NotNull
        ActivityType activityType,

        @NotNull
        @Min(0)
        Integer score,

        @NotNull
        @DecimalMin("0.0")
        @DecimalMax("1.0")
        Double accuracy,

        @NotNull
        @Min(0)
        Integer timeSpentSeconds,

        @NotNull
        @Min(1)
        Integer attemptCount,

        @NotNull
        Boolean success,

        /**
         * Optional for activities that use hints.
         * Null is normalized to 0 by the service/entity.
         */
        @Min(0)
        Integer hintsUsed,

        /**
         * Coding evidence only.
         */
        @Min(0)
        Integer testCasesPassed,

        /**
         * Coding evidence only.
         */
        @Min(0)
        Integer testCasesTotal,

        /**
         * ID of the battle session / code submission
         * that produced this performance record.
         *
         * Used for idempotency.
         */
        UUID sourceId

) {

	public String userId() {
		// TODO Auto-generated method stub
		return null;
	}
}