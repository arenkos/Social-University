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
    
    // ✅ Oturum durumunu manuel olarak yönet
    @State private var isAuthenticated = false
    @State private var currentUser: User?
    
    // Uygulamanın başlangıç durumu
    @State private var isInitialized = false
    // Yeniden başlatma gerektiğinde kullanılacak
    @State private var resetNavigation = false
    
    // AppSchema'yı kullanarak model container oluştur
    let sharedModelContainer = AppSchema.modelContainer()
    
    // ✅ App başladığında UserDefaults'tan oturum durumunu oku
    init() {
        let savedIsAuthenticated = UserDefaults.standard.bool(forKey: "com.socialuniversity.isAuthenticated")
        let userId = UserDefaults.standard.string(forKey: "com.socialuniversity.userId") ?? "yok"
        let userEmail = UserDefaults.standard.string(forKey: "com.socialuniversity.userEmail") ?? "yok"
        
        print("🚀 App Init - UserDefaults kontrol:")
        print("   - isAuthenticated: \(savedIsAuthenticated)")
        print("   - userId: \(userId)")
        print("   - userEmail: \(userEmail)")
        
        // ✅ Eğer kullanıcı bilgileri var ama isAuthenticated false ise, düzelt
        if !savedIsAuthenticated && userId != "yok" && userEmail != "yok" {
            print("🔧 App Init: Kullanıcı bilgileri var ama isAuthenticated false, düzeltiliyor")
            UserDefaults.standard.set(true, forKey: "com.socialuniversity.isAuthenticated")
            self._isAuthenticated = State(initialValue: true)
        } else if savedIsAuthenticated && userId == "yok" {
            print("⚠️ Authentication var ama kullanıcı bilgileri yok, temizleniyor")
            UserDefaults.standard.set(false, forKey: "com.socialuniversity.isAuthenticated")
            self._isAuthenticated = State(initialValue: false)
        } else {
            self._isAuthenticated = State(initialValue: savedIsAuthenticated)
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(isAuthenticated: $isAuthenticated)
                .environmentObject(AuthService(modelContext: nil))
                .modelContainer(sharedModelContainer)
                .onAppear {
                    // App başladığında veritabanı hatalarını önlemek için gerekli
                    print("📱 App: ContentView görünümü başlatılıyor - isAuthenticated: \(isAuthenticated)")
                    print("📱 App: UserDefaults kontrol:")
                    print("   - isAuthenticated: \(UserDefaults.standard.bool(forKey: "com.socialuniversity.isAuthenticated"))")
                    print("   - userId: \(UserDefaults.standard.string(forKey: "com.socialuniversity.userId") ?? "nil")")
                }
                .onChange(of: isAuthenticated) { oldValue, newValue in
                    print("📱 App: Oturum durumu değişti: \(oldValue) -> \(newValue)")
                    
                    // ✅ Sadece gerçek değişikliklerde UserDefaults'a kaydet
                    if oldValue != newValue {
                        print("📱 App: UserDefaults'a isAuthenticated kaydediliyor: \(newValue)")
                        UserDefaults.standard.set(newValue, forKey: "com.socialuniversity.isAuthenticated")
                        
                        if !newValue && isInitialized {
                            // Sadece daha önce giriş yapılmışsa ve şimdi çıkış yapıldıysa
                            print("📱 App: Kullanıcı çıkış yaptı, giriş sayfasına yönlendiriliyor")
                            currentUser = nil
                            isInitialized = false
                            resetNavigation.toggle()
                        } else if newValue && !isInitialized {
                            // Giriş yapıldığında, kullanıcı verilerini yükle
                            print("📱 App: Kullanıcı giriş yaptı, veriler yükleniyor")
                            loadUserData()
                        }
                    } else {
                        print("📱 App: isAuthenticated değişikliği yok, UserDefaults güncellenmiyor")
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
