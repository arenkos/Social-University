<?php
/**
 * Courses API
 * Dersleri listeler ve filtreleme yapar
 */

require_once '../config.php';
header('Content-Type: application/json');

// GET isteği kontrolü
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    sendResponse(false, 'Sadece GET istekleri kabul edilir');
}

// Filtreleme parametreleri
$search = isset($_GET['search']) ? $_GET['search'] : '';
$department = isset($_GET['department']) ? $_GET['department'] : '';
$userId = isset($_GET['user_id']) ? $_GET['user_id'] : '';

// Temel sorgu
$query = 'SELECT c.* FROM courses c';
$params = [];

// Kullanıcının kayıtlı olduğu dersleri işaretlemek için JOIN
if (!empty($userId)) {
    $query .= ' LEFT JOIN user_courses uc ON c.id = uc.course_id AND uc.user_id = ?';
    $params[] = $userId;
}

// WHERE koşulları
$whereConditions = [];

// Arama filtresi
if (!empty($search)) {
    $whereConditions[] = '(c.course_name LIKE ? OR c.course_code LIKE ?)';
    $params[] = "%$search%";
    $params[] = "%$search%";
}

// Bölüm filtresi
if (!empty($department)) {
    $whereConditions[] = 'c.department_name = ?';
    $params[] = $department;
}

// WHERE koşullarını ekle
if (!empty($whereConditions)) {
    $query .= ' WHERE ' . implode(' AND ', $whereConditions);
}

// Sıralama
$query .= ' ORDER BY c.course_code ASC';

// Sorguyu çalıştır
$stmt = $pdo->prepare($query);
$stmt->execute($params);
$courses = $stmt->fetchAll();

// Kullanıcının kayıtlı olduğu dersleri işaretle
if (!empty($userId)) {
    $enrolledStmt = $pdo->prepare('SELECT course_id FROM user_courses WHERE user_id = ?');
    $enrolledStmt->execute([$userId]);
    $enrolledCourses = $enrolledStmt->fetchAll(PDO::FETCH_COLUMN);
    
    foreach ($courses as &$course) {
        $course['is_enrolled'] = in_array($course['id'], $enrolledCourses);
    }
}

// Bölümleri al (filtreleme için)
$deptStmt = $pdo->query('SELECT DISTINCT department_name FROM courses ORDER BY department_name');
$departments = $deptStmt->fetchAll(PDO::FETCH_COLUMN);

// Sonuçları döndür
sendResponse(true, 'Dersler başarıyla alındı', [
    'courses' => $courses,
    'departments' => $departments
]); 