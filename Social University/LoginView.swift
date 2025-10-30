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

// AppModels.swift dosyasından modelleri otomatik olarak kullanıyoruz
// Swift modelleri aynı projede olduğu için buradan doğrudan erişilebilir

struct LoginView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    // ✅ Authentication state callback'i
    var onAuthenticationChange: ((Bool) -> Void)?
    
    @State private var currentUser: User?
    
    // Görünüm Durumu
    @State private var viewState: ViewState = .login
    
    // Login Alanları
    @State private var loginEmail = ""
    @State private var loginPassword = ""
    
    // Kayıt Alanları
    @State private var registerEmail = ""
    @State private var registerPassword = ""
    @State private var registerConfirmPassword = ""
    @State private var registerNameSurname = ""
    @State private var registerStudentNumber = ""
    @State private var registerPhone = ""
    
    // Yönlendirme Kontrolü
    @State private var shouldNavigateToCourses = false
    @State private var shouldNavigateToUniversitySelection = false
    @State private var shouldNavigateToDepartmentSelection = false
    
    enum ViewState {
        case login
        case register
    }
    
    // ✅ Kullanıcı bilgilerini UserDefaults'a kaydetme fonksiyonu
    private func saveUserToDefaults(_ user: User) {
        UserDefaults.standard.set(user.id, forKey: "com.socialuniversity.userId")
        UserDefaults.standard.set(user.email, forKey: "com.socialuniversity.userEmail")
        UserDefaults.standard.set(user.name, forKey: "com.socialuniversity.userName")
        UserDefaults.standard.set(user.surname, forKey: "com.socialuniversity.userSurname")
        UserDefaults.standard.set(user.studentNumber, forKey: "com.socialuniversity.userStudentNumber")
        UserDefaults.standard.set(user.department, forKey: "com.socialuniversity.department")
        UserDefaults.standard.set(user.university ?? "", forKey: "com.socialuniversity.university")
        
        // ✅ EN ÖNEMLİSİ: isAuthenticated'ı da kaydet
        UserDefaults.standard.set(true, forKey: "com.socialuniversity.isAuthenticated")
        
        print("✅ Kullanıcı bilgileri UserDefaults'a kaydedildi:")
        print("   - ID: \(user.id)")
        print("   - Email: \(user.email)")
        print("   - Name: \(user.name) \(user.surname)")
        print("   - University: \(user.university ?? "")")
        print("   - Department: \(user.department)")
        print("   - isAuthenticated: true")
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Başlık ve logo
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
                .padding(.top)
                
                // Görünüm Seçici (Login / Register)
                Picker("Görünüm", selection: $viewState) {
                    Text("Giriş Yap").tag(ViewState.login)
                    Text("Kayıt Ol").tag(ViewState.register)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 30)
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                } else if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
                
                // İçerik Alanı
                ScrollView {
                    if viewState == .login {
                        loginView
                    } else {
                        registerView
                    }
                }
                .scrollDismissesKeyboard(.interactively)
                
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
            .navigationDestination(isPresented: $shouldNavigateToDepartmentSelection) {
                if let user = currentUser {
                    // Bölüm seçim ekranına yönlendir
                    // Kullanıcının üniversitesi zaten seçili, sadece bölüm seçmeye yönlendir
                    UniversitySelectionView(user: user)
                        .onAppear {
                            // UniversitySelectionView içinde önceden seçilen üniversiteyi kullanacak
                            // ve otomatik olarak bölüm seçimine yönlendirecek
                            UserDefaults.standard.set(user.university, forKey: "com.socialuniversity.university")
                        }
                }
            }
            .navigationDestination(isPresented: $shouldNavigateToCourses) {
                if let user = currentUser {
                    // Ders listesi sayfasına yönlendir
                    CourseListView(user: user)
                }
            }
        }
    }
    
    // Giriş Formu
    private var loginView: some View {
        VStack(spacing: 20) {
            VStack(spacing: 15) {
                TextField("E-posta", text: $loginEmail)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                
                SecureField("Şifre", text: $loginPassword)
                    .textContentType(.password)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                
                Button(action: {
                    loginWithEmailPassword()
                }) {
                    Text("Giriş Yap")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(isLoading || loginEmail.isEmpty || loginPassword.isEmpty)
            }
            .padding(.horizontal, 30)
            
            Divider()
                .padding(.vertical)
            
            // Microsoft ile Giriş
            VStack(spacing: 15) {
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
                
                // Demo Kullanıcı
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
            
            /*
            Button(action: {
                logout()
            }) {
                Text("Çıkış Yap")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 30)
             */
        }
    }
    
    // Kayıt Formu
    private var registerView: some View {
        VStack(spacing: 15) {
            TextField("Ad Soyad", text: $registerNameSurname)
                .textContentType(.name)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            
            TextField("E-posta", text: $registerEmail)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .textInputAutocapitalization(.never)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            
            SecureField("Şifre", text: $registerPassword)
                .textContentType(.newPassword)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            
            SecureField("Şifre (Tekrar)", text: $registerConfirmPassword)
                .textContentType(.newPassword)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            
            TextField("Öğrenci Numarası", text: $registerStudentNumber)
                .keyboardType(.numberPad)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            
            TextField("Telefon Numarası", text: $registerPhone)
                .keyboardType(.phonePad)
                .textContentType(.telephoneNumber)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            
            Button(action: {
                registerUser()
            }) {
                Text("Kayıt Ol")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(isLoading || !isValidRegistration())
            
            if !isValidRegistration() && !registerPassword.isEmpty && !registerConfirmPassword.isEmpty {
                Text("Şifreler eşleşmiyor!")
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .padding(.horizontal, 30)
    }
    
    // Doğrulama işlevi
    private func isValidRegistration() -> Bool {
        return !registerEmail.isEmpty &&
               !registerPassword.isEmpty &&
               !registerNameSurname.isEmpty &&
               !registerStudentNumber.isEmpty &&
               registerPassword == registerConfirmPassword
    }
    
    // Email ve şifre ile giriş yapma
    private func loginWithEmailPassword() {
        isLoading = true
        errorMessage = nil
        
        APIService.shared.loginWithEmailPassword(email: loginEmail, password: loginPassword) { result in
            isLoading = false
            
            switch result {
            case .success(let user):
                // Kullanıcı başarıyla giriş yaptı
                self.currentUser = user
                modelContext.insert(user)
                
                // ✅ Oturum durumunu güncelle
                onAuthenticationChange?(true)
                
                // ✅ Kullanıcı bilgilerini UserDefaults'a kaydet
                self.saveUserToDefaults(user)
                
                // Kullanıcı bilgilerine göre yönlendirme yap
                if !user.department.isEmpty {
                    // Bölüm bilgisi varsa derslere yönlendir
                    shouldNavigateToCourses = true
                } else if let university = user.university, !university.isEmpty {
                    // Üniversite bilgisi var ama bölüm yoksa, bölüm seçimine yönlendir
                    shouldNavigateToDepartmentSelection = true
                } else {
                    // Üniversite bilgisi yoksa, üniversite seçimine yönlendir
                    shouldNavigateToUniversitySelection = true
                }
                
            case .failure(let error):
                errorMessage = "Giriş yapılamadı: \(error.localizedDescription)"
            }
        }
    }
    
    // Kayıt olma
    private func registerUser() {
        isLoading = true
        errorMessage = nil
        
        APIService.shared.registerUser(
            email: registerEmail,
            password: registerPassword,
            nameSurname: registerNameSurname,
            studentNumber: registerStudentNumber,
            phoneNumber: registerPhone
        ) { result in
            isLoading = false
            
            switch result {
            case .success(let success):
                if success {
                    // Kayıt başarılı, login ekranına geç
                    viewState = .login
                    loginEmail = registerEmail
                    loginPassword = registerPassword
                    
                    // Kayıt formunu temizle
                    registerEmail = ""
                    registerPassword = ""
                    registerConfirmPassword = ""
                    registerNameSurname = ""
                    registerStudentNumber = ""
                    registerPhone = ""
                    
                    errorMessage = "Kayıt başarılı! Lütfen giriş yapın."
                } else {
                    errorMessage = "Kayıt başarısız. Lütfen tekrar deneyin."
                }
                
            case .failure(let error):
                errorMessage = "Kayıt yapılamadı: \(error.localizedDescription)"
            }
        }
    }
    
    private func signInWithMicrosoft() {
        isLoading = true
        errorMessage = nil
        
        #if canImport(UIKit)
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
                // Microsoft ile giriş işlemini API ile gerçekleştir
                APIService.shared.loginWithMicrosoftAccount(userInfo: userInfo) { apiResult in // 'result' ismini 'apiResult' olarak değiştirdim
                    DispatchQueue.main.async { // API yanıtı sonrası UI güncellemesi için
                        switch apiResult {
                        case .success(let user):
                            // Kullanıcı modelini oluştur ve ekle
                            self.currentUser = user
                            modelContext.insert(user)

                            // ✅ Oturum durumunu güncelle
                            onAuthenticationChange?(true)
                            
                            // ✅ Kullanıcı bilgilerini UserDefaults'a kaydet
                            self.saveUserToDefaults(user)

                            // Kullanıcı bilgilerine göre yönlendirme yap
                            if !user.department.isEmpty {
                                // Bölüm bilgisi varsa derslere yönlendir
                                shouldNavigateToCourses = true
                            } else if let university = user.university, !university.isEmpty {
                                // Üniversite bilgisi var ama bölüm yoksa, bölüm seçimine yönlendir
                                shouldNavigateToDepartmentSelection = true
                            } else {
                                // Üniversite bilgisi yoksa, üniversite seçimine yönlendir
                                shouldNavigateToUniversitySelection = true
                            }

                        case .failure(let error):
                            errorMessage = "Giriş yapılamadı: \(error.localizedDescription)"
                        }
                    }
                }

            case .failure(let error):
                 DispatchQueue.main.async { // Hata mesajı UI'da gösterilecek
                    errorMessage = "Microsoft ile giriş yapılamadı: \(error.localizedDescription)"
                 }
            }
        }
        #else
        // UIKit olmayan platformlar için hata veya alternatif akış
        errorMessage = "Microsoft ile giriş bu platformda desteklenmiyor."
        isLoading = false
        #endif
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
            department: "Bilgisayar ",
            university: "Doğuş Üniversitesi"
        )
        
        // ModelContext'e ekle
        modelContext.insert(demoUser)
        
        // Örnek veriler oluştur
        createSampleData(for: demoUser)
        
        // Kullanıcıyı ayarla
        currentUser = demoUser
        
        // ✅ AppStorage'daki oturum durumu değişkenini güncelle
        onAuthenticationChange?(true)
        
        // ✅ Kullanıcı bilgilerini UserDefaults'a kaydet
        saveUserToDefaults(demoUser)
        UserDefaults.standard.set(true, forKey: "com.socialuniversity.isDemo")
        
        // Demo kullanıcı için bölüm ve üniversite bilgisi var, direkt derslere yönlendir
        shouldNavigateToCourses = true
        
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
                senderId: nil as String?,
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
                senderId: nil as String?,
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
    
    // ✅ Çıkış yapma fonksiyonu
    private func logout() {
        // UserDefaults'taki tüm kullanıcı bilgilerini temizle
        UserDefaults.standard.removeObject(forKey: "com.socialuniversity.userId")
        UserDefaults.standard.removeObject(forKey: "com.socialuniversity.userName")
        UserDefaults.standard.removeObject(forKey: "com.socialuniversity.userSurname")
        UserDefaults.standard.removeObject(forKey: "com.socialuniversity.userEmail")
        UserDefaults.standard.removeObject(forKey: "com.socialuniversity.userStudentNumber")
        UserDefaults.standard.removeObject(forKey: "com.socialuniversity.department")
        UserDefaults.standard.removeObject(forKey: "com.socialuniversity.university")
        UserDefaults.standard.removeObject(forKey: "com.socialuniversity.isDemo")
        
        // ✅ EN ÖNEMLİSİ: isAuthenticated'ı false yap
        UserDefaults.standard.set(false, forKey: "com.socialuniversity.isAuthenticated")
        
        // ✅ Oturum durumunu güncelle
        onAuthenticationChange?(false)
        
        // ✅ Kullanıcıyı temizle
        currentUser = nil
        
        // Giriş ekranına yönlendir
        viewState = .login
        
        print("✅ Kullanıcı çıkış yaptı, tüm veriler temizlendi")
        print("   - isAuthenticated: false")
    }
}

#Preview {
    LoginView { _ in }
        .modelContainer(AppSchema.modelContainer())
} 
