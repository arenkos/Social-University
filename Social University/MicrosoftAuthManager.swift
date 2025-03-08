import Foundation
import SwiftUI
import SwiftData
// MSAL kütüphanesini import ediyoruz
import MSAL
import UIKit

// Microsoft kimlik doğrulama için gerekli sınıf
public class MicrosoftAuthManager {
    // Kullanıcı bilgilerini taşıyan yapı
    public struct UserInfo: Codable {
        public let id: String
        public let email: String
        public let name: String
        public let surname: String
        public let studentNumber: String
        public let department: String
        
        public init(id: String, email: String, name: String, surname: String, studentNumber: String, department: String) {
            self.id = id
            self.email = email
            self.name = name
            self.surname = surname
            self.studentNumber = studentNumber
            self.department = department
        }
    }
    
    // Singleton örneği
    public static let shared = MicrosoftAuthManager()
    
    // UserDefaults için anahtarlar
    private let userInfoKey = "com.socialuniversity.userInfo"
    private let isAuthenticatedKey = "com.socialuniversity.isAuthenticated"
    
    // Microsoft uygulama kimlik bilgileri
    private let clientId = "c456eab1-fe61-4c7e-925e-e907e5ab07b8" // Microsoft Azure Portal'dan alınacak
    private let redirectUri = "msauth.AR-Software-Consultancy.Social-University://auth" // Uygulamanız için tanımladığınız yönlendirme URI'si
    private let authority = "https://login.microsoftonline.com/common" // Tekrar common kullanıyoruz
    private let scopes = ["User.Read", "User.ReadBasic.All"]
    
    // MSAL uygulama örneği
    private var msalApplication: MSALPublicClientApplication?
    
    private init() {
        // MSAL uygulamasını başlat
        setupMSAL()
    }
    
    // MSAL kurulumu
    private func setupMSAL() {
        do {
            // Authority URL'sini doğru formatta oluştur
            guard let authorityURL = URL(string: "\(authority)") else {
                print("Authority URL oluşturulamadı")
                return
            }
            
            let authority = try MSALAuthority(url: authorityURL)
            
            // MSAL konfigürasyonu
            let config = MSALPublicClientApplicationConfig(clientId: clientId,
                                                          redirectUri: redirectUri,
                                                          authority: authority)
            
            // Ek yapılandırma ayarları
            config.cacheConfig.keychainSharingGroup = "AR-Software-Consultancy.Social-University"
            
            msalApplication = try MSALPublicClientApplication(configuration: config)
            print("MSAL başarıyla başlatıldı")
        } catch {
            print("MSAL başlatma hatası: \(error)")
        }
    }
    
    // Kullanıcının oturum açıp açmadığını kontrol et
    public func isAuthenticated() -> Bool {
        return UserDefaults.standard.bool(forKey: isAuthenticatedKey)
    }
    
    // Kaydedilmiş kullanıcı bilgilerini getir
    public func getSavedUserInfo() -> UserInfo? {
        guard let data = UserDefaults.standard.data(forKey: userInfoKey) else {
            return nil
        }
        
        do {
            let userInfo = try JSONDecoder().decode(UserInfo.self, from: data)
            return userInfo
        } catch {
            print("Kullanıcı bilgileri çözülemedi: \(error)")
            return nil
        }
    }
    
    // Kullanıcı bilgilerini kaydet
    private func saveUserInfo(_ userInfo: UserInfo) {
        do {
            let data = try JSONEncoder().encode(userInfo)
            UserDefaults.standard.set(data, forKey: userInfoKey)
            UserDefaults.standard.set(true, forKey: isAuthenticatedKey)
        } catch {
            print("Kullanıcı bilgileri kaydedilemedi: \(error)")
        }
    }
    
