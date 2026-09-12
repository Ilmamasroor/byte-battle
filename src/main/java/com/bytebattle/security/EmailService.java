package com.bytebattle.security;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

@Service
public class EmailService {

    private final JavaMailSender mailSender;

    @Value("${app.frontend-url:http://localhost:3000}")
    private String frontendUrl;

    public EmailService(JavaMailSender mailSender) {
        this.mailSender = mailSender;
    }

    public void sendPasswordResetEmail(String toEmail, String resetToken) {
        String resetLink = frontendUrl + "/reset-password?token=" + resetToken;

        SimpleMailMessage message = new SimpleMailMessage();
        message.setTo(toEmail);
        message.setSubject("Byte Battle - Password Reset Request");
        message.setText(
                "You requested a password reset.\n\n" +
                		"Click the link below to reset your password (valid for 15 minutes):\n" +                resetLink + "\n\n" +
                "If you didn't request this, you can safely ignore this email."
        );

        mailSender.send(message);
    }
}