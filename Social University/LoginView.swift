//
//  LoginView.swift
//  Social University
//
//  Created by Aren Koş on 8.03.2025.
//

import SwiftUI
import SwiftData
#if canImport(UIKit)
import UIKit
#endif

struct LoginView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var authService = AuthService()
    
    // UIHostingController referansı için
    @State private var window: UIWindow?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Logo ve başlık
                Image(systemName: "graduationcap.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .foregroundColor(.blue)
                
                Text("Sosyal Üniversite")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Üniversite öğrencileri için sohbet uygulaması")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer().frame(height: 40)
                
                // Microsoft ile giriş butonu
                Button(action: {
                    #if canImport(UIKit)
                    // UIApplication'dan rootViewController'ı al
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let rootViewController = windowScene.windows.first?.rootViewController {
                        authService.signInWithMicrosoft(from: rootViewController)
                    } else {
                        authService.errorMessage = "Giriş yapılamıyor: UIViewController bulunamadı"
                    }
                    #else
                    authService.errorMessage = "Bu platformda Microsoft ile giriş desteklenmiyor"
                    #endif
                }) {
                    HStack {
                        Image(systemName: "person.crop.circle")
                            .font(.title2)
                        Text("Microsoft ile Giriş Yap")
                            .fontWeight(.semibold)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal, 40)
                .disabled(authService.isLoading)
                
                // Demo kullanıcı ile giriş butonu
                /*
                Button(action: {
                    authService.createDemoUserAndLogin()
                }) {
                    Text("Demo Kullanıcı ile Giriş Yap")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                }
                .padding(.horizontal, 40)
                .disabled(authService.isLoading)
                
                if authService.isLoading {
                    ProgressView()
                        .padding()
                }
                
                Spacer()
                
                // Hata mesajı
                if let errorMessage = authService.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }*/
            }
            .padding()
            .onAppear {
                // AuthService'e modelContext'i enjekte et
                authService.updateModelContext(modelContext)
            }
            .navigationDestination(isPresented: $authService.isAuthenticated) {
                if let user = authService.currentUser {
                    CourseListView(user: user)
                }
            }
        }
    }
}

#Preview {
    LoginView()
        .modelContainer(for: [User.self, Course.self, Message.self, Item.self], inMemory: true)
} 
