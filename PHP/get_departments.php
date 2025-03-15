<?php
/**
 * Üniversiteye Göre Bölüm Listesi API Endpoint'i
 * Seçilen üniversiteye ait bölümleri döndürür
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

$table_name = "social_departments";

// Veritabanı bağlantısı
$conn = new mysqli($server, $username, $password, $db_name);

// Bağlantı hatası kontrolü
if ($conn->connect_error) {
    die(json_encode(["success" => false, "message" => "Veritabanı bağlantısı başarısız: " . $conn->connect_error]));
}

// Üniversite adını al
$university = isset($_GET['university']) ? $_GET['university'] : '';

// Üniversite adı boşsa varsayılan bölüm listesini döndür
if (empty($university)) {
    $departments = [
        "Adalet",
        "Aşçılık",
        "Bankacılık ve Sigortacılık",
        "Bilgisayar Mühendisliği",
        "Bilgisayar Programcılığı",
        "Bilişim Güvenliği Teknolojisi",
        "Çocuk Gelişimi",
        "Dış Ticaret",
        "Dijital Oyun Tasarımı",
        "Ekonomi",
        "Elektrik-Elektronik Mühendisliği",
        "Gastronomi ve Mutfak Sanatları",
        "Grafik Tasarımı",
        "Hukuk",
        "İşletme",
        "Makine Mühendisliği",
        "Mimarlık",
        "Psikoloji",
        "Yazılım Mühendisliği",
        "Yönetim Bilişim Sistemleri"
    ];
    
    echo json_encode(["success" => true, "data" => $departments]);
    $conn->close();
    exit;
}

// Log için üniversite adını kaydet
error_log("Requesting departments for university: " . $university);

try {
    // Üniversiteye göre bölümleri sorgula
    $sql = "SELECT department_name FROM $table_name WHERE university_name = ? ORDER BY department_name ASC";
    $stmt = $conn->prepare($sql);

    if ($stmt === false) {
        throw new Exception("SQL sorgu hazırlama hatası: " . $conn->error);
    }

    $stmt->bind_param("s", $university);
    $stmt->execute();
    $result = $stmt->get_result();

    $departments = [];

    if ($result->num_rows > 0) {
        while ($row = $result->fetch_assoc()) {
            $departments[] = $row['department_name'];
        }
    }

    // Eğer veritabanında bölüm bulunamazsa varsayılan bölüm listesini kullan
    if (empty($departments)) {
        $departments = [
            "Adalet",
            "Aşçılık",
            "Bankacılık ve Sigortacılık",
            "Bilgisayar Mühendisliği",
            "Bilgisayar Programcılığı",
            "Bilişim Güvenliği Teknolojisi",
            "Çocuk Gelişimi",
            "Dış Ticaret",
            "Dijital Oyun Tasarımı",
            "Ekonomi",
            "Elektrik-Elektronik Mühendisliği",
            "Gastronomi ve Mutfak Sanatları",
            "Grafik Tasarımı",
            "Hukuk",
            "İşletme",
            "Makine Mühendisliği",
            "Mimarlık",
            "Psikoloji",
            "Yazılım Mühendisliği",
            "Yönetim Bilişim Sistemleri"
        ];
    }

    echo json_encode(["success" => true, "data" => $departments]);
    $stmt->close();
} catch (Exception $e) {
    error_log("Error in get_departments.php: " . $e->getMessage());
    echo json_encode(["success" => false, "message" => $e->getMessage(), "data" => [
        "Adalet",
        "Aşçılık",
        "Bankacılık ve Sigortacılık",
        "Bilgisayar Mühendisliği",
        "Bilgisayar Programcılığı",
        "Bilişim Güvenliği Teknolojisi",
        "Çocuk Gelişimi",
        "Dış Ticaret",
        "Dijital Oyun Tasarımı",
        "Ekonomi",
        "Elektrik-Elektronik Mühendisliği",
        "Gastronomi ve Mutfak Sanatları",
        "Grafik Tasarımı",
        "Hukuk",
        "İşletme",
        "Makine Mühendisliği",
        "Mimarlık",
        "Psikoloji",
        "Yazılım Mühendisliği",
        "Yönetim Bilişim Sistemleri"
    ]]);
}

$conn->close();
?> 