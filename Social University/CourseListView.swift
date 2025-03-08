//
//  CourseListView.swift
//  Social University
//
//  Created by Aren Koş on 8.03.2025.
//

import SwiftUI
import SwiftData

// AppCore.swift dosyasını import ediyoruz
// @_exported import struct Social_University.User
// @_exported import struct Social_University.Course
// @_exported import struct Social_University.Message

struct CourseListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var courses: [Course]
    
    var user: User
    @State private var searchText = ""
    @State private var selectedDepartment: String?
    // Sabit bölüm listesi - API'den çekmek yerine burada statik olarak tanımlıyoruz
    @State private var departments: [String] = [
        "Adalet",
        "Aşçılık",
        "Bankacılık ve Sigortacılık",
        "Bilgisayar Mühendisliği",
        "Bilgisayar Programcılığı",
        "Bilişim Güvenliği Teknolojisi",
        "Çocuk Gelişimi",
        "Dış Ticaret",
        "Dijital Oyun Tasarımı",
        "Ekonomi",
        "Elektrik",
        "Elektrik-Elektronik Mühendisliği",
        "Elektronik Teknolojisi",
        "Endüstri Mühendisliği",
        "Fotoğrafçılık ve Kameramanlık",
        "Gastronomi ve Mutfak Sanatları",
        "Görsel İletişim Tasarımı",
        "Grafik",
        "Grafik Tasarımı",
        "Halkla İlişkiler ve Tanıtım",
        "Hukuk",
        "İç Mimarlık",
        "İletişim Tasarımı",
        "İngiliz Dili ve Edebiyatı",
        "İnsan Kaynakları Yönetimi",
        "İnşaat Mühendisliği",
        "İnşaat Teknolojisi",
        "İş Sağlığı ve Güvenliği",
        "İşletme (İngilizce)",
        "İşletme (Türkçe)",
        "Lojistik",
        "Makine",
        "Makine Mühendisliği",
        "Matematik",
        "Mekatronik",
        "Mimari Restorasyon",
        "Mimarlık",
        "Moda Tasarımı",
        "Mütercim-Tercümanlık",
        "Otomotiv Teknolojisi",
        "Psikoloji (İngilizce)",
        "Psikoloji (Türkçe)",
        "Radyo ve Televizyon Programcılığı",
        "Sivil Hava Ulaştırma İşletmeciliği",
        "Sivil Havacılık Kabin Hizmetleri",
        "Spor Yönetimi",
        "Türk Dili ve Edebiyatı",
        "Turizm ve Otel İşletmeciliği",
        "Uçak Teknolojisi",
        "Uluslararası İlişkiler",
        "Uluslararası Ticaret ve İşletmecilik",
        "Uygulamalı İngilizce ve Çevirmenlik",
        "Yazılım Mühendisliği",
        "Yönetim Bilişim Sistemleri"
    ]
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingLogoutAlert = false
    
    // Uygulama genelinde oturum durumunu takip eden değişkenlere erişim
    @AppStorage("com.socialuniversity.isAuthenticated") private var isAuthenticated = false
    
    // UniversitySelectionView'dan seçilen değerlere erişim
    @AppStorage("selectedUniversity") private var selectedUniversity = ""
    @AppStorage("selectedDepartment") private var savedDepartment = ""
    
    // Oturum durumunu güncelleyebilmek için Environment değişkeni
    @Environment(\.presentationMode) private var presentationMode
    
    // Çıkış yapıldığında giriş sayfasına dönmek için
    @State private var shouldNavigateToLogin = false
    
    var filteredCourses: [Course] {
        courses.filter { course in
            let matchesSearch = searchText.isEmpty || 
                course.courseName.localizedCaseInsensitiveContains(searchText) ||
                course.courseCode.localizedCaseInsensitiveContains(searchText)
            
            let matchesDepartment = selectedDepartment == nil || 
                course.departmentName == selectedDepartment
            
            return matchesSearch && matchesDepartment
        }
    }
    
    var body: some View {
        VStack {
            // Arama ve filtreleme
            VStack(spacing: 10) {
                TextField("Ders ara...", text: $searchText)
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                
                /*
                if !departments.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            Button(action: {
                                selectedDepartment = nil
                            }) {
                                Text("Tümü")
                                    .padding(.vertical, 5)
                                    .padding(.horizontal, 10)
                                    .background(selectedDepartment == nil ? Color.blue : Color.gray.opacity(0.2))
                                    .foregroundColor(selectedDepartment == nil ? .white : .primary)
                                    .cornerRadius(15)
                            }
                            
                            ForEach(departments, id: \.self) { department in
                                Button(action: {
                                    selectedDepartment = department
                                }) {
                                    Text(department)
                                        .padding(.vertical, 5)
                                        .padding(.horizontal, 10)
                                        .background(selectedDepartment == department ? Color.blue : Color.gray.opacity(0.2))
                                        .foregroundColor(selectedDepartment == department ? .white : .primary)
                                        .cornerRadius(15)
                                }
                            }
                        }
                    }
                }
                */
            }
            .padding()
            
            // Seçilen üniversite ve bölüm bilgisi gösterimi
            if !selectedUniversity.isEmpty {
                HStack {
                    Text("Üniversite: \(selectedUniversity)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if !savedDepartment.isEmpty {
                        Text("Bölüm: \(savedDepartment)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            
            if isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else if let errorMessage = errorMessage {
                Spacer()
                Text(errorMessage)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Button("Yeniden Dene") {
                    loadCourses()
                }
                .padding()
                Spacer()
            } else if filteredCourses.isEmpty {
                Spacer()
                Text(searchText.isEmpty && selectedDepartment == nil ? "Henüz ders yok" : "Arama kriterlerine uygun ders bulunamadı")
                    .foregroundColor(.gray)
                Spacer()
            } else {
                List {
                    ForEach(filteredCourses) { course in
                        NavigationLink(destination: ChatView(user: user, course: course)) {
                            CourseRow(course: course, isEnrolled: isEnrolled(course: course))
                        }
                        .swipeActions {
                            if isEnrolled(course: course) {
                                Button(role: .destructive) {
                                    unenrollCourse(course: course)
                                } label: {
                                    Label("Ayrıl", systemImage: "person.fill.xmark")
                                }
                            } else {
                                Button {
                                    enrollCourse(course: course)
                                } label: {
                                    Label("Katıl", systemImage: "person.fill.badge.plus")
                                }
                                .tint(.green)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Dersler")
        .navigationBarBackButtonHidden(true) // Geri dönüş butonunu gizle
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingLogoutAlert = true
                }) {
                    Text("Çıkış Yap")
                        .foregroundColor(.red)
                }
            }
        }
        .alert("Çıkış yapmak istiyor musunuz?", isPresented: $showingLogoutAlert) {
            Button("İptal", role: .cancel) {}
            Button("Çıkış Yap", role: .destructive) {
                signOut()
            }
        } message: {
            Text("Çıkış yaptığınızda oturumunuz sonlandırılacak ve giriş sayfasına yönlendirileceksiniz.")
        }
        .onAppear {
            // UniversitySelectionView'dan seçilen bölüm varsa, bunu seçili bölüm olarak ayarla
            if !savedDepartment.isEmpty {
                selectedDepartment = savedDepartment
            }
            
            loadCourses()
        }
        .refreshable {
            loadCourses()
        }
        // NavigationStack'in kökünde bulunan login sayfasına dön
        .onChange(of: shouldNavigateToLogin) { _, newValue in
            if newValue {
                #if canImport(UIKit)
                if #available(iOS 15.0, *) {
                    // iOS 15 ve üzeri için güncel yöntem
                    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
                        return
                    }
                    
                    if let rootViewController = windowScene.keyWindow?.rootViewController {
                        // Ana ekrana dönmek için NavigationStack'i temizle
                        if let navigationController = rootViewController as? UINavigationController {
                            navigationController.popToRootViewController(animated: true)
                        } else {
                            // NavigationStack yoksa mevcut görünümleri kapat
                            rootViewController.dismiss(animated: true)
                        }
                    }
                } else {
                    // iOS 15 öncesi için eski yöntem (kullanımdan kaldırıldı)
                    if let window = UIApplication.shared.windows.first,
                       let rootViewController = window.rootViewController {
                        // Ana ekrana dönmek için NavigationStack'i temizle
                        if let navigationController = rootViewController as? UINavigationController {
                            navigationController.popToRootViewController(animated: true)
                        } else {
                            // NavigationStack yoksa mevcut görünümleri kapat
                            rootViewController.dismiss(animated: true)
                        }
                    }
                }
                #endif
            }
        }
    }
    
    private func loadCourses() {
        isLoading = true
        errorMessage = nil
        
        // Seçilen bölüm bilgisini API çağrısına ekle
        APIService.shared.getCourses(
            studentId: user.studentNumber,
            search: searchText.isEmpty ? nil : searchText,
            department: selectedDepartment
        ) { result in
            isLoading = false
            
            switch result {
            case .success(let (fetchedCourses, fetchedDepartments)):
                // Mevcut dersleri temizle
                for course in courses {
                    modelContext.delete(course)
                }
                
                // Yeni dersleri ekle
                for course in fetchedCourses {
                    modelContext.insert(course)
                }
                
                // Bölüm listesini güncelle (eğer API'den bölüm listesi geliyorsa)
                if !fetchedDepartments.isEmpty {
                    self.departments = fetchedDepartments
                }
                
                // Eğer seçili bölüm artık mevcut değilse, seçimi temizle
                if let selectedDepartment = selectedDepartment, !departments.contains(selectedDepartment) {
                    self.selectedDepartment = nil
                }
                
            case .failure(let error):
                errorMessage = "Dersler yüklenemedi: \(error.localizedDescription)"
            }
        }
    }
    
    private func isEnrolled(course: Course) -> Bool {
        // API'den gelen bilgiye göre derse kayıtlı olup olmadığını kontrol et
        // Bu bilgi course nesnesinde saklanabilir
        return course.isEnrolled ?? false
    }
    
    private func enrollCourse(course: Course) {
        isLoading = true
        errorMessage = nil
        
        APIService.shared.enrollCourse(studentId: user.studentNumber, courseCode: course.courseCode, action: "enroll") { result in
            isLoading = false
            
            switch result {
            case .success:
                // Dersleri yeniden yükle
                loadCourses()
                
            case .failure(let error):
                errorMessage = "Derse katılınamadı: \(error.localizedDescription)"
            }
        }
    }
    
    private func unenrollCourse(course: Course) {
        isLoading = true
        errorMessage = nil
        
        APIService.shared.enrollCourse(studentId: user.studentNumber, courseCode: course.courseCode, action: "unenroll") { result in
            isLoading = false
            
            switch result {
            case .success:
                // Dersleri yeniden yükle
                loadCourses()
                
            case .failure(let error):
                errorMessage = "Dersten ayrılınamadı: \(error.localizedDescription)"
            }
        }
    }
    
    private func signOut() {
        isLoading = true
        
        // Microsoft ile giriş yapmış kullanıcılar için Microsoft çıkış işlemi
        // Demo kullanıcılar için doğrudan UserDefaults güncellemesi
        MicrosoftAuthManager.shared.signOut { success in
            self.isLoading = false
            
            // Tüm verileri temizle ve giriş ekranına dön
            DispatchQueue.main.async {
                // Tüm kullanıcı bilgilerini temizle
                UserDefaults.standard.removeObject(forKey: "selectedUniversity")
                UserDefaults.standard.removeObject(forKey: "selectedDepartment")
                UserDefaults.standard.removeObject(forKey: "com.socialuniversity.userId")
                UserDefaults.standard.removeObject(forKey: "com.socialuniversity.userName")
                UserDefaults.standard.removeObject(forKey: "com.socialuniversity.userSurname")
                UserDefaults.standard.removeObject(forKey: "com.socialuniversity.userEmail")
                UserDefaults.standard.removeObject(forKey: "com.socialuniversity.userStudentNumber")
                UserDefaults.standard.removeObject(forKey: "com.socialuniversity.userDepartment")
                UserDefaults.standard.removeObject(forKey: "com.socialuniversity.isDemo")
                UserDefaults.standard.removeObject(forKey: "com.socialuniversity.userInfo")
                
                // Değişiklikleri hemen kaydet ve yayınla
                UserDefaults.standard.synchronize()
                
                // Giriş durumunu false olarak ayarla - bu @AppStorage bağlı olduğundan Social_UniversityApp'i tetikleyecek
                self.isAuthenticated = false
                
                // NotificationCenter aracılığıyla uygulama genelinde bildirim yayınla
                NotificationCenter.default.post(name: NSNotification.Name("LogoutNotification"), object: nil)
                
                print("Çıkış yapıldı, login sayfasına yönlendiriliyor...")
            }
        }
    }
}

struct CourseRow: View {
    let course: Course
    let isEnrolled: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(course.courseCode)
                    .font(.headline)
                
                Spacer()
                
                if isEnrolled {
                    Text("Kayıtlı")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            
            Text(course.courseName)
                .font(.subheadline)
            
            Text(course.departmentName)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    VStack {
        Text("Preview için CourseListView")
            .font(.headline)
        
        Text("Gerçek bir önizleme için Xcode'da projeyi çalıştırın")
            .font(.subheadline)
            .foregroundColor(.secondary)
    }
    .padding()
} 
