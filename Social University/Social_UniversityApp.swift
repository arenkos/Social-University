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
    
    var body: some Scene {
        WindowGroup {
            LoginView()
                .modelContainer(for: [User.self, Course.self, Message.self, Item.self])
        }
    }
}

// Uygulama içinde kullanılan model sınıflarını import ediyoruz
// NOT: Model sınıfları Models.swift dosyasında tanımlanmıştır
// Bu nedenle buradaki tanımlamalar kaldırılmıştır
