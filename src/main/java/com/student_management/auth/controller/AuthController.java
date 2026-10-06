package com.student_management.auth.controller;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.student_management.auth.dto.request.LoginRequest;
import com.student_management.auth.dto.request.RegisterRequest;
import com.student_management.auth.dto.response.LoginResponse;
import com.student_management.auth.entity.User;
import com.student_management.auth.service.AuthService;
import com.student_management.config.JwtService;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthService authService;
    private final JwtService jwtService;

    public AuthController(
            AuthService authService,
            JwtService jwtService) {
        this.authService = authService;
        this.jwtService = jwtService;
    }

    /**
     * LOGIN
     */
    @PostMapping("/login")
    public ResponseEntity<LoginResponse> login(
            @Valid @RequestBody LoginRequest request) {

        User user = authService.authenticate(
                request.getUsername(),
                request.getPassword());

        String token = jwtService.generateToken(user);

        LoginResponse response = new LoginResponse(
                token,
                user.getUsername(),
                user.getRole().name());

        return ResponseEntity.ok(response);
    }

    /**
     * REGISTER
     */
    @PostMapping("/register")
    public ResponseEntity<LoginResponse> register(
            @Valid @RequestBody RegisterRequest request) {

        User user = authService.register(request);

        // Tự động đăng nhập sau khi đăng ký
        String token = jwtService.generateToken(user);

        LoginResponse response = new LoginResponse(
                token,
                user.getUsername(),
                user.getRole().name());

        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(response);
    }
}