package com.bytebattle.security.service;

import com.bytebattle.user.entity.User;
import com.bytebattle.user.repository.UserRepository;

import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

@Service
public class CustomUserDetailsService implements UserDetailsService {

    private final UserRepository userRepository;

    public CustomUserDetailsService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    /*
     * Used during normal login.
     *
     * Login uses email as the username.
     */
    @Override
    public UserDetails loadUserByUsername(String email)
            throws UsernameNotFoundException {

        User user = userRepository.findByEmail(email.trim().toLowerCase())
                .orElseThrow(() ->
                        new UsernameNotFoundException("User not found")
                );

        return new CustomUserDetails(user);
    }

    /*
     * Used by JwtAuthFilter.
     *
     * JWT contains the user's ID as its subject.
     */
    public UserDetails loadUserById(String userId)
            throws UsernameNotFoundException {

        User user = userRepository.findByIdAndActiveTrue(userId)
                .orElseThrow(() ->
                        new UsernameNotFoundException("User not found")
                );

        return new CustomUserDetails(user);
    }

	public User getUser() {
		// TODO Auto-generated method stub
		return null;
	}
}