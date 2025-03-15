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

if (empty($email)) {
    die(json_encode(["success" => false, "message" => "E-posta adresi gerekli"]));
}

// Kullanıcıyı kontrol et
$sql = "SELECT * FROM $table_name WHERE mail = ? AND onay = 1";
$stmt = $conn->prepare($sql);
$stmt->bind_param("s", $email);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows > 0) {
    $user = $result->fetch_assoc();
    date_default_timezone_set("Europe/Istanbul");
    $date = date("Y-m-d H:i:s");
    
    // Son giriş zamanını güncelle
    $sql2 = "UPDATE $table_name SET updated_at = ? WHERE mail = ? AND onay = 1";
    $stmt2 = $conn->prepare($sql2);
    $stmt2->bind_param("ss", $date, $email);
    $stmt2->execute();
    
    echo json_encode(["success" => true, "data" => $user]);
} else {
    // Microsoft hesabıyla giriş yapan kullanıcı veritabanında yoksa otomatik kayıt yap
    $name = $data['name'] ?? '';
    $surname = $data['surname'] ?? '';
    $name_surname = $name . ' ' . $surname;
    $student_number = $data['student_number'] ?? '';
    $department = $data['department'] ?? '';
    date_default_timezone_set("Europe/Istanbul");
    $date = date("Y-m-d H:i:s");
    
    // Kullanıcıyı ekle
    $sql3 = "INSERT INTO $table_name (date, mail, name_surname, student_number, department, onay, ms_auth) VALUES (?, ?, ?, ?, ?, 1, 1)";
    $stmt3 = $conn->prepare($sql3);
    $stmt3->bind_param("sssss", $date, $email, $name_surname, $student_number, $department);
    
    if ($stmt3->execute()) {
        // Yeni eklenen kullanıcının ID'sini al
        $user_id = $conn->insert_id;
        
        // Kullanıcı bilgilerini getir
        $sql4 = "SELECT * FROM $table_name WHERE id = ?";
        $stmt4 = $conn->prepare($sql4);
        $stmt4->bind_param("i", $user_id);
        $stmt4->execute();
        $result4 = $stmt4->get_result();
        
        if ($result4->num_rows > 0) {
            $new_user = $result4->fetch_assoc();
            echo json_encode(["success" => true, "data" => $new_user, "message" => "Microsoft hesabıyla yeni kullanıcı oluşturuldu"]);
        } else {
            echo json_encode(["success" => false, "message" => "Kullanıcı oluşturuldu ancak bilgileri alınamadı"]);
        }
        
        $stmt4->close();
    } else {
        echo json_encode(["success" => false, "message" => "Microsoft hesabıyla kullanıcı oluşturulamadı: " . $stmt3->error]);
    }
    
    $stmt3->close();
}

$stmt->close();
$conn->close();

?>
