<?php
/**
 * Login API
 * Microsoft API ile giriş işlemi
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
if (!isset($data['email']) || empty($data['email'])) {
    sendResponse(false, 'E-posta adresi gereklidir');
}

$email = filter_var($data['email'], FILTER_SANITIZE_EMAIL);

// E-posta formatı kontrolü
if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    sendResponse(false, 'Geçersiz e-posta formatı');
}

// Üniversite e-posta kontrolü (örnek: university.edu.tr)
$domain = substr(strrchr($email, "@"), 1);
if (strpos($domain, 'university.edu') === false) {
    sendResponse(false, 'Sadece üniversite e-posta adresleri kabul edilir');
}

// E-posta adresinden bilgileri çıkar
$username = explode('@', $email)[0];
$studentNumber = preg_replace('/[^0-9]/', '', $username);

// Microsoft API ile doğrulama burada yapılacak
// Bu örnek için basitleştirilmiş bir simülasyon yapıyoruz

// Kullanıcı veritabanında var mı kontrol et
$stmt = $pdo->prepare('SELECT * FROM users WHERE email = ?');
$stmt->execute([$email]);
$user = $stmt->fetch();

if (!$user) {
    // Yeni kullanıcı oluştur
    $id = bin2hex(random_bytes(16)); // UUID oluştur
    
    // Örnek olarak, kullanıcı adını parçalara ayırıyoruz
    // Gerçek uygulamada Microsoft API'den alınacak
    $name = 'Örnek';
    $surname = 'Öğrenci';
    $department = 'Bilgisayar Mühendisliği';
    
    $stmt = $pdo->prepare('INSERT INTO users (id, email, name, surname, student_number, department) VALUES (?, ?, ?, ?, ?, ?)');
    $stmt->execute([$id, $email, $name, $surname, $studentNumber, $department]);
    
    // Yeni oluşturulan kullanıcıyı al
    $stmt = $pdo->prepare('SELECT * FROM users WHERE id = ?');
    $stmt->execute([$id]);
    $user = $stmt->fetch();
}

// Kullanıcı bilgilerini döndür
sendResponse(true, 'Giriş başarılı', [
    'user' => [
        'id' => $user['id'],
        'email' => $user['email'],
        'name' => $user['name'],
        'surname' => $user['surname'],
        'studentNumber' => $user['student_number'],
        'department' => $user['department']
    ]
]); 