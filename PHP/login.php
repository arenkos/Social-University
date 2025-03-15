<?php

// Veritabanı bağlantı bilgileri
$db_name = "u162605596_dogus";
$username = "u162605596_dogus";
$password = "Arenkos1.";
$server = "127.0.0.1:3306";

$table_name = "social_students";

// Veritabanı bağlantısı
$conn = new mysqli($server, $username, $password, $db_name);

// Bağlantı hatası kontrolü
if ($conn->connect_error) {
    die(json_encode(["success" => false, "message" => "Veritabanı bağlantısı başarısız: " . $conn->connect_error]));
}

// JSON verisini al
$data = json_decode(file_get_contents('php://input'), true);

if ($data === null) {
    die(json_encode(["success" => false, "message" => "JSON verisi okunamadı veya geçersiz"]));
}

$email = $data['email'] ?? '';
$password = $data['password'] ?? '';

// Kullanıcıyı kontrol et
$sql = "SELECT * FROM $table_name WHERE mail = ? AND password = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("ss", $email, $password);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows > 0) {
    $user = $result->fetch_assoc();
    
    // E-posta onayını kontrol et
    $sql2 = "SELECT * FROM $table_name WHERE mail = ? AND password = ? AND onay = 1";
    $stmt2 = $conn->prepare($sql2);
    $stmt2->bind_param("ss", $email, $password);
    $stmt2->execute();
    $result2 = $stmt2->get_result();
    date_default_timezone_set("Europe/Istanbul");
    $date = date("Y-m-d H:i:s");
    
    if ($result2->num_rows > 0) {
        $sql3 = "UPDATE $table_name SET updated_at = ? WHERE mail = ? AND password = ? AND onay = 1";
        $stmt3 = $conn->prepare($sql3);
        $stmt3->bind_param("sss", $date, $email, $password);
        $stmt3->execute();
        echo json_encode(["success" => true, "data" => $user]);
    } else {
        echo json_encode(["success" => false, "message" => "E-posta onayı olmadan giriş yapılamaz"]);
    }
    $stmt2->close();
} else {
    echo json_encode(["success" => false, "message" => "E-posta veya şifre hatalı"]);
}

$stmt->close();
$conn->close();

?>