    // Microsoft ile giriş işlemi
    public func signIn(viewController: UIViewController, completion: @escaping (Result<UserInfo, Error>) -> Void) {
        // MSAL uygulamasını kontrol et
        guard let application = msalApplication else {
            let error = NSError(domain: "MicrosoftAuthManager", code: 1001, userInfo: [NSLocalizedDescriptionKey: "MSAL uygulaması başlatılamadı. Lütfen daha sonra tekrar deneyin."])
            completion(.failure(error))
            return
        }
        
        // Doğrudan interaktif kimlik doğrulama kullan
        acquireTokenInteractively(application: application, viewController: viewController) { result in
            switch result {
            case .success(let userInfo):
                // Kullanıcı bilgilerini kaydet
                self.saveUserInfo(userInfo)
                completion(.success(userInfo))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // Sessiz kimlik doğrulama (token yenileme)
    private func acquireTokenSilently(application: MSALPublicClientApplication, completion: @escaping (Result<String, Error>) -> Void) {
        do {
            // Mevcut hesapları kontrol et
            let accounts = try application.allAccounts()
            
            // Hesap yoksa hata döndür
            guard let account = accounts.first else {
                completion(.failure(NSError(domain: "MicrosoftAuthManager", code: 1002, userInfo: [NSLocalizedDescriptionKey: "Oturum açık hesap bulunamadı"])))
                return
            }
            
            // Sessiz token alma parametreleri
            let parameters = MSALSilentTokenParameters(scopes: scopes, account: account)
            
            // Sessiz token alma işlemi
            application.acquireTokenSilent(with: parameters) { (result, error) in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let result = result else {
                    completion(.failure(NSError(domain: "MicrosoftAuthManager", code: 1003, userInfo: [NSLocalizedDescriptionKey: "Token alınamadı"])))
                    return
                }
                
                completion(.success(result.accessToken))
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    // İnteraktif kimlik doğrulama
    private func acquireTokenInteractively(application: MSALPublicClientApplication, viewController: UIViewController, completion: @escaping (Result<UserInfo, Error>) -> Void) {
        // Web görünümü parametrelerini oluştur
        let webViewParameters = MSALWebviewParameters(authPresentationViewController: viewController)
        
        // Web görünümü tipini ayarla - Sadece WKWebView kullan (uygulama içi web görünümü)
        webViewParameters.webviewType = .wkWebView
        
        // Geçici oturum kullanma (tarayıcı geçmişi saklanmasın)
        webViewParameters.prefersEphemeralWebBrowserSession = true
        
        // Interaktif parametreleri yapılandır
        let parameters = MSALInteractiveTokenParameters(scopes: scopes, webviewParameters: webViewParameters)
        parameters.promptType = .selectAccount // Kullanıcıya hesap seçme ekranını göster
        
        // Broker (Microsoft Authenticator) kullanımını devre dışı bırak
        parameters.extraQueryParameters = ["use_broker": "NO", "prompt": "login"]
        
        // Hata ayıklama için ek bilgiler
        print("MSAL Giriş Başlatılıyor - ClientID: \(clientId)")
        print("MSAL Giriş Başlatılıyor - RedirectURI: \(redirectUri)")
        print("MSAL Giriş Başlatılıyor - Authority: \(authority)")
        print("MSAL Web Görünümü Tipi: \(webViewParameters.webviewType.rawValue)")
        print("MSAL Web Görünümü Geçici Oturum: \(webViewParameters.prefersEphemeralWebBrowserSession)")
        
        application.acquireToken(with: parameters) { (result, error) in
            if let error = error {
                print("MSAL Hata Detayları: \(error)")
                
                // MSALError tipine dönüştürme
                let nsError = error as NSError
                let errorCode = nsError.code
                let errorDomain = nsError.domain
                let errorUserInfo = nsError.userInfo
                
                print("MSAL Hata Kodu: \(errorCode)")
                print("MSAL Hata Domain: \(errorDomain)")
                print("MSAL Hata UserInfo: \(errorUserInfo)")
                
                // Özel hata mesajı oluştur
                var detailedErrorMessage = "Microsoft giriş hatası: "
                
                if errorCode == -50000 {
                    detailedErrorMessage += "Uygulama yapılandırma hatası. Azure Portal'da uygulama ayarlarınızı kontrol edin."
                } else {
                    detailedErrorMessage += error.localizedDescription
                }
                
                completion(.failure(NSError(domain: errorDomain, code: errorCode, userInfo: [NSLocalizedDescriptionKey: detailedErrorMessage])))
                return
            }
            
            guard let result = result else {
                completion(.failure(NSError(domain: "MicrosoftAuthManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Token alınamadı"])))
                return
            }
            
            print("MSAL Token başarıyla alındı")
            self.fetchUserProfile(token: result.accessToken, completion: completion)
        }
    }
    
    // Microsoft Graph API'den kullanıcı bilgilerini alma
    private func fetchUserProfile(token: String, completion: @escaping (Result<UserInfo, Error>) -> Void) {
        let url = URL(string: "https://graph.microsoft.com/v1.0/me")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "MicrosoftAuthManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Veri alınamadı"])))
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                
                let id = json?["id"] as? String ?? ""
                let email = (json?["mail"] as? String) ?? (json?["userPrincipalName"] as? String) ?? ""
                let name = json?["givenName"] as? String ?? "Kullanıcı"
                let surname = json?["surname"] as? String ?? "Adı"
                
                // Öğrenci numarası ve bölüm bilgisi için ek API çağrıları yapılabilir
                let studentNumber = email.components(separatedBy: "@").first ?? ""
                let department = "Bilgisayar Mühendisliği" // Varsayılan değer
                
                let userInfo = UserInfo(
                    id: id,
                    email: email,
                    name: name,
                    surname: surname,
                    studentNumber: studentNumber,
                    department: department
                )
                
                DispatchQueue.main.async {
                    print("Kullanıcı bilgileri başarıyla alındı: \(name) \(surname) (\(email))")
                    completion(.success(userInfo))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MSAL uygulamasını al
    private func getMSALApplication() -> MSALPublicClientApplication? {
        return msalApplication
    }
    
    // MSAL hesabını al
    private func getMSALAccount() -> MSALAccount? {
        guard let application = getMSALApplication() else {
            return nil
        }
        
        do {
            let accounts = try application.allAccounts()
            return accounts.first
        } catch {
            print("MSAL hesaplarını alma hatası: \(error)")
            return nil
        }
    }
    
    // Çıkış işlemi
    func signOut(completion: @escaping (Bool) -> Void) {
        // Önce kullanıcının demo kullanıcı olup olmadığını kontrol et
        let isDemo = UserDefaults.standard.bool(forKey: "com.socialuniversity.isDemo")
        
        if isDemo {
            // Demo kullanıcı için oturum bilgilerini temizle
            clearUserDefaults()
            completion(true)
            return
        }
        
        // Microsoft kullanıcısı için çıkış işlemi
        guard let application = getMSALApplication() else {
            clearUserDefaults()
            completion(false)
            return
        }
        
        guard let account = getMSALAccount() else {
            clearUserDefaults()
            completion(true) // Hesap bulunamadıysa başarılı kabul et
            return
        }
        
        // Hata mesajında belirtildiği gibi, signoutFromBrowser true olduğunda geçerli MSALWebviewParameters gerekiyor
        #if canImport(UIKit)
        // UIKit mevcutsa, bir UI view controller belirtmeliyiz
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let viewController = windowScene.windows.first?.rootViewController {
            // WebView parametreleri oluştur
            let webViewParameters = MSALWebviewParameters(authPresentationViewController: viewController)
            webViewParameters.webviewType = .wkWebView
            
            // Signout parametrelerini, webViewParameters ile birlikte oluştur
            let parameters = MSALSignoutParameters(webviewParameters: webViewParameters)
            parameters.signoutFromBrowser = true
            
            // Çıkış işlemini gerçekleştir
            do {
                try application.signout(with: account, signoutParameters: parameters, completionBlock: { (success, error) in
                    if let error = error {
                        print("Microsoft çıkış hatası: \(error)")
                        completion(false)
                        return
                    }
                    
                    self.clearUserDefaults()
                    completion(true)
                })
            } catch {
                print("Microsoft çıkış hatası: \(error)")
                clearUserDefaults()
                completion(false)
            }
        } else {
            // View controller alınamadı, UserDefaults'u temizleyip çıkış yap
            print("View controller alınamadı, UserDefaults temizleniyor")
            clearUserDefaults()
            completion(true)
        }
        #else
        // UIKit yoksa, UserDefaults'u temizleyip çıkış yap
        print("UIKit import edilemedi, UserDefaults temizleniyor")
        clearUserDefaults()
        completion(true)
        #endif
    }
    
    // UserDefaults'tan kullanıcı bilgilerini temizle
    private func clearUserDefaults() {
        // Tüm kullanıcı bilgilerini temizle
        UserDefaults.standard.removeObject(forKey: "com.socialuniversity.userId")
        UserDefaults.standard.removeObject(forKey: "com.socialuniversity.userName")
        UserDefaults.standard.removeObject(forKey: "com.socialuniversity.userSurname")
        UserDefaults.standard.removeObject(forKey: "com.socialuniversity.userEmail")
        UserDefaults.standard.removeObject(forKey: "com.socialuniversity.userStudentNumber")
        UserDefaults.standard.removeObject(forKey: "com.socialuniversity.userDepartment")
        UserDefaults.standard.removeObject(forKey: "com.socialuniversity.isDemo")
        UserDefaults.standard.removeObject(forKey: "com.socialuniversity.accessToken")
        UserDefaults.standard.removeObject(forKey: "com.socialuniversity.account")
        
        // Değişiklikleri hemen uygula
        UserDefaults.standard.synchronize()
    }
} 
