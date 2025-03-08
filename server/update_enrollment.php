<?php
/**
 * Ders Kayıt Güncelleme API
 * Öğrencinin derse katılma veya dersten ayrılma işlemlerini gerçekleştirir
 */

// Veritabanı bağlantısını dahil et
require_once 'db.php';

// CORS ayarları
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");
header("Content-Type: application/json; charset=UTF-8");

// Sadece POST isteklerini kabul et
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendResponse(false, 'Sadece POST istekleri kabul edilir');
}

// JSON verisini al
$data = json_decode(file_get_contents("php://input"), true);

// Gerekli alanları kontrol et
if (!isset($data['student_id']) || empty($data['student_id'])) {
    sendResponse(false, 'Öğrenci numarası gereklidir');
}

if (!isset($data['course_code']) || empty($data['course_code'])) {
    sendResponse(false, 'Ders kodu gereklidir');
}

if (!isset($data['action']) || empty($data['action']) || !in_array($data['action'], ['enroll', 'unenroll'])) {
    sendResponse(false, 'Geçerli bir işlem belirtilmelidir (enroll/unenroll)');
}

$studentId = $data['student_id'];
$courseCode = $data['course_code'];
$action = $data['action'];

try {
    // Dersi bul
    $stmt = $pdo->prepare("SELECT * FROM courses WHERE course_code = ?");
    $stmt->execute([$courseCode]);
    $course = $stmt->fetch();
    
    if (!$course) {
        sendResponse(false, 'Ders bulunamadı');
    }
    
    // Mevcut kayıtlı öğrencileri al
    $registeredStudents = $course['course_registered_students'] ? explode(',', $course['course_registered_students']) : [];
    
    // Öğrencinin kayıt durumunu kontrol et
    $isEnrolled = in_array($studentId, $registeredStudents);
    
    // Katılma işlemi
    if ($action === 'enroll') {
        if ($isEnrolled) {
            sendResponse(false, 'Öğrenci zaten bu derse kayıtlı');
        }
        
        // Öğrenciyi ekle
        $registeredStudents[] = $studentId;
    } 
    // Ayrılma işlemi
    else if ($action === 'unenroll') {
        if (!$isEnrolled) {
            sendResponse(false, 'Öğrenci bu derse kayıtlı değil');
        }
        
        // Öğrenciyi çıkar
        $registeredStudents = array_diff($registeredStudents, [$studentId]);
    }
    
    // Yeni öğrenci listesini oluştur
    $newRegisteredStudents = implode(',', $registeredStudents);
    
    // Dersi güncelle
    $updateStmt = $pdo->prepare("UPDATE courses SET course_registered_students = ? WHERE course_code = ?");
    $updateStmt->execute([$newRegisteredStudents, $courseCode]);
    
    // Başarılı yanıt döndür
    $message = $action === 'enroll' ? 'Derse başarıyla katıldınız' : 'Dersten başarıyla ayrıldınız';
    sendResponse(true, $message, [
        'course_code' => $courseCode,
        'is_enrolled' => $action === 'enroll',
        'student_count' => count($registeredStudents)
    ]);
    
} catch (PDOException $e) {
    // Hata durumunda
    sendResponse(false, 'İşlem sırasında hata oluştu: ' . $e->getMessage());
} 