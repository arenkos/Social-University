import Foundation
import SwiftUI
import SwiftData

// Microsoft kimlik doğrulama için gerekli kütüphaneleri ekleyeceğiz
// Bu dosya Microsoft API ile kimlik doğrulama işlemlerini yönetecek

public class AuthService: ObservableObject {
    @Published public var isAuthenticated = false
    @Published public var currentUser: User?
    @Published public var errorMessage: String?
    @Published public var isLoading = false
    
    // Microsoft uygulama kimlik bilgileri
    private let clientId = "YOUR_MICROSOFT_CLIENT_ID" // Microsoft Azure Portal'dan alınacak
    private let redirectUri = "msauth.com.yourdomain.socialuniversity://auth" // Uygulamanız için tanımladığınız yönlendirme URI'si
    private let authority = "https://login.microsoftonline.com/common"
    private let scopes = ["User.Read", "User.ReadBasic.All"]
    
    // ModelContext referansı
    private var modelContext: ModelContext?
    
    public init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
    }
    
    // ModelContext'i güncellemek için fonksiyon
    public func updateModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    // Microsoft ile giriş işlemi
    public func signInWithMicrosoft() {
        isLoading = true
        errorMessage = nil
        
        MicrosoftAuthManager.shared.signIn { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let userInfo):
                    self.handleSuccessfulLogin(with: userInfo)
                case .failure(let error):
                    self.errorMessage = "Giriş sırasında hata oluştu: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // Başarılı giriş işlemini yönet
    private func handleSuccessfulLogin(with userInfo: MicrosoftAuthManager.UserInfo) {
        guard let modelContext = modelContext else {
            self.errorMessage = "Model context bulunamadı"
            return
        }
        
        // Kullanıcı zaten var mı kontrol et
        let userIdToFind = userInfo.id
        let descriptor = FetchDescriptor<User>(predicate: #Predicate<User> { user in
            user.id == userIdToFind
        })
        
        do {
            let existingUsers = try modelContext.fetch(descriptor)
            
            if existingUsers.isEmpty {
                // Yeni kullanıcı oluştur
                let newUser = User(
                    id: userInfo.id,
                    email: userInfo.email,
                    name: userInfo.name,
                    surname: userInfo.surname,
                    studentNumber: userInfo.studentNumber,
                    department: userInfo.department
                )
                
                modelContext.insert(newUser)
                self.currentUser = newUser
            } else if let existingUser = existingUsers.first {
                // Mevcut kullanıcıyı güncelle
                existingUser.email = userInfo.email
                existingUser.name = userInfo.name
                existingUser.surname = userInfo.surname
                existingUser.studentNumber = userInfo.studentNumber
                existingUser.department = userInfo.department
                
                self.currentUser = existingUser
            }
            
            self.isAuthenticated = true
        } catch {
            self.errorMessage = "Kullanıcı kontrolü sırasında hata: \(error.localizedDescription)"
        }
    }
    
    // Demo kullanıcı oluşturma ve giriş
    public func createDemoUserAndLogin() {
        isLoading = true
        errorMessage = nil
        
        // Demo kullanıcı bilgileri
        let userInfo = MicrosoftAuthManager.UserInfo(
            id: "demo1",
            email: "demo@university.edu.tr",
            name: "Demo",
            surname: "Kullanıcı",
            studentNumber: "123456",
            department: "Bilgisayar Mühendisliği"
        )
        
        // Giriş simülasyonu
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self = self else { return }
            
            self.isLoading = false
            self.handleSuccessfulLogin(with: userInfo)
        }
    }
    
    // Microsoft ile çıkış işlemi
    public func signOut() {
        isLoading = true
        
        MicrosoftAuthManager.shared.signOut { [weak self] success in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if success {
                    self.currentUser = nil
                    self.isAuthenticated = false
                } else {
                    self.errorMessage = "Çıkış yapılırken bir hata oluştu"
                }
            }
        }
    }
    
    // Microsoft API'den kullanıcı bilgilerini alma
    public func fetchUserProfile() {
        // MSAL kütüphanesi entegre edildiğinde burada Microsoft Graph API'den kullanıcı bilgileri alınacak
        // Şimdilik demo kullanıcı bilgilerini kullanıyoruz
    }
} 