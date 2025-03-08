<?php
/**
 * Mesajlar API
 * Ders mesajlarını listeler ve yeni mesaj gönderir
 */

// Veritabanı bağlantısını dahil et
require_once 'db.php';

// CORS ayarları
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");
header("Content-Type: application/json; charset=UTF-8");

// İstek metoduna göre işlem yap
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    // Mesajları listele
    getMessages();
} elseif ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Yeni mesaj gönder
    sendMessage();
} else {
    sendResponse(false, 'Sadece GET ve POST istekleri kabul edilir');
}

/**
 * Ders mesajlarını listeler
 */
function getMessages() {
    global $pdo;
    
    // Gerekli parametreleri kontrol et
    if (!isset($_GET['course_code']) || empty($_GET['course_code'])) {
        sendResponse(false, 'Ders kodu gereklidir');
    }
    
    $courseCode = $_GET['course_code'];
    
    try {
        // Dersi bul
        $courseStmt = $pdo->prepare("SELECT * FROM courses WHERE course_code = ?");
        $courseStmt->execute([$courseCode]);
        $course = $courseStmt->fetch();
        
        if (!$course) {
            sendResponse(false, 'Ders bulunamadı');
        }
        
        // Mesajları al
        $stmt = $pdo->prepare("
            SELECT m.*, s.student_id 
            FROM messages m
            LEFT JOIN students s ON m.student_id = s.student_id
            WHERE m.course_code = ?
            ORDER BY m.timestamp ASC
        ");
        $stmt->execute([$courseCode]);
        $messages = $stmt->fetchAll();
        
        // Mesajları formatla
        $formattedMessages = [];
        foreach ($messages as $message) {
            $formattedMessages[] = [
                'id' => $message['id'],
                'message' => $message['message'],
                'timestamp' => $message['timestamp'],
                'course_code' => $message['course_code'],
                'student_id' => $message['student_id']
            ];
        }
        
        // Başarılı yanıt döndür
        sendResponse(true, 'Mesajlar başarıyla alındı', [
            'messages' => $formattedMessages
        ]);
        
    } catch (PDOException $e) {
        // Hata durumunda
        sendResponse(false, 'Mesajlar alınırken hata oluştu: ' . $e->getMessage());
    }
}

/**
 * Yeni mesaj gönderir
 */
function sendMessage() {
    global $pdo;
    
    // JSON verisini al
    $data = json_decode(file_get_contents("php://input"), true);
    
    // Gerekli alanları kontrol et
    if (!isset($data['course_code']) || empty($data['course_code'])) {
        sendResponse(false, 'Ders kodu gereklidir');
    }
    
    if (!isset($data['message']) || empty($data['message'])) {
        sendResponse(false, 'Mesaj içeriği gereklidir');
    }
    
    $courseCode = $data['course_code'];
    $message = $data['message'];
    $studentId = isset($data['student_id']) ? $data['student_id'] : null;
    
    try {
        // Dersi bul
        $courseStmt = $pdo->prepare("SELECT * FROM courses WHERE course_code = ?");
        $courseStmt->execute([$courseCode]);
        $course = $courseStmt->fetch();
        
        if (!$course) {
            sendResponse(false, 'Ders bulunamadı');
        }
        
        // Öğrenci ID'si belirtilmişse, öğrencinin derse kayıtlı olup olmadığını kontrol et
        if ($studentId) {
            $registeredStudents = $course['course_registered_students'] ? explode(',', $course['course_registered_students']) : [];
            if (!in_array($studentId, $registeredStudents)) {
                sendResponse(false, 'Bu derse kayıtlı değilsiniz');
            }
        }
        
        // Yeni mesaj oluştur
        $id = uniqid();
        $timestamp = date('Y-m-d H:i:s');
        
        $stmt = $pdo->prepare("
            INSERT INTO messages (id, message, timestamp, course_code, student_id) 
            VALUES (?, ?, ?, ?, ?)
        ");
        $stmt->execute([$id, $message, $timestamp, $courseCode, $studentId]);
        
        // Yeni mesajı al
        $messageStmt = $pdo->prepare("
            SELECT m.*, s.student_id 
            FROM messages m
            LEFT JOIN students s ON m.student_id = s.student_id
            WHERE m.id = ?
        ");
        $messageStmt->execute([$id]);
        $newMessage = $messageStmt->fetch();
        
        // Mesajı formatla
        $formattedMessage = [
            'id' => $newMessage['id'],
            'message' => $newMessage['message'],
            'timestamp' => $newMessage['timestamp'],
            'course_code' => $newMessage['course_code'],
            'student_id' => $newMessage['student_id']
        ];
        
        // Başarılı yanıt döndür
        sendResponse(true, 'Mesaj başarıyla gönderildi', [
            'message' => $formattedMessage
        ]);
        
    } catch (PDOException $e) {
        // Hata durumunda
        sendResponse(false, 'Mesaj gönderilirken hata oluştu: ' . $e->getMessage());
    }
} 