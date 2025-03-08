# Sosyal Üniversite Uygulaması

Üniversite öğrencileri için geliştirilmiş bir sohbet uygulaması. Öğrenciler, üniversite e-posta adresleriyle giriş yaparak derslerine katılabilir ve diğer öğrencilerle iletişim kurabilirler.

## Özellikler

- Microsoft API ile üniversite e-posta adresi üzerinden giriş
- Ders listesi görüntüleme ve filtreleme
- Derslere katılma ve ayrılma
- WhatsApp benzeri sohbet arayüzü
- Gerçek zamanlı mesajlaşma

## Teknik Detaylar

### iOS Uygulaması

- Swift ve SwiftUI ile geliştirilmiştir
- SwiftData ile yerel veritabanı yönetimi
- URLSession ile API iletişimi

### Sunucu Tarafı

- PHP ile geliştirilmiş RESTful API
- MySQL veritabanı
- PDO ile güvenli veritabanı işlemleri

## Kurulum

### iOS Uygulaması

1. Xcode'u açın
2. Proje dosyasını açın (`Social University.xcodeproj`)
3. `APIService.swift` dosyasında `baseURL` değişkenini kendi sunucu adresinizle güncelleyin
4. Uygulamayı derleyin ve çalıştırın

### Sunucu Tarafı

1. PHP ve MySQL destekli bir web sunucusu kurun
2. `server` klasöründeki dosyaları sunucunuza yükleyin
3. `config.php` dosyasında veritabanı bağlantı bilgilerini güncelleyin
4. `schema.sql` dosyasını MySQL veritabanınızda çalıştırarak tabloları oluşturun

## API Endpoint'leri

### Kullanıcı İşlemleri

- `POST /api/login.php`: Microsoft API ile giriş yapar

### Ders İşlemleri

- `GET /api/courses.php`: Dersleri listeler
- `POST /api/enroll.php`: Derse katılma/ayrılma işlemlerini yapar

### Mesaj İşlemleri

- `GET /api/messages.php`: Bir derse ait mesajları listeler
- `POST /api/messages.php`: Yeni mesaj gönderir

## Geliştirme

### Microsoft API Entegrasyonu

Gerçek bir uygulamada, Microsoft Graph API kullanarak üniversite e-posta adreslerini doğrulamanız gerekecektir. Bu örnek uygulamada, basitleştirilmiş bir simülasyon kullanılmıştır.

### Gerçek Zamanlı Mesajlaşma

Daha gelişmiş bir sürümde, WebSocket veya Firebase gibi teknolojiler kullanarak gerçek zamanlı mesajlaşma eklenebilir.

## Lisans

Bu proje MIT lisansı altında lisanslanmıştır. Detaylar için `LICENSE` dosyasına bakın. 