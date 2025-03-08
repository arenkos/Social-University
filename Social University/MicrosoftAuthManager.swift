import Foundation
import SwiftUI
import SwiftData
// MSAL kütüphanesini import ediyoruz
import MSAL
import UIKit

// Microsoft kimlik doğrulama için gerekli sınıf
public class MicrosoftAuthManager {
    // Kullanıcı bilgilerini taşıyan yapı
    public struct UserInfo {
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
    
    // Microsoft ile giriş işlemi
    public func signIn(viewController: UIViewController, completion: @escaping (Result<UserInfo, Error>) -> Void) {
        // MSAL uygulamasını kontrol et
        guard let application = msalApplication else {
            let error = NSError(domain: "MicrosoftAuthManager", code: 1001, userInfo: [NSLocalizedDescriptionKey: "MSAL uygulaması başlatılamadı. Lütfen daha sonra tekrar deneyin."])
            completion(.failure(error))
            return
        }
        
        // Doğrudan interaktif kimlik doğrulama kullan
        acquireTokenInteractively(application: application, viewController: viewController, completion: completion)
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
                let department = json?["department"] as? String ?? "" // Varsayılan değer
                
                let userInfo = UserInfo(
                    id: id,
                    email: email,
                    name: name,
                    surname: surname,
                    studentNumber: studentNumber,
                    department: department
                )
                
                DispatchQueue.main.async {
                    //print("Kullanıcı bilgileri başarıyla alındı: \(name) \(surname) (\(email))")
                    completion(.success(userInfo))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // Microsoft ile çıkış işlemi
    public func signOut(completion: @escaping (Bool) -> Void) {
        guard let application = msalApplication else {
            completion(false)
            return
        }
        
        do {
            let accounts = try application.allAccounts()
            if let account = accounts.first {
                try application.remove(account)
                print("Microsoft hesabından başarıyla çıkış yapıldı")
            }
            completion(true)
        } catch {
            print("Çıkış yapılırken hata oluştu: \(error)")
            completion(false)
        }
    }
} 
