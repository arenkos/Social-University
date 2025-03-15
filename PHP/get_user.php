<?php
/**
 * Kullanıcı Bilgilerini Sorgulama API Endpoint'i
 * Kullanıcı ID'sine göre bilgileri sorgular
 */

// Config dosyasını dahil et
require_once 'config.php';

// Sadece GET isteklerine izin ver
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    sendResponse(false, 'Sadece GET istekleri kabul edilir', null, 405);
}

// API isteğini doğrula
if (!validateAPIRequest()) {
    sendResponse(false, 'Yetkisiz erişim', null, 401);
}

// URL'den kullanıcı ID'sini al
$requestUri = $_SERVER['REQUEST_URI'];
$uriSegments = explode('/', parse_url($requestUri, PHP_URL_PATH));
$userId = end($uriSegments);

if (empty($userId)) {
    sendResponse(false, 'Kullanıcı ID bulunamadı', null, 400);
}

// Veritabanı bağlantısı
$conn = getDBConnection();

// Kullanıcı bilgilerini sorgula
$sql = "SELECT * FROM social_students WHERE id = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("s", $userId);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 0) {
    // Kullanıcı bulunamadı
    sendResponse(false, 'Kullanıcı bulunamadı', null, 404);
}

// Kullanıcı bilgilerini al
$user = $result->fetch_assoc();

// Kullanıcı bilgilerini hazırla
$userData = [
    'id' => $user['id'],
    'email' => $user['mail'],
    'name' => $user['name_surname'],
    'studentNumber' => $user['student_number'],
    'department' => $user['department'],
    'university' => $user['university']
];

// Başarılı yanıt gönder
sendResponse(true, 'Kullanıcı bilgileri bulundu', $userData);

// Bağlantıyı kapat
$conn->close();
?> 
