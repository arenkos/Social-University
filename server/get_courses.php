<?php
/**
 * Dersleri Listele API
 * Tüm dersleri veya belirli bir bölüme ait dersleri listeler
 */

// Veritabanı bağlantısını dahil et
require_once 'db.php';

// CORS ayarları
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");
header("Content-Type: application/json; charset=UTF-8");

// Sadece GET isteklerini kabul et
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    sendResponse(false, 'Sadece GET istekleri kabul edilir');
}

// İsteğe bağlı parametreler
$department = isset($_GET['department']) ? $_GET['department'] : null;
$search = isset($_GET['search']) ? $_GET['search'] : null;
$studentId = isset($_GET['student_id']) ? $_GET['student_id'] : null;

try {
    // Temel sorgu
    $query = "SELECT * FROM courses";
    $params = [];
    $whereAdded = false;
    
    // Bölüm filtresi
    if ($department) {
        $query .= " WHERE course_department = ?";
        $params[] = $department;
        $whereAdded = true;
    }
    
    // Arama filtresi
    if ($search) {
        if ($whereAdded) {
            $query .= " AND (course_code LIKE ? OR course_name LIKE ?)";
        } else {
            $query .= " WHERE (course_code LIKE ? OR course_name LIKE ?)";
            $whereAdded = true;
        }
        $searchParam = "%$search%";
        $params[] = $searchParam;
        $params[] = $searchParam;
    }
    
    // Sıralama
    $query .= " ORDER BY course_department, course_code";
    
    // Sorguyu çalıştır
    $stmt = $pdo->prepare($query);
    $stmt->execute($params);
    $courses = $stmt->fetchAll();
    
    // Bölümleri al - course_department sütunundan benzersiz değerleri çek
    $deptStmt = $pdo->query("SELECT DISTINCT course_department FROM courses ORDER BY course_department");
    $departments = $deptStmt->fetchAll(PDO::FETCH_COLUMN);
    
    // Öğrencinin kayıtlı olduğu dersleri al (eğer öğrenci ID belirtilmişse)
    $enrolledCourses = [];
    if ($studentId) {
        $enrollStmt = $pdo->prepare("SELECT course_code FROM courses WHERE FIND_IN_SET(?, course_registered_students)");
        $enrollStmt->execute([$studentId]);
        $enrolledCourses = $enrollStmt->fetchAll(PDO::FETCH_COLUMN);
    }
    
    // Dersleri formatla
    $formattedCourses = [];
    foreach ($courses as $course) {
        // Kayıtlı öğrenci sayısını hesapla
        $registeredStudents = $course['course_registered_students'] ? explode(',', $course['course_registered_students']) : [];
        $studentCount = count($registeredStudents);
        
        // Öğrencinin bu derse kayıtlı olup olmadığını kontrol et
        $isEnrolled = $studentId && in_array($studentId, $registeredStudents);
        
        $formattedCourses[] = [
            'course_code' => $course['course_code'],
            'course_name' => $course['course_name'],
            'course_department' => $course['course_department'],
            'student_count' => $studentCount,
            'is_enrolled' => $isEnrolled
        ];
    }
    
    // Başarılı yanıt döndür
    sendResponse(true, 'Dersler başarıyla alındı', [
        'courses' => $formattedCourses,
        'departments' => $departments
    ]);
    
} catch (PDOException $e) {
    // Hata durumunda
    sendResponse(false, 'Dersler alınırken hata oluştu: ' . $e->getMessage());
} 