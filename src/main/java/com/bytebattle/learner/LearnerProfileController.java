package com.bytebattle.learner;

import com.bytebattle.common.ApiResponse;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/learner-profile")
public class LearnerProfileController {

    private final LearnerProfileService learnerProfileService;

    public LearnerProfileController(LearnerProfileService learnerProfileService) {
        this.learnerProfileService = learnerProfileService;
    }

    // GET /api/learner-profile -> get the logged-in user's own profile
    @GetMapping
    public ApiResponse<LearnerProfileResponseDTO> getMyProfile() {
        return ApiResponse.success(learnerProfileService.getMyProfile());
    }

    // POST /api/learner-profile -> create profile for the logged-in user
    @PostMapping
    public ApiResponse<LearnerProfileResponseDTO> createProfile(@Valid @RequestBody CreateLearnerProfileRequestDTO request) {
        return ApiResponse.success("Learner profile created", learnerProfileService.createProfile(request));
    }

    // PUT /api/learner-profile -> update the logged-in user's own profile
    @PutMapping
    public ApiResponse<LearnerProfileResponseDTO> updateProfile(@Valid @RequestBody UpdateLearnerProfileRequestDTO request) {
        return ApiResponse.success("Learner profile updated", learnerProfileService.updateProfile(request));
    }
}