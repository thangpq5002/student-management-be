-- ============================================================
-- 0. EXTENSION
-- ============================================================
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ============================================================
-- 1. ENUMS
-- ============================================================
CREATE TYPE user_role AS ENUM ('ADMIN', 'TEACHER');

CREATE TYPE user_status AS ENUM ('ACTIVE', 'INACTIVE');

CREATE TYPE teacher_status AS ENUM ('ACTIVE', 'INACTIVE');

CREATE TYPE class_status AS ENUM ('ACTIVE', 'INACTIVE');

CREATE TYPE subject_status AS ENUM ('ACTIVE', 'INACTIVE');

CREATE TYPE gender AS ENUM ('MALE', 'FEMALE', 'OTHER');

CREATE TYPE student_status AS ENUM ('ACTIVE', 'INACTIVE', 'GRADUATED', 'TRANSFERRED');

CREATE TYPE enrollment_status AS ENUM ('ACTIVE', 'COMPLETED', 'TRANSFERRED', 'DROPPED');

CREATE TYPE semester AS ENUM ('SEMESTER_1', 'SEMESTER_2');

CREATE TYPE assessment_type AS ENUM ('ORAL', 'QUIZ', 'MIDTERM', 'FINAL', 'OTHER');

CREATE TYPE attendance_type AS ENUM ('CLASS', 'SUBJECT');

CREATE TYPE attendance_status AS ENUM ('PRESENT', 'ABSENT', 'LATE', 'EXCUSED');

-- ============================================================
-- 2. USERS
-- Tài khoản đăng nhập hệ thống, quản lý username, email, password,
-- role (ADMIN/TEACHER) và trạng thái tài khoản.
-- ============================================================
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid (),
    username VARCHAR(50) NOT NULL,
    email VARCHAR(255) NOT NULL,
    password_hash TEXT NOT NULL,
    role user_role NOT NULL,
    status user_status NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_users_username UNIQUE (username),
    CONSTRAINT uq_users_email UNIQUE (email)
);

CREATE INDEX idx_users_role ON users (role);

CREATE INDEX idx_users_status ON users (status);

-- ============================================================
-- 3. TEACHERS
-- Thông tin hồ sơ giáo viên, liên kết 1-1 với tài khoản USERS.
-- ============================================================
CREATE TABLE teachers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid (),
    teacher_code VARCHAR(50) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(20),
    address TEXT,
    status teacher_status NOT NULL DEFAULT 'ACTIVE',
    user_id UUID NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_teachers_code UNIQUE (teacher_code),
    CONSTRAINT uq_teachers_user UNIQUE (user_id),
    CONSTRAINT fk_teachers_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);

CREATE INDEX idx_teachers_name ON teachers (last_name, first_name);

CREATE INDEX idx_teachers_status ON teachers (status);

-- ============================================================
-- 4. STUDENTS
-- Thông tin cá nhân và trạng thái của sinh viên/học sinh.
-- ============================================================
CREATE TABLE students (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid (),
    student_code VARCHAR(50) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    date_of_birth DATE,
    gender gender,
    email VARCHAR(255),
    phone VARCHAR(20),
    address TEXT,
    parent_name VARCHAR(200),
    parent_phone VARCHAR(20),
    status student_status NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_students_code UNIQUE (student_code)
);

CREATE INDEX idx_students_name ON students (last_name, first_name);

CREATE INDEX idx_students_status ON students (status);

-- ============================================================
-- 5. CLASSES
-- Danh sách lớp học, niên khóa và giáo viên chủ nhiệm.
-- ============================================================

CREATE TABLE classes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid (),
    class_code VARCHAR(50) NOT NULL,
    name VARCHAR(100) NOT NULL,
    grade_level INTEGER NOT NULL,
    academic_year VARCHAR(20) NOT NULL,
    status class_status NOT NULL DEFAULT 'ACTIVE',
    homeroom_teacher_id UUID,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_classes_code UNIQUE (class_code),
    CONSTRAINT fk_classes_homeroom_teacher FOREIGN KEY (homeroom_teacher_id) REFERENCES teachers (id) ON DELETE SET NULL,
    CONSTRAINT check_classes_grade_level CHECK (grade_level BETWEEN 1 AND 12)
);

CREATE INDEX idx_classes_academic_year ON classes (academic_year);

CREATE INDEX idx_classes_grade_level ON classes (grade_level);

CREATE INDEX idx_classes_homeroom_teacher ON classes (homeroom_teacher_id);

-- ============================================================
-- 6. SUBJECTS
-- Danh mục môn học và các thông tin cấu hình của môn.
-- ============================================================
CREATE TABLE subjects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid (),
    subject_code VARCHAR(50) NOT NULL,
    name VARCHAR(150) NOT NULL,
    description TEXT,
    periods_per_week INTEGER,
    weight INTEGER NOT NULL DEFAULT 1,
    status subject_status NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_subjects_code UNIQUE (subject_code),
    CONSTRAINT check_subject_periods CHECK (
        periods_per_week IS NULL
        OR periods_per_week > 0
    ),
    CONSTRAINT check_subject_weight CHECK (weight > 0)
);

CREATE INDEX idx_subjects_status ON subjects (status);

-- ============================================================
-- 7. CLASS_SUBJECTS
-- Xác định môn học nào được mở cho lớp nào trong từng
-- năm học và học kỳ.
-- ============================================================

CREATE TABLE class_subjects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid (),
    class_id UUID NOT NULL,
    subject_id UUID NOT NULL,
    academic_year VARCHAR(20) NOT NULL,
    semester semester NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_class_subjects_class FOREIGN KEY (class_id) REFERENCES classes (id) ON DELETE CASCADE,
    CONSTRAINT fk_class_subjects_subject FOREIGN KEY (subject_id) REFERENCES subjects (id) ON DELETE CASCADE,
    CONSTRAINT uq_class_subjects UNIQUE (
        class_id,
        subject_id,
        academic_year,
        semester
    ),
    CONSTRAINT uq_class_subject_identity UNIQUE (id, class_id)
);

CREATE INDEX idx_class_subjects_class ON class_subjects (class_id);

CREATE INDEX idx_class_subjects_subject ON class_subjects (subject_id);

CREATE INDEX idx_class_subjects_year_semester ON class_subjects (academic_year, semester);

-- ============================================================
-- 8. CLASS_TEACHERS
-- Phân công giáo viên dạy một môn cụ thể của một lớp.
-- Liên kết TEACHER với CLASS_SUBJECT.
-- ============================================================

CREATE TABLE class_teachers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid (),
    class_subject_id UUID NOT NULL,
    teacher_id UUID NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_class_teachers_class_subject FOREIGN KEY (class_subject_id) REFERENCES class_subjects (id) ON DELETE CASCADE,
    CONSTRAINT fk_class_teachers_teacher FOREIGN KEY (teacher_id) REFERENCES teachers (id) ON DELETE CASCADE,
    CONSTRAINT uq_class_subject_teacher UNIQUE (class_subject_id, teacher_id),
    CONSTRAINT uq_class_teacher_identity UNIQUE (id, class_subject_id)
);

CREATE INDEX idx_class_teachers_class_subject ON class_teachers (class_subject_id);

CREATE INDEX idx_class_teachers_teacher ON class_teachers (teacher_id);

-- ============================================================
-- 9. ENROLLMENTS
-- Ghi nhận sinh viên thuộc lớp nào trong từng năm học.
-- Đây là bảng liên kết STUDENTS với CLASSES.
-- ============================================================

CREATE TABLE enrollments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid (),
    student_id UUID NOT NULL,
    class_id UUID NOT NULL,
    academic_year VARCHAR(20) NOT NULL,
    enrollment_date DATE NOT NULL DEFAULT CURRENT_DATE,
    status enrollment_status NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_enrollments_student FOREIGN KEY (student_id) REFERENCES students (id) ON DELETE CASCADE,
    CONSTRAINT fk_enrollments_class FOREIGN KEY (class_id) REFERENCES classes (id) ON DELETE RESTRICT,
    CONSTRAINT uq_student_academic_year UNIQUE (student_id, academic_year),
    CONSTRAINT uq_enrollment_identity UNIQUE (id, class_id)
);

CREATE INDEX idx_enrollments_student ON enrollments (student_id);

CREATE INDEX idx_enrollments_class ON enrollments (class_id);

CREATE INDEX idx_enrollments_year ON enrollments (academic_year);

-- ============================================================
-- 10. ASSESSMENT_TYPES
-- Danh mục các hình thức đánh giá và hệ số điểm tương ứng.
-- ============================================================

CREATE TABLE assessment_types (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid (),
    code assessment_type NOT NULL,
    name VARCHAR(100) NOT NULL,
    weight INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_assessment_type_code UNIQUE (code),
    CONSTRAINT check_assessment_weight CHECK (weight > 0)
);

-- ============================================================
-- 11. GRADES
-- Lưu điểm của sinh viên theo lớp-môn, học kỳ và loại đánh giá.
-- Điểm được nhập bởi giáo viên được phân công.
-- ============================================================

CREATE TABLE grades (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid (),
    enrollment_id UUID NOT NULL,
    class_teacher_id UUID NOT NULL,
    semester semester NOT NULL,
    assessment_type assessment_type NOT NULL,
    score NUMERIC(4, 2) NOT NULL,
    note TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_grades_enrollment FOREIGN KEY (enrollment_id) REFERENCES enrollments (id) ON DELETE CASCADE,
    CONSTRAINT fk_grades_class_teacher FOREIGN KEY (class_teacher_id) REFERENCES class_teachers (id) ON DELETE RESTRICT,
    CONSTRAINT check_grade_score CHECK (
        score >= 0
        AND score <= 10
    )
);

CREATE INDEX idx_grades_enrollment ON grades (enrollment_id);

CREATE INDEX idx_grades_class_teacher ON grades (class_teacher_id);

CREATE INDEX idx_grades_semester ON grades (semester);

CREATE INDEX idx_grades_assessment_type ON grades (assessment_type);

-- ============================================================
-- 12. ATTENDANCE_SESSIONS
-- Lưu một buổi/phiên điểm danh của lớp hoặc của một môn học.
-- Có thể điểm danh theo CLASS hoặc SUBJECT.
-- ============================================================

CREATE TABLE attendance_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid (),
    class_id UUID NOT NULL,
    subject_id UUID,
    teacher_id UUID,
    attendance_type attendance_type NOT NULL DEFAULT 'CLASS',
    date DATE NOT NULL,
    period INTEGER,
    note TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_attendance_sessions_class FOREIGN KEY (class_id) REFERENCES classes (id) ON DELETE CASCADE,
    CONSTRAINT fk_attendance_sessions_subject FOREIGN KEY (subject_id) REFERENCES subjects (id) ON DELETE SET NULL,
    CONSTRAINT fk_attendance_sessions_teacher FOREIGN KEY (teacher_id) REFERENCES teachers (id) ON DELETE SET NULL,
    CONSTRAINT check_attendance_period CHECK (
        period IS NULL
        OR period > 0
    ),
    CONSTRAINT check_attendance_subject_teacher CHECK (
        (
            attendance_type = 'CLASS'
            AND subject_id IS NULL
        )
        OR (
            attendance_type = 'SUBJECT'
            AND subject_id IS NOT NULL
            AND teacher_id IS NOT NULL
        )
    )
);

CREATE INDEX idx_attendance_sessions_class_date ON attendance_sessions (class_id, date);

CREATE INDEX idx_attendance_sessions_teacher ON attendance_sessions (teacher_id);

CREATE INDEX idx_attendance_sessions_subject ON attendance_sessions (subject_id);

-- ============================================================
-- 13. ATTENDANCE_RECORDS
-- Lưu kết quả điểm danh của từng sinh viên trong một phiên.
-- Mỗi sinh viên chỉ có một kết quả trong một phiên điểm danh.
-- ============================================================

CREATE TABLE attendance_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid (),
    session_id UUID NOT NULL,
    enrollment_id UUID NOT NULL,
    status attendance_status NOT NULL,
    note TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_attendance_records_session FOREIGN KEY (session_id) REFERENCES attendance_sessions (id) ON DELETE CASCADE,
    CONSTRAINT fk_attendance_records_enrollment FOREIGN KEY (enrollment_id) REFERENCES enrollments (id) ON DELETE CASCADE,
    CONSTRAINT uq_attendance_record UNIQUE (session_id, enrollment_id)
);

CREATE INDEX idx_attendance_records_session ON attendance_records (session_id);

CREATE INDEX idx_attendance_records_enrollment ON attendance_records (enrollment_id);

CREATE INDEX idx_attendance_records_status ON attendance_records (status);

-- ============================================================
-- 14. UPDATED_AT FUNCTION & TRIGGERS
-- Tự động cập nhật updated_at mỗi khi bản ghi được chỉnh sửa.
-- ============================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_teachers_updated_at BEFORE UPDATE ON teachers FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_students_updated_at BEFORE UPDATE ON students FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_classes_updated_at BEFORE UPDATE ON classes FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_subjects_updated_at BEFORE UPDATE ON subjects FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_enrollments_updated_at BEFORE UPDATE ON enrollments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_grades_updated_at BEFORE UPDATE ON grades FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
-- ============================================================
-- 15. VIEWS
-- Các VIEW tổng hợp dữ liệu thường dùng để truy vấn nhanh:
-- - v_teachers: thông tin giáo viên + tài khoản.
-- - v_student_classes: sinh viên + lớp đang/đã tham gia.
-- - v_teacher_assignments: giáo viên + lớp + môn được phân công.
-- ============================================================
CREATE VIEW v_teachers AS
SELECT
    t.id AS teacher_id,
    t.teacher_code,
    t.first_name,
    t.last_name,
    t.email,
    t.phone,
    t.status,
    u.id AS user_id,
    u.username,
    u.email AS account_email,
    u.role,
    u.status AS account_status
FROM teachers t
    JOIN users u ON u.id = t.user_id;

CREATE VIEW v_student_classes AS
SELECT
    s.id AS student_id,
    s.student_code,
    s.first_name,
    s.last_name,
    c.id AS class_id,
    c.class_code,
    c.name AS class_name,
    e.academic_year,
    e.status AS enrollment_status
FROM
    students s
    JOIN enrollments e ON e.student_id = s.id
    JOIN classes c ON c.id = e.class_id;

CREATE VIEW v_teacher_assignments AS
SELECT
    ct.id AS assignment_id,
    t.id AS teacher_id,
    t.teacher_code,
    t.first_name AS teacher_first_name,
    t.last_name AS teacher_last_name,
    c.id AS class_id,
    c.class_code,
    c.name AS class_name,
    s.id AS subject_id,
    s.subject_code,
    s.name AS subject_name,
    cs.academic_year,
    cs.semester
FROM
    class_teachers ct
    JOIN teachers t ON t.id = ct.teacher_id
    JOIN class_subjects cs ON cs.id = ct.class_subject_id
    JOIN classes c ON c.id = cs.class_id
    JOIN subjects s ON s.id = cs.subject_id;