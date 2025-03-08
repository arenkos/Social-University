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

## Tamamlanması Gereken Adımlar

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

### 4. MSAL Entegrasyonu

MSAL paketini ekledikten sonra, `MicrosoftAuthManager.swift` dosyasını güncelleyin:

1. `import MSAL` ifadesini ekleyin.
2. `initMSAL()` fonksiyonunu çağırın.
3. `signIn()` ve `signOut()` fonksiyonlarını MSAL kullanacak şekilde güncelleyin.

## Örnek Kod

```swift
// MicrosoftAuthManager.swift dosyasında:

import MSAL

private var application: MSALPublicClientApplication?

private func initMSAL() {
    let authority = "\(authority)/organizations"
    let msalConfiguration = MSALPublicClientApplicationConfig(clientId: clientId, redirectUri: redirectUri, authority: authority)
    
    do {
        application = try MSALPublicClientApplication(configuration: msalConfiguration)
    } catch {
        print("MSAL başlatma hatası: \(error)")
    }
}
```

## Sorun Giderme

Eğer kimlik doğrulama sırasında sorunlar yaşıyorsanız:

1. Info.plist dosyasındaki URL şemalarının doğru olduğundan emin olun.
2. Azure Portal'daki yönlendirme URI'sinin uygulama içindeki URI ile eşleştiğini kontrol edin.
3. Xcode konsolunda hata mesajlarını kontrol edin.

## Daha Fazla Bilgi

Microsoft kimlik doğrulama hakkında daha fazla bilgi için:

- [Microsoft Authentication Library (MSAL) for iOS](https://github.com/AzureAD/microsoft-authentication-library-for-objc)
- [Microsoft Graph API Documentation](https://docs.microsoft.com/en-us/graph/overview)

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