package com.student_management.config;

import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.UUID;
import java.util.function.Function;

import javax.crypto.SecretKey;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import com.student_management.auth.entity.User;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;

@Service
public class JwtService {

    @Value("${jwt.secret}")
    private String secret;

    @Value("${jwt.expiration}")
    private long expiration;

    /**
     * Tạo SecretKey từ JWT secret
     */
    private SecretKey getSigningKey() {
        return Keys.hmacShaKeyFor(
                secret.getBytes(StandardCharsets.UTF_8));
    }

    /**
     * Tạo JWT token cho User
     */
    public String generateToken(User user) {

        return Jwts.builder()
                .subject(user.getUsername())

                // Lưu userId vào JWT
                .claim("userId", user.getId().toString())

                // Lưu role vào JWT
                .claim("role", user.getRole().name())

                // Thời gian tạo
                .issuedAt(new Date())

                // Thời gian hết hạn
                .expiration(
                        new Date(System.currentTimeMillis() + expiration))

                // Ký token
                .signWith(getSigningKey())

                .compact();
    }

    /**
     * Lấy username từ JWT
     */
    public String extractUsername(String token) {
        return extractClaim(token, Claims::getSubject);
    }

    /**
     * Lấy role từ JWT
     */
    public String extractRole(String token) {
        return extractAllClaims(token)
                .get("role", String.class);
    }

    /**
     * Lấy userId từ JWT
     */
    public UUID extractUserId(String token) {

        String userId = extractAllClaims(token)
                .get("userId", String.class);

        return UUID.fromString(userId);
    }

    /**
     * Kiểm tra token có hợp lệ hay không
     */
    public boolean isTokenValid(String token) {

        try {
            extractAllClaims(token);
            return true;

        } catch (Exception e) {
            return false;
        }
    }

    /**
     * Lấy một claim cụ thể
     */
    private <T> T extractClaim(
            String token,
            Function<Claims, T> claimsResolver) {

        Claims claims = extractAllClaims(token);

        return claimsResolver.apply(claims);
    }

    /**
     * Parse toàn bộ claims trong JWT
     */
    private Claims extractAllClaims(String token) {

        return Jwts.parser()
                .verifyWith(getSigningKey())
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }
}