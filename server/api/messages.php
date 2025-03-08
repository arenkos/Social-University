<?php
/**
 * Messages API
 * Mesajları listeler ve yeni mesaj gönderir
 */

require_once '../config.php';
header('Content-Type: application/json');

// İstek türüne göre işlem yap
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
 * Mesajları listeler
 */
function getMessages() {
    global $pdo;
    
    // Gerekli parametreleri kontrol et
    if (!isset($_GET['course_id']) || empty($_GET['course_id'])) {
        sendResponse(false, 'Ders ID gereklidir');
    }
    
    $courseId = $_GET['course_id'];
    $lastId = isset($_GET['last_id']) ? $_GET['last_id'] : null;
    
    // Dersin varlığını kontrol et
    $courseStmt = $pdo->prepare('SELECT * FROM courses WHERE id = ?');
    $courseStmt->execute([$courseId]);
    $course = $courseStmt->fetch();
    
    if (!$course) {
        sendResponse(false, 'Ders bulunamadı');
    }
    
    // Mesajları sorgula
    $query = 'SELECT m.*, u.name, u.surname, u.student_number 
              FROM messages m 
              LEFT JOIN users u ON m.sender_id = u.id 
              WHERE m.course_id = ?';
    $params = [$courseId];
    
    // Son mesaj ID'sinden sonraki mesajları al
    if ($lastId) {
        $query .= ' AND m.id > ?';
        $params[] = $lastId;
    }
    
    $query .= ' ORDER BY m.timestamp ASC';
    
    $stmt = $pdo->prepare($query);
    $stmt->execute($params);
    $messages = $stmt->fetchAll();
    
    // Mesajları formatla
    $formattedMessages = [];
    foreach ($messages as $message) {
        $formattedMessages[] = [
            'id' => $message['id'],
            'content' => $message['content'],
            'timestamp' => $message['timestamp'],
            'sender' => $message['sender_id'] ? [
                'id' => $message['sender_id'],
                'name' => $message['name'],
                'surname' => $message['surname'],
                'studentNumber' => $message['student_number']
            ] : null,
            'course_id' => $message['course_id']
        ];
    }
    
    sendResponse(true, 'Mesajlar başarıyla alındı', [
        'messages' => $formattedMessages
    ]);
}

/**
 * Yeni mesaj gönderir
 */
function sendMessage() {
    global $pdo;
    
    // Gelen verileri al
    $data = json_decode(file_get_contents('php://input'), true);
    
    // Gerekli alanların kontrolü
    if (!isset($data['course_id']) || empty($data['course_id'])) {
        sendResponse(false, 'Ders ID gereklidir');
    }
    
    if (!isset($data['content']) || empty($data['content'])) {
        sendResponse(false, 'Mesaj içeriği gereklidir');
    }
    
    $courseId = $data['course_id'];
    $content = $data['content'];
    $senderId = isset($data['sender_id']) ? $data['sender_id'] : null;
    
    // Dersin varlığını kontrol et
    $courseStmt = $pdo->prepare('SELECT * FROM courses WHERE id = ?');
    $courseStmt->execute([$courseId]);
    $course = $courseStmt->fetch();
    
    if (!$course) {
        sendResponse(false, 'Ders bulunamadı');
    }
    
    // Gönderen kullanıcının varlığını kontrol et (eğer belirtilmişse)
    if ($senderId) {
        $userStmt = $pdo->prepare('SELECT * FROM users WHERE id = ?');
        $userStmt->execute([$senderId]);
        $user = $userStmt->fetch();
        
        if (!$user) {
            sendResponse(false, 'Kullanıcı bulunamadı');
        }
        
        // Kullanıcının derse kayıtlı olup olmadığını kontrol et
        $enrollStmt = $pdo->prepare('SELECT * FROM user_courses WHERE user_id = ? AND course_id = ?');
        $enrollStmt->execute([$senderId, $courseId]);
        $isEnrolled = $enrollStmt->fetch() ? true : false;
        
        if (!$isEnrolled) {
            sendResponse(false, 'Kullanıcı bu derse kayıtlı değil');
        }
    }
    
    // Yeni mesaj oluştur
    $id = bin2hex(random_bytes(16)); // UUID oluştur
    $timestamp = date('Y-m-d H:i:s');
    
    $stmt = $pdo->prepare('INSERT INTO messages (id, content, timestamp, sender_id, course_id) VALUES (?, ?, ?, ?, ?)');
    $stmt->execute([$id, $content, $timestamp, $senderId, $courseId]);
    
    // Yeni mesajı al
    $messageStmt = $pdo->prepare('SELECT m.*, u.name, u.surname, u.student_number 
                                 FROM messages m 
                                 LEFT JOIN users u ON m.sender_id = u.id 
                                 WHERE m.id = ?');
    $messageStmt->execute([$id]);
    $message = $messageStmt->fetch();
    
    // Mesajı formatla
    $formattedMessage = [
        'id' => $message['id'],
        'content' => $message['content'],
        'timestamp' => $message['timestamp'],
        'sender' => $message['sender_id'] ? [
            'id' => $message['sender_id'],
            'name' => $message['name'],
            'surname' => $message['surname'],
            'studentNumber' => $message['student_number']
        ] : null,
        'course_id' => $message['course_id']
    ];
    
    sendResponse(true, 'Mesaj başarıyla gönderildi', [
        'message' => $formattedMessage
    ]);
} 