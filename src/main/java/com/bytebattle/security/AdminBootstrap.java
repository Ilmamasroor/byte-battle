package com.bytebattle.security;

import com.bytebattle.user.User;
import com.bytebattle.user.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/**
 * DEV/OPS convenience: if {@code bytebattle.admin.bootstrap-email} (env ADMIN_BOOTSTRAP_EMAIL) is set and a
 * user with that email exists, promote them to ADMIN at startup. There is no default value, and
 * registration itself can never choose a role.
 */
@Component
public class AdminBootstrap implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(AdminBootstrap.class);

    private final UserRepository userRepository;
    private final String bootstrapEmail;

    public AdminBootstrap(UserRepository userRepository,
                          @Value("${bytebattle.admin.bootstrap-email:}") String bootstrapEmail) {
        this.userRepository = userRepository;
        this.bootstrapEmail = bootstrapEmail;
    }

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        if (bootstrapEmail == null || bootstrapEmail.isBlank()) {
            return;
        }
        String email = bootstrapEmail.trim();
        userRepository.findByEmail(email).ifPresentOrElse(user -> {
            if (user.getRole() == User.Role.ADMIN) {
                log.info("Admin bootstrap: user {} is already ADMIN", email);
            } else {
                user.setRole(User.Role.ADMIN);
                userRepository.save(user);
                log.warn("Admin bootstrap: promoted user {} to ADMIN (bytebattle.admin.bootstrap-email)", email);
            }
        }, () -> log.warn("Admin bootstrap: no user with email {} exists yet; register first, then restart", email));
    }
}
