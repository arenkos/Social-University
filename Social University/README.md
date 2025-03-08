# Sosyal Üniversite Uygulaması

Bu uygulama, üniversite öğrencileri için geliştirilmiş bir sohbet uygulamasıdır. Öğrenciler Microsoft hesaplarıyla giriş yapabilir, derslere katılabilir ve sohbet edebilirler.

## Microsoft Kimlik Doğrulama Entegrasyonu

Bu belge, Sosyal Üniversite uygulamasına Microsoft kimlik doğrulama özelliğini eklemek için gerekli adımları açıklar.

## Yapılan Değişiklikler

Aşağıdaki dosyalar oluşturuldu veya güncellendi:

1. **MicrosoftAuthManager.swift**: Microsoft kimlik doğrulama işlemlerini yöneten sınıf.
2. **AuthService.swift**: Kimlik doğrulama servisini uygulama ile entegre eden sınıf.
3. **LoginView.swift**: Kullanıcı giriş ekranı.
4. **AppDelegate.swift**: URL şema işlemleri için gerekli sınıf.
5. **Info.plist**: URL şemaları için gerekli yapılandırma.

## Microsoft Kimlik Doğrulama Entegrasyonu Adımları

### 1. Microsoft Azure Portal'da Uygulama Kaydı

1. [Microsoft Azure Portal](https://portal.azure.com)'a gidin ve oturum açın.
2. "Azure Active Directory" > "Uygulama kayıtları" > "Yeni kayıt" seçeneğini tıklayın.
3. Uygulamanıza bir isim verin (örn. "Sosyal Üniversite").
4. Desteklenen hesap türleri olarak "Herhangi bir kuruluş dizinindeki hesaplar" seçeneğini seçin.
5. Yönlendirme URI'si olarak `msauth.com.yourdomain.socialuniversity://auth` ekleyin (bu URI'yi kendi uygulama kimliğinizle değiştirin).
6. "Kaydet" düğmesine tıklayın.
7. Kayıt tamamlandıktan sonra, "Uygulama (istemci) Kimliği" değerini not alın.

### 2. MSAL Paketini Projeye Ekleme

1. Xcode'da projeyi açın.
2. "File" > "Add Packages..." seçeneğini tıklayın.
3. Arama çubuğuna `https://github.com/AzureAD/microsoft-authentication-library-for-objc` yazın.
4. "MSAL" paketini seçin ve "Add Package" düğmesine tıklayın.

### 3. Uygulama Kodunu Güncelleme

1. `MicrosoftAuthManager.swift` dosyasını açın.
2. `clientId` değişkenini Azure Portal'dan aldığınız "Uygulama (istemci) Kimliği" ile güncelleyin.
3. `redirectUri` değişkenini kendi uygulama kimliğinizle güncelleyin.
4. Yorum satırı olarak eklenmiş MSAL kodlarını etkinleştirin.

### 4. Info.plist Dosyasını Güncelleme

Info.plist dosyasında aşağıdaki değerleri güncelleyin:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>com.yourdomain.socialuniversity</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>msauth.com.yourdomain.socialuniversity</string>
        </array>
    </dict>
</array>
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>msauthv2</string>
    <string>msauthv3</string>
</array>
```

### 5. AppDelegate.swift Dosyasını Güncelleme

`AppDelegate.swift` dosyasında URL şema işlemlerini etkinleştirin:

```swift
func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
    // MSAL kütüphanesi entegre edildiğinde yorum satırını kaldırın
    // return MSALPublicClientApplication.handleMSALResponse(url, sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String)
    
    return true
}
```

## Microsoft Kimlik Doğrulama Akışı

1. Kullanıcı "Microsoft ile Giriş Yap" düğmesine tıklar.
2. MSAL kütüphanesi, kullanıcıyı Microsoft kimlik doğrulama sayfasına yönlendirir.
3. Kullanıcı Microsoft hesap bilgilerini girer.
4. Başarılı kimlik doğrulama sonrasında, kullanıcı uygulamaya geri yönlendirilir.
5. MSAL kütüphanesi, erişim belirtecini (access token) alır.
6. Uygulama, Microsoft Graph API'yi kullanarak kullanıcı bilgilerini alır.
7. Kullanıcı bilgileri, uygulamada kaydedilir ve kullanıcı giriş yapmış olur.

## Sorun Giderme

Eğer kimlik doğrulama sırasında sorunlar yaşıyorsanız:

1. Azure Portal'da uygulama kaydınızı kontrol edin.
2. Yönlendirme URI'sinin doğru olduğundan emin olun.
3. Info.plist dosyasındaki URL şemalarının doğru olduğundan emin olun.
4. Xcode konsolunda hata mesajlarını kontrol edin.

## Daha Fazla Bilgi

- [Microsoft Authentication Library (MSAL) for iOS](https://github.com/AzureAD/microsoft-authentication-library-for-objc)
- [Microsoft Graph API Documentation](https://docs.microsoft.com/en-us/graph/overview)
- [Azure Active Directory Authentication](https://docs.microsoft.com/en-us/azure/active-directory/develop/)

## Uygulama Özellikleri

- Microsoft API ile kimlik doğrulama
- Ders listesi görüntüleme ve filtreleme
- Derslere katılma ve ayrılma
- WhatsApp benzeri sohbet arayüzü
- Gerçek zamanlı mesajlaşma

## Teknik Detaylar

- Swift ve SwiftUI ile geliştirilmiştir
- SwiftData ile yerel veritabanı yönetimi
- Microsoft Authentication Library (MSAL) ile kimlik doğrulama
- Microsoft Graph API ile kullanıcı bilgilerini alma 