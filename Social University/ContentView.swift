import SwiftUI
import SwiftData
import Foundation

struct ContentView: View {
    // ✅ App'ten geçilen authentication state'i
    @Binding var isAuthenticated: Bool
    
    // Yönlendirme durumlarını izle
    @State private var isShowingLoginView = false
    @State private var isShowingUniversitySelection = false
    @State private var isShowingCourseList = false
    
    // UserDefaults için anahtarlar
    private let universityKey = "com.socialuniversity.university"
    private let departmentKey = "com.socialuniversity.department"
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "graduationcap.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .foregroundColor(.blue)
                
                Text("Social University")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Üniversite öğrencileri için sosyal platform")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .onAppear {
                // Hoş geldiniz ekranını 2 saniye göster, sonra uygun ekrana yönlendir
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    determineDestination()
                }
            }
            // Navigasyon yönlendirmeleri
            .navigationDestination(isPresented: $isShowingLoginView) {
                LoginView { newAuthState in
                    isAuthenticated = newAuthState
                }
            }
            .navigationDestination(isPresented: $isShowingUniversitySelection) {
                UniversitySelectionView(user: createDefaultUser())
            }
            .navigationDestination(isPresented: $isShowingCourseList) {
                CourseListView(user: createDefaultUser())
            }
        }
    }
    
    // ✅ Uygun yönlendirmeyi belirle
    private func determineDestination() {
        let userDefaults_isAuthenticated = UserDefaults.standard.bool(forKey: "com.socialuniversity.isAuthenticated")
        let userDefaults_userId = UserDefaults.standard.string(forKey: "com.socialuniversity.userId") ?? "yok"
        
        print("📱 ContentView determineDestination:")
        print("   - @Binding isAuthenticated: \(isAuthenticated)")
        print("   - UserDefaults isAuthenticated: \(userDefaults_isAuthenticated)")
        print("   - UserDefaults userId: \(userDefaults_userId)")
        
        if !isAuthenticated {
            // Giriş yapılmamış, login ekranına yönlendir
            print("📱 Kullanıcı doğrulanmamış, login ekranına yönlendiriliyor")
            isShowingLoginView = true
            return
        }
        
        // Kullanıcı doğrulanmış, bilgilerini kontrol et
        let university = UserDefaults.standard.string(forKey: universityKey) ?? ""
        let department = UserDefaults.standard.string(forKey: departmentKey) ?? ""
        
        print("📱 Kullanıcı doğrulanmış:")
        print("   - University: '\(university)'")
        print("   - Department: '\(department)'")
        
        // Yönlendirme öncesi tüm sayfaları kapat
        isShowingLoginView = false
        isShowingUniversitySelection = false
        isShowingCourseList = false
        
        // Kullanıcı bilgilerine göre yönlendirme
        if !university.isEmpty && !department.isEmpty {
            // Hem üniversite hem bölüm bilgisi var, derslere git
            print("📱 Hem üniversite hem bölüm var, derslere yönlendiriliyor")
            isShowingCourseList = true
        } else {
            // Üniversite veya bölüm eksik, üniversite seçimine git
            print("📱 Üniversite/bölüm eksik, üniversite seçimine yönlendiriliyor")
            isShowingUniversitySelection = true
        }
    }
    
    // ✅ UserDefaults'tan gerçek kullanıcı bilgilerini yükle
    private func createDefaultUser() -> User {
        let userId = UserDefaults.standard.string(forKey: "com.socialuniversity.userId") ?? "unknown"
        let userEmail = UserDefaults.standard.string(forKey: "com.socialuniversity.userEmail") ?? "unknown@example.com"
        let userName = UserDefaults.standard.string(forKey: "com.socialuniversity.userName") ?? "Bilinmeyen"
        let userSurname = UserDefaults.standard.string(forKey: "com.socialuniversity.userSurname") ?? "Kullanıcı"
        let userStudentNumber = UserDefaults.standard.string(forKey: "com.socialuniversity.userStudentNumber") ?? "000000"
        let userDepartment = UserDefaults.standard.string(forKey: "com.socialuniversity.department") ?? ""
        let userUniversity = UserDefaults.standard.string(forKey: "com.socialuniversity.university") ?? ""
        
        print("📱 ContentView - UserDefaults'tan kullanıcı bilgileri yüklendi:")
        print("   - ID: \(userId)")
        print("   - Email: \(userEmail)")
        print("   - University: \(userUniversity)")
        print("   - Department: \(userDepartment)")
        
        return User(
            id: userId,
            email: userEmail,
            name: userName,
            surname: userSurname,
            studentNumber: userStudentNumber,
            department: userDepartment,
            university: userUniversity
        )
    }
}

#Preview {
    ContentView(isAuthenticated: .constant(false))
        .modelContainer(AppSchema.modelContainer())
}
