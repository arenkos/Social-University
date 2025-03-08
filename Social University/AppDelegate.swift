import Foundation
import SwiftUI
// MSAL kütüphanesini import ediyoruz
import MSAL

#if canImport(UIKit)
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Uygulama başlatma işlemleri
        return true
    }
    
    // Microsoft kimlik doğrulama için URL şema işlemleri
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        // MSAL kütüphanesi ile URL işlemleri
        print("URL şeması işleniyor: \(url)")
        
        // URL'nin doğru formatta olup olmadığını kontrol et
        guard url.scheme?.lowercased().hasPrefix("msauth") == true else {
            print("Geçersiz URL şeması: \(url.scheme ?? "nil")")
            return false
        }
        
        // MSAL kütüphanesine URL'yi işlemesi için gönder
        let result = MSALPublicClientApplication.handleMSALResponse(url, sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String)
        
        print("MSAL URL işleme sonucu: \(result)")
        return result
    }
}
#endif 