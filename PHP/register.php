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
$name_surname = $data['name_surname'] ?? '';
$student_number = $data['student_number'] ?? '';
$phone_number = $data['phone_number'] ?? '';
date_default_timezone_set("Europe/Istanbul");
$date = date("Y-m-d H:i:s");

// Kullanıcıyı ekle
$sql = "INSERT INTO $table_name (date, mail, password, name_surname, student_number, phone) VALUES (?, ?, ?, ?, ?, ?)";
$stmt = $conn->prepare($sql);
$stmt->bind_param("ssssss", $date, $email, $password, $name_surname, $student_number, $phone_number);

if ($stmt->execute()) {
    echo json_encode(["success" => true, "message" => "Kayıt başarılı"]);
} else {
    echo json_encode(["success" => false, "message" => "Kayıt başarısız: " . $stmt->error]);
}

$stmt->close();
$conn->close();

?>
