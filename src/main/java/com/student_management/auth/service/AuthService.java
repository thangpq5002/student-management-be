package com.student_management.auth.service;

import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import com.student_management.auth.dto.request.RegisterRequest;
import com.student_management.auth.entity.User;
import com.student_management.auth.entity.UserRole;
import com.student_management.auth.entity.UserStatus;
import com.student_management.auth.repository.UserRepository;

@Service
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    public AuthService(
            UserRepository userRepository,
            PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
    }

    /**
     * Đăng nhập
     */
    public User authenticate(
            String username,
            String password) {

        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException(
                        "Username hoặc password không đúng"));

        if (user.getStatus() != UserStatus.ACTIVE) {
            throw new RuntimeException(
                    "Tài khoản đã bị vô hiệu hóa");
        }

        if (!passwordEncoder.matches(
                password,
                user.getPasswordHash())) {
            throw new RuntimeException(
                    "Username hoặc password không đúng");
        }

        return user;
    }

    /**
     * Đăng ký tài khoản
     */
    public User register(RegisterRequest request) {

        // Kiểm tra username
        if (userRepository.existsByUsername(request.getUsername())) {
            throw new RuntimeException(
                    "Username đã tồn tại");
        }

        // Kiểm tra email
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new RuntimeException(
                    "Email đã tồn tại");
        }

        // Tạo User mới
        User user = new User();

        user.setUsername(request.getUsername());
        user.setEmail(request.getEmail());

        // BCrypt password
        user.setPasswordHash(
                passwordEncoder.encode(request.getPassword()));

        // Không cho đăng ký ADMIN
        user.setRole(UserRole.TEACHER);

        // Tài khoản mới được ACTIVE
        user.setStatus(UserStatus.ACTIVE);

        return userRepository.save(user);
    }
}