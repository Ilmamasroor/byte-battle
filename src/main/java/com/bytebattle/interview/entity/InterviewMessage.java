package com.bytebattle.interview.entity;

import com.bytebattle.interview.enums.InterviewMessageRole;
import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(
        name = "interview_messages",
        indexes = {
                @Index(
                        name = "idx_interview_message_session_sequence",
                        columnList = "interview_session_id, sequence_number"
                )
        },
        uniqueConstraints = {
                @UniqueConstraint(
                        name = "uk_interview_message_session_sequence",
                        columnNames = {
                                "interview_session_id",
                                "sequence_number"
                        }
                )
        }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class InterviewMessage {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "interview_session_id", nullable = false)
    private UUID interviewSessionId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private InterviewMessageRole role;

    @Column(columnDefinition = "TEXT", nullable = false)
    private String content;

    @Column(name = "sequence_number", nullable = false)
    private Integer sequenceNumber;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @PrePersist
    void onCreate() {
        createdAt = Instant.now();
    }
}