<?php
/**
 * Kullanıcı Bilgilerini Güncelleme API Endpoint'i
 * Kullanıcı ID'sine göre üniversite ve bölüm bilgilerini günceller
 */

// Önce header'ları ayarla
header('Content-Type: application/json; charset=utf-8');

// Config dosyasını dahil etmeyi dene, yoksa devam et
@include_once 'config.php';

// Veritabanı bağlantı bilgileri
$db_name = "u162605596_dogus";
$username = "u162605596_dogus";
$password = "Arenkos1.";
$server = "127.0.0.1:3306";

$table_name = "social_students";

try {
    // Veritabanı bağlantısı
    $conn = new mysqli($server, $username, $password, $db_name);

    // Bağlantı hatası kontrolü
    if ($conn->connect_error) {
        throw new Exception("Veritabanı bağlantısı başarısız: " . $conn->connect_error);
    }

    // JSON verisini al
    $input = file_get_contents('php://input');
    $data = json_decode($input, true);

    if ($data === null) {
        $json_error = json_last_error_msg();
        throw new Exception("JSON verisi okunamadı veya geçersiz: $json_error. Alınan veri: $input");
    }

    // Gerekli alanları kontrol et
    $userId = $data['user_id'] ?? '';

    if (empty($userId)) {
        throw new Exception("Kullanıcı ID'si gerekli");
    }

    // Güncellenecek alanları hazırla
    $updateFields = [];
    $bindParams = [];
    $bindTypes = '';

    // Üniversite bilgisi varsa güncelle
    if (isset($data['university'])) {
        $updateFields[] = "university = ?";
        $bindParams[] = $data['university'];
        $bindTypes .= 's';
    }

    // Bölüm bilgisi varsa güncelle
    if (isset($data['department'])) {
        $updateFields[] = "department = ?";
        $bindParams[] = $data['department'];
        $bindTypes .= 's';
    }

    // Güncelleme tarihi
    date_default_timezone_set("Europe/Istanbul");
    $updateDate = date("Y-m-d H:i:s");
    $updateFields[] = "updated_at = ?";
    $bindParams[] = $updateDate;
    $bindTypes .= 's';

    // Güncellenecek alan yoksa hata döndür
    if (empty($updateFields)) {
        throw new Exception("Güncellenecek alan belirtilmedi");
    }

    // SQL sorgusunu hazırla
    $sql = "UPDATE $table_name SET " . implode(", ", $updateFields) . " WHERE id = ?";
    $bindParams[] = $userId;
    $bindTypes .= 's';

    $stmt = $conn->prepare($sql);

    if ($stmt === false) {
        throw new Exception("SQL sorgu hazırlama hatası: " . $conn->error);
    }

    // Parametreleri bind et
    $stmt->bind_param($bindTypes, ...$bindParams);

    // Sorguyu çalıştır
    if ($stmt->execute()) {
        // Etkilenen satır sayısını kontrol et
        if ($stmt->affected_rows > 0) {
            echo json_encode(["success" => true, "message" => "Kullanıcı bilgileri başarıyla güncellendi"]);
        } else {
            echo json_encode(["success" => true, "message" => "Kullanıcı bulunamadı veya bilgiler zaten güncel"]);
        }
    } else {
        throw new Exception("Kullanıcı bilgileri güncellenirken hata oluştu: " . $stmt->error);
    }

    $stmt->close();
    $conn->close();
    
} catch (Exception $e) {
    error_log("Error in update_user.php: " . $e->getMessage());
    echo json_encode(["success" => false, "message" => $e->getMessage()]);
    
    if (isset($conn) && $conn instanceof mysqli) {
        $conn->close();
    }
}
?> 