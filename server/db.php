<?php
/**
 * Veritabanı Bağlantı Bilgileri
 * Social University uygulaması için veritabanı bağlantı ayarları
 */

// Veritabanı bağlantı bilgileri
$host = 'localhost';
$dbname = 'social_university';
$username = 'root';
$password = '';
$charset = 'utf8mb4';

// DSN (Data Source Name) oluştur
$dsn = "mysql:host=$host;dbname=$dbname;charset=$charset";

// PDO seçenekleri
$options = [
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    PDO::ATTR_EMULATE_PREPARES => false,
];

// PDO bağlantısını oluştur
try {
    $pdo = new PDO($dsn, $username, $password, $options);
} catch (PDOException $e) {
    // Hata durumunda JSON formatında hata mesajı döndür
    header('Content-Type: application/json');
    echo json_encode([
        'status' => false,
        'message' => 'Veritabanı bağlantı hatası: ' . $e->getMessage()
    ]);
    exit;
}

/**
 * JSON yanıt döndürme fonksiyonu
 * 
 * @param bool $status Başarı durumu
 * @param string $message Mesaj
 * @param array $data Veri
 * @return void
 */
function sendResponse($status, $message, $data = []) {
    echo json_encode([
        'status' => $status,
        'message' => $message,
        'data' => $data
    ]);
    exit;
} 