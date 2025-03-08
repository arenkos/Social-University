<?php
/**
 * Enroll API
 * Derse katılma ve ayrılma işlemleri
 */

require_once '../config.php';
header('Content-Type: application/json');

// POST isteği kontrolü
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendResponse(false, 'Sadece POST istekleri kabul edilir');
}

// Gelen verileri al
$data = json_decode(file_get_contents('php://input'), true);

// Gerekli alanların kontrolü
if (!isset($data['user_id']) || empty($data['user_id'])) {
    sendResponse(false, 'Kullanıcı ID gereklidir');
}

if (!isset($data['course_id']) || empty($data['course_id'])) {
    sendResponse(false, 'Ders ID gereklidir');
}

if (!isset($data['action']) || empty($data['action'])) {
    sendResponse(false, 'İşlem türü gereklidir (enroll/unenroll)');
}

$userId = $data['user_id'];
$courseId = $data['course_id'];
$action = $data['action'];

// Kullanıcı ve dersin varlığını kontrol et
$userStmt = $pdo->prepare('SELECT * FROM users WHERE id = ?');
$userStmt->execute([$userId]);
$user = $userStmt->fetch();

if (!$user) {
    sendResponse(false, 'Kullanıcı bulunamadı');
}

$courseStmt = $pdo->prepare('SELECT * FROM courses WHERE id = ?');
$courseStmt->execute([$courseId]);
$course = $courseStmt->fetch();

if (!$course) {
    sendResponse(false, 'Ders bulunamadı');
}

// Kayıt durumunu kontrol et
$enrollStmt = $pdo->prepare('SELECT * FROM user_courses WHERE user_id = ? AND course_id = ?');
$enrollStmt->execute([$userId, $courseId]);
$isEnrolled = $enrollStmt->fetch() ? true : false;

// İşlemi gerçekleştir
if ($action === 'enroll') {
    if ($isEnrolled) {
        sendResponse(false, 'Kullanıcı zaten bu derse kayıtlı');
    }
    
    $stmt = $pdo->prepare('INSERT INTO user_courses (user_id, course_id) VALUES (?, ?)');
    $stmt->execute([$userId, $courseId]);
    
    sendResponse(true, 'Derse başarıyla kaydoldunuz');
} elseif ($action === 'unenroll') {
    if (!$isEnrolled) {
        sendResponse(false, 'Kullanıcı bu derse kayıtlı değil');
    }
    
    $stmt = $pdo->prepare('DELETE FROM user_courses WHERE user_id = ? AND course_id = ?');
    $stmt->execute([$userId, $courseId]);
    
    sendResponse(true, 'Dersten başarıyla ayrıldınız');
} else {
    sendResponse(false, 'Geçersiz işlem türü. Sadece "enroll" veya "unenroll" kabul edilir');
} 