-- ============================================================
-- SEED ASSESSMENT TYPES (Bắt buộc cho nghiệp vụ tính điểm)
-- ============================================================
INSERT INTO
    assessment_types (code, name, weight)
VALUES ('ORAL', 'Điểm miệng', 1),
    ('QUIZ', 'Điểm kiểm tra', 1),
    ('MIDTERM', 'Điểm giữa kỳ', 2),
    ('FINAL', 'Điểm cuối kỳ', 3),
    ('OTHER', 'Điểm khác', 1) ON CONFLICT (code) DO NOTHING;