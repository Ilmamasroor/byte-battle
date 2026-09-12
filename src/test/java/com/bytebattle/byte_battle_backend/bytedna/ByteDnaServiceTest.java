package com.bytebattle.bytedna;

import com.bytebattle.bytedna.dto.ByteDNAResponseDTO;
import com.bytebattle.bytedna.dto.CreateByteDNARequestDTO;
import com.bytebattle.exception.ResourceNotFoundException;
import com.bytebattle.security.CustomUserDetails;
import com.bytebattle.user.User;
import com.bytebattle.user.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContext;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ByteDnaServiceTest {

    @Mock
    private ByteDNARepository byteDNARepository;

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private ByteDNAService byteDNAService;

    private User currentUser;
    private UUID currentUserId;

    @BeforeEach
    void setUp() {
        currentUserId = UUID.randomUUID();
        currentUser = new User();
        currentUser.setId(currentUserId);
        currentUser.setEmail("test@example.com");
        currentUser.setName("testuser");

        CustomUserDetails userDetails = new CustomUserDetails(currentUser);
        SecurityContext securityContext = mock(SecurityContext.class);
        when(securityContext.getAuthentication()).thenReturn(
                new UsernamePasswordAuthenticationToken(userDetails, null, userDetails.getAuthorities())
        );
        SecurityContextHolder.setContext(securityContext);
    }

    @Test
    void createByteDNA_succeedsForNewUser() {
        CreateByteDNARequestDTO request = new CreateByteDNARequestDTO();
        request.setTechnicalExperience(ByteDNA.TechnicalExperience.BEGINNER);
        request.setPreferredLanguage("Java");

        when(byteDNARepository.existsByUser_Id(currentUserId)).thenReturn(false);
        when(userRepository.findById(currentUserId)).thenReturn(Optional.of(currentUser));
        when(byteDNARepository.save(any(ByteDNA.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

        ByteDNAResponseDTO result = byteDNAService.createByteDNA(request);

        assertNotNull(result);
        assertEquals("Java", result.getPreferredLanguage());
    }

    @Test
    void createByteDNA_throwsWhenProfileAlreadyExists() {
        CreateByteDNARequestDTO request = new CreateByteDNARequestDTO();

        when(byteDNARepository.existsByUser_Id(currentUserId)).thenReturn(true);

        assertThrows(IllegalArgumentException.class,
                () -> byteDNAService.createByteDNA(request));
    }

    @Test
    void getMyByteDNA_returnsProfileWhenExists() {
        ByteDNA dna = new ByteDNA();
        dna.setUser(currentUser);
        dna.setTechnicalExperience(ByteDNA.TechnicalExperience.INTERMEDIATE);
        dna.setPreferredLanguage("Java");

        when(byteDNARepository.findByUser_Id(currentUserId)).thenReturn(Optional.of(dna));

        ByteDNAResponseDTO result = byteDNAService.getMyByteDNA();

        assertEquals("Java", result.getPreferredLanguage());
    }

    @Test
    void getMyByteDNA_throwsWhenProfileNotFound() {
        when(byteDNARepository.findByUser_Id(currentUserId)).thenReturn(Optional.empty());

        assertThrows(ResourceNotFoundException.class, () -> byteDNAService.getMyByteDNA());
    }
}