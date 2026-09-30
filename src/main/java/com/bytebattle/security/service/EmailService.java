package com.bytebattle.security.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

@Service
public class EmailService {

    private static final Logger log = LoggerFactory.getLogger(EmailService.class);

    private final JavaMailSender mailSender;

    @Value("${app.frontend-url:http://localhost:3000}")
    private String frontendUrl;

    public EmailService(JavaMailSender mailSender) {
        this.mailSender = mailSender;
    }

    // Async so the API response time doesn't reveal whether the email exists.
    // Errors are handled here because nobody is waiting for this call.
    @Async
    public void sendPasswordResetEmail(String toEmail, String resetToken) {
        try {
            String resetLink = frontendUrl + "/reset-password?token=" + resetToken;

            SimpleMailMessage message = new SimpleMailMessage();
            message.setTo(toEmail);
            message.setSubject("Byte Battle - Password Reset Request");
            message.setText(
                    "You requested a password reset.\n\n"
                    + "Click the link below to reset your password (valid for "
                    + AuthService.RESET_TOKEN_MINUTES + " minutes):\n"
                    + resetLink + "\n\n"
                    + "If you didn't request this, you can safely ignore this email.");

            mailSender.send(message);
        } catch (RuntimeException e) {
            log.error("Could not send password reset email", e);
        }
    }
}
