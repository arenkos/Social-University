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
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    // Uygulama genelinde oturum durumunu takip eden değişkenlere erişim
    @AppStorage("com.socialuniversity.isAuthenticated") private var isAuthenticated = false
    @State private var currentUser: User?
    
    // Demo kullanıcı için geçici yönlendirme kontrolü
    @State private var shouldNavigateToUniversitySelection = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // Başlık ve açıklama
                VStack(spacing: 10) {
                    Image("AppLogo") // Logo ekleyebilirsiniz
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                    
                    Text("Social University")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Üniversite hayatını keşfet, arkadaş edin, ders notlarını paylaş")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                // Giriş bölümü
                VStack(spacing: 20) {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(1.5)
                            .padding()
                    } else if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding()
                    }
                    
                    Button(action: {
                        signInWithMicrosoft()
                    }) {
                        HStack {
                            Image(systemName: "globe")
                                .font(.title3)
                            Text("Microsoft Hesabı ile Giriş Yap")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(isLoading)
                    
                    Text("veya")
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        createDemoUser()
                    }) {
                        Text("Demo kullanıcı ile devam et")
                            .underline()
                            .foregroundColor(.secondary)
                    }
                    .disabled(isLoading)
                }
                .padding(.horizontal, 30)
                
                Spacer()
                
                // Alt bilgi
                Text("© 2025 Social University Tüm Hakları Saklıdır")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom)
            }
            .padding()
            .navigationDestination(isPresented: $shouldNavigateToUniversitySelection) {
                if let user = currentUser {
                    UniversitySelectionView(user: user)
                }
            }
        }
    }
    
    private func signInWithMicrosoft() {
        isLoading = true
        errorMessage = nil
        
        // UIViewController'ı elde etme
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            errorMessage = "Uygulama penceresi hazır değil."
            isLoading = false
            return
        }
        
        // Microsoft kimlik doğrulama işlemi
        MicrosoftAuthManager.shared.signIn(viewController: rootViewController) { result in
            isLoading = false
            
            switch result {
            case .success(let userInfo):
                // Kullanıcı modelini oluştur
                let user = User(
                    id: userInfo.id,
                    email: userInfo.email,
                    name: userInfo.name,
                    surname: userInfo.surname,
                    studentNumber: userInfo.studentNumber,
                    department: userInfo.department
                )
                
                // ModelContext'e ekle
                modelContext.insert(user)
                
                // Oturum durumunu güncelle ve kullanıcıyı kaydet
                currentUser = user
                
                // AppStorage'daki oturum durumu değişkenini güncelle
                isAuthenticated = true
                
                // Üniversite seçim sayfasına yönlendir
                shouldNavigateToUniversitySelection = true
                
                print("Microsoft kullanıcısı ile giriş yapıldı: \(user.name)")
                
            case .failure(let error):
                errorMessage = "Giriş yapılamadı: \(error.localizedDescription)"
            }
        }
    }
    
    private func createDemoUser() {
        isLoading = true
        
        // Demo kullanıcı oluştur
        let demoUser = User(
            id: "demo-user-id",
            email: "demo@university.edu.tr",
            name: "Demo",
            surname: "Kullanıcı",
            studentNumber: "123456",
            department: "Bilgisayar Mühendisliği"
        )
        
        // ModelContext'e ekle
        modelContext.insert(demoUser)
        
        // Örnek veriler oluştur
        createSampleData(for: demoUser)
        
        // Kullanıcıyı ayarla
        currentUser = demoUser
        
        // Demo kullanıcı bilgilerini UserDefaults'a kaydet
        // Bu şekilde demo kullanıcı girişi de Microsoft kullanıcısı gibi davranabilir
        UserDefaults.standard.set("demo-user-id", forKey: "com.socialuniversity.userId")
        UserDefaults.standard.set("Demo", forKey: "com.socialuniversity.userName")
        UserDefaults.standard.set("Kullanıcı", forKey: "com.socialuniversity.userSurname")
        UserDefaults.standard.set("demo@university.edu.tr", forKey: "com.socialuniversity.userEmail")
        UserDefaults.standard.set("123456", forKey: "com.socialuniversity.userStudentNumber")
        UserDefaults.standard.set("Bilgisayar Mühendisliği", forKey: "com.socialuniversity.userDepartment")
        UserDefaults.standard.set(true, forKey: "com.socialuniversity.isDemo")
        
        // AppStorage'daki oturum durumu değişkenini güncelle
        isAuthenticated = true
        
        // Doğrudan üniversite seçim sayfasına yönlendir
        shouldNavigateToUniversitySelection = true
        
        print("Demo kullanıcı ile giriş yapıldı.")
        isLoading = false
    }
    
    private func createSampleData(for user: User) {
        // Örnek dersler
        let courses = [
            Course(id: "BIL101", courseCode: "BIL101", courseName: "Bilgisayar Programlama", departmentName: "Bilgisayar Mühendisliği", isEnrolled: true),
            Course(id: "BIL203", courseCode: "BIL203", courseName: "Veri Yapıları", departmentName: "Bilgisayar Mühendisliği", isEnrolled: true),
            Course(id: "MAT101", courseCode: "MAT101", courseName: "Kalkülüs I", departmentName: "Matematik", isEnrolled: false),
            Course(id: "FIZ101", courseCode: "FIZ101", courseName: "Fizik I", departmentName: "Fizik", isEnrolled: false),
            Course(id: "ENG101", courseCode: "ENG101", courseName: "İngilizce I", departmentName: "Yabancı Diller", isEnrolled: true)
        ]
        
        // Örnek mesajlar
        let messages = [
            Message(
                id: "msg1",
                content: "Merhaba, bu derse hoş geldiniz!",
                timestamp: Date().addingTimeInterval(-86400), // 1 gün önce
                senderId: nil,
                courseId: "BIL101"
            ),
            Message(
                id: "msg2",
                content: "Ödev teslim tarihi ne zaman?",
                timestamp: Date().addingTimeInterval(-43200), // 12 saat önce
                senderId: user.id,
                courseId: "BIL101"
            ),
            Message(
                id: "msg3",
                content: "Ödevler gelecek hafta Cuma günü teslim edilecek.",
                timestamp: Date().addingTimeInterval(-21600), // 6 saat önce
                senderId: nil,
                courseId: "BIL101"
            )
        ]
        
        // Örnekleri ModelContext'e ekle
        for course in courses {
            modelContext.insert(course)
        }
        
        for message in messages {
            modelContext.insert(message)
        }
    }
}

#Preview {
    LoginView()
        .modelContainer(for: [User.self, Course.self, Message.self, Item.self], inMemory: true)
} 
