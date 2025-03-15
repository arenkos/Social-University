//
//  Social_UniversityApp.swift
//  Social University
//
//  Created by Aren Koş on 8.03.2025.
//

import SwiftUI
import SwiftData

@main
struct Social_UniversityApp: App {
    // AppDelegate'i platform koşullu olarak entegre et
    #if canImport(UIKit)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif
    
    // Uygulama genelinde oturum durumunu takip et
    @AppStorage("com.socialuniversity.isAuthenticated") private var isAuthenticated = false
    @State private var currentUser: User?
    
    // Uygulamanın başlangıç durumu
    @State private var isInitialized = false
    // Yeniden başlatma gerektiğinde kullanılacak
    @State private var resetNavigation = false
    
    // AppSchema'yı kullanarak model container oluştur
    let sharedModelContainer = AppSchema.modelContainer()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(AuthService())
                .modelContainer(sharedModelContainer)
                .onAppear {
                    // App başladığında veritabanı hatalarını önlemek için gerekli
                    print("ContentView görünümü başlatılıyor ve modelContainer ayarlanıyor")
                }
                .onChange(of: isAuthenticated) { oldValue, newValue in
                    print("Oturum durumu değişti: \(oldValue) -> \(newValue)")
                    if !newValue {
                        // Çıkış yapıldığında tüm veriler temizlenir
                        currentUser = nil
                        isInitialized = false
                        
                        // NavigationStack'i yeniden oluşturmak için ID değiştir
                        resetNavigation.toggle()
                        
                        // Bu kısım otomatik olarak giriş sayfasına yönlendirecek
                        print("Oturum kapatıldı, giriş sayfasına yönlendiriliyor")
                    } else if !isInitialized {
                        // Giriş yapıldığında, kullanıcı verilerini yükle
                        loadUserData()
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LogoutNotification"))) { _ in
                    print("Çıkış bildirimi alındı, uygulama yeniden başlatılıyor...")
                    // isAuthenticated zaten false yapılmış olmalı, ama yine de kontrol et
                    if isAuthenticated {
                        isAuthenticated = false
                    }
                    
                    // NavigationStack'i yeniden oluştur
                    resetNavigation.toggle()
                    
                    #if canImport(UIKit)
                    // Root view controller'ı sıfırla
                    resetRootViewController()
                    #endif
                }
        }
    }
    
    #if canImport(UIKit)
    // Root view controller'ı sıfırla
    private func resetRootViewController() {
        DispatchQueue.main.async {
            if #available(iOS 15.0, *) {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    // Animasyonu kapat ve root view controller'ı yeniden oluştur
                    UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve) {
                        let rootViewController = UIHostingController(rootView: LoginView())
                        window.rootViewController = rootViewController
                    }
                }
            } else {
                // iOS 15 öncesi için
                if let window = UIApplication.shared.windows.first {
                    UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve) {
                        let rootViewController = UIHostingController(rootView: LoginView())
                        window.rootViewController = rootViewController
                    }
                }
            }
        }
    }
    
    // NavigationStack'i sıfırla
    private func resetNavigationStack() {
        DispatchQueue.main.async {
            if #available(iOS 15.0, *) {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootViewController = windowScene.windows.first?.rootViewController {
                    // NavigationController'ı bul
                    findAndResetNavigationController(rootViewController)
                }
            } else {
                // iOS 15 öncesi için
                if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
                    findAndResetNavigationController(rootViewController)
                }
            }
        }
    }
    
    // NavigationController'ı bul ve sıfırla
    private func findAndResetNavigationController(_ viewController: UIViewController) {
        if let navigationController = viewController as? UINavigationController {
            navigationController.popToRootViewController(animated: true)
        } else if let tabBarController = viewController as? UITabBarController {
            if let selectedViewController = tabBarController.selectedViewController {
                findAndResetNavigationController(selectedViewController)
            }
        } else if let presentedViewController = viewController.presentedViewController {
            viewController.dismiss(animated: true) {
                print("Tüm modallar kapatıldı.")
            }
        }
    }
    #endif
    
    // Kullanıcı verilerini yükle
    private func loadUserData() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Demo kullanıcı mı kontrol et
            let isDemo = UserDefaults.standard.bool(forKey: "com.socialuniversity.isDemo")
            
            if isDemo {
                // Demo kullanıcı bilgilerini UserDefaults'tan al
                let id = UserDefaults.standard.string(forKey: "com.socialuniversity.userId") ?? "demo-user-id"
                let name = UserDefaults.standard.string(forKey: "com.socialuniversity.userName") ?? "Demo"
                let surname = UserDefaults.standard.string(forKey: "com.socialuniversity.userSurname") ?? "Kullanıcı"
                let email = UserDefaults.standard.string(forKey: "com.socialuniversity.userEmail") ?? "demo@university.edu.tr"
                let studentNumber = UserDefaults.standard.string(forKey: "com.socialuniversity.userStudentNumber") ?? "123456"
                let department = UserDefaults.standard.string(forKey: "com.socialuniversity.userDepartment") ?? "Bilgisayar Mühendisliği"
                
                // Demo kullanıcı oluştur
                currentUser = User(
                    id: id,
                    email: email,
                    name: name,
                    surname: surname,
                    studentNumber: studentNumber,
                    department: department
                )
            } else {
                // Microsoft kullanıcı bilgilerini MicrosoftAuthManager'dan al
                if let userInfo = MicrosoftAuthManager.shared.getSavedUserInfo() {
                    currentUser = User(
                        id: userInfo.id,
                        email: userInfo.email,
                        name: userInfo.name,
                        surname: userInfo.surname,
                        studentNumber: userInfo.studentNumber,
                        department: userInfo.department
                    )
                } else {
                    // Kullanıcı bilgisi yoksa, varsayılan oluştur (bu durumda çıkış yapmak daha iyi olabilir)
                    isAuthenticated = false
                    return
                }
            }
            
            isInitialized = true
        }
    }
    
    // Test ve önizleme için varsayılan kullanıcı
    private func createDefaultUser() -> User {
        return User(
            id: "default-id",
            email: "default@example.com",
            name: "Varsayılan",
            surname: "Kullanıcı",
            studentNumber: "000000",
            department: ""
        )
    }
}

// Uygulama içinde kullanılan model sınıflarını import ediyoruz
// NOT: Model sınıfları Models.swift dosyasında tanımlanmıştır
// Bu nedenle buradaki tanımlamalar kaldırılmıştır
