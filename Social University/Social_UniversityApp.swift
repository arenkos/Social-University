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
    
    var body: some Scene {
        WindowGroup {
            // Oturum durumuna göre görünümü belirle
            Group {
                if isAuthenticated {
                    if currentUser != nil {
                        NavigationStack {
                            CourseListView(user: currentUser!)
                        }
                    } else {
                        LoginView()
                            .onAppear {
                                checkAuthenticationStatus()
                            }
                    }
                } else {
                    LoginView()
                }
            }
            .modelContainer(for: [User.self, Course.self, Message.self, Item.self])
            .onAppear {
                // Uygulama başladığında oturum durumunu kontrol et
                checkAuthenticationStatus()
            }
            .onChange(of: isAuthenticated) { _, newValue in
                // Oturum durumu değiştiğinde çağrılacak
                if !newValue {
                    // Çıkış yapıldığında, currentUser'ı temizle
                    currentUser = nil
                } else if currentUser == nil {
                    // Giriş yapıldığında ama currentUser yoksa, kullanıcı bilgilerini yükle
                    checkAuthenticationStatus()
                }
            }
        }
    }
    
    // Oturum durumunu kontrol et
    private func checkAuthenticationStatus() {
        if isAuthenticated {
            if let savedUserInfo = MicrosoftAuthManager.shared.getSavedUserInfo() {
                // Kaydedilmiş kullanıcı bilgilerini kullanarak User modelini oluştur
                let user = User(
                    id: savedUserInfo.id,
                    email: savedUserInfo.email,
                    name: savedUserInfo.name,
                    surname: savedUserInfo.surname,
                    studentNumber: savedUserInfo.studentNumber,
                    department: savedUserInfo.department
                )
                currentUser = user
            } else {
                // Kimlik doğrulama bilgisi var ama kullanıcı bilgisi yok, oturumu kapat
                isAuthenticated = false
            }
        }
    }
}

// Uygulama içinde kullanılan model sınıflarını import ediyoruz
// NOT: Model sınıfları Models.swift dosyasında tanımlanmıştır
// Bu nedenle buradaki tanımlamalar kaldırılmıştır
