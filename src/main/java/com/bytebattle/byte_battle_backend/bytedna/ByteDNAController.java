package com.bytebattle.byte_battle_backend.bytedna;

import com.bytebattle.byte_battle_backend.bytedna.dto.ByteDNAResponseDTO;
import com.bytebattle.byte_battle_backend.bytedna.dto.CreateByteDNARequestDTO;
import com.bytebattle.byte_battle_backend.bytedna.dto.UpdateByteDNARequestDTO;
import com.bytebattle.byte_battle_backend.common.ApiResponse;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/byte-dna")
public class ByteDNAController {

    private final ByteDNAService byteDNAService;

    public ByteDNAController(ByteDNAService byteDNAService) {
        this.byteDNAService = byteDNAService;
    }

    // GET /api/byte-dna -> get the logged-in user's own Byte DNA
    @GetMapping
    public ApiResponse<ByteDNAResponseDTO> getMyByteDNA() {
        return ApiResponse.success(byteDNAService.getMyByteDNA());
    }

    // POST /api/byte-dna -> create Byte DNA for the logged-in user
    @PostMapping
    public ApiResponse<ByteDNAResponseDTO> createByteDNA(@Valid @RequestBody CreateByteDNARequestDTO request) {
        return ApiResponse.success("Byte DNA profile created", byteDNAService.createByteDNA(request));
    }

    // PUT /api/byte-dna -> update the logged-in user's own Byte DNA
    @PutMapping
    public ApiResponse<ByteDNAResponseDTO> updateByteDNA(@Valid @RequestBody UpdateByteDNARequestDTO request) {
        return ApiResponse.success("Byte DNA profile updated", byteDNAService.updateByteDNA(request));
    }
}