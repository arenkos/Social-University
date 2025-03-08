-- Social University Veritabanı Şeması

-- Veritabanını oluştur
CREATE DATABASE IF NOT EXISTS social_university CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE social_university;

-- Kullanıcılar tablosu
CREATE TABLE IF NOT EXISTS users (
    id VARCHAR(36) PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    surname VARCHAR(100) NOT NULL,
    student_number VARCHAR(50) NOT NULL,
    department VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Dersler tablosu
CREATE TABLE IF NOT EXISTS courses (
    id VARCHAR(36) PRIMARY KEY,
    course_code VARCHAR(20) NOT NULL,
    course_name VARCHAR(255) NOT NULL,
    department_name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Kullanıcı-Ders ilişki tablosu
CREATE TABLE IF NOT EXISTS user_courses (
    user_id VARCHAR(36) NOT NULL,
    course_id VARCHAR(36) NOT NULL,
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, course_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Mesajlar tablosu
CREATE TABLE IF NOT EXISTS messages (
    id VARCHAR(36) PRIMARY KEY,
    content TEXT NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    sender_id VARCHAR(36),
    course_id VARCHAR(36) NOT NULL,
    FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Örnek dersler
INSERT INTO courses (id, course_code, course_name, department_name) VALUES
(UUID(), 'BIL101', 'Bilgisayar Programlama', 'Bilgisayar Mühendisliği'),
(UUID(), 'BIL203', 'Veri Yapıları', 'Bilgisayar Mühendisliği'),
(UUID(), 'MAT101', 'Kalkülüs I', 'Matematik'),
(UUID(), 'FIZ101', 'Fizik I', 'Fizik'),
(UUID(), 'ENG101', 'İngilizce I', 'Yabancı Diller'); 