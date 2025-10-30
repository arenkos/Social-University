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
    @State private var departments: [String] = []
    @State private var isLoading = false
    @State private var errorMessage: String? = nil // Eski hata mesajı (String)
    @State private var alertMessage: AlertMessage? = nil // Yeni hata mesajı (Identifiable)
    @State private var showingLogoutAlert = false
    
    // Seçili sekme
    @State private var selectedTab = 0 // 0: Tüm Dersler, 1: Katıldığım Dersler
    
    // Uygulama genelinde oturum durumunu takip eden değişkenler
    @AppStorage("com.socialuniversity.isAuthenticated") private var isAuthenticated = false
    
    // Önbellek için değişkenler
    @State private var cachedCourses: [Course] = []
    @State private var cachedDepartments: [String] = []
    @State private var lastCacheUpdate: Date? = nil
    private let cacheDuration: TimeInterval = 3600
    @State private var isOfflineMode = false
    
    // İşlem yapılan ders ID'sini ve işlem durumunu tutacak değişkenler
    @State private var processingCourseId: String? = nil
    @State private var isProcessingEnrollment = false
    
    // UserDefaults anahtarları
    private let kCachedCoursesKey = "com.socialuniversity.cachedCourses"
    private let kCachedDepartmentsKey = "com.socialuniversity.cachedDepartments"
    private let kLastCacheUpdateKey = "com.socialuniversity.lastCacheUpdate"
    
    // UniversitySelectionView'dan seçilen değerlere erişim
    @AppStorage("selectedUniversity") private var selectedUniversity = ""
    @AppStorage("selectedDepartment") private var savedDepartment = ""
    
    @Environment(\.presentationMode) private var presentationMode
    @State private var shouldNavigateToLogin = false
    @State private var isLoadingDepartments = false
    
    // Hatalar için identifiable yapı
    struct AlertMessage: Identifiable {
        let id = UUID()
        let message: String
    }
    
    // Tüm ders listeleri için filtreleme
    var filteredCourses: [Course] {
        let trimmedSearchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Önbellekteki verileri kullan, yoksa courses kullan
        let sourceCourses = !cachedCourses.isEmpty ? cachedCourses : courses
        
        // ID'si üzerinden tekrarları temizle
        let uniqueCourses = Array(Dictionary(grouping: sourceCourses) { $0.id }.values.map { $0.first! })
        
        // Filtreleme işlemi
        let filteredResults = uniqueCourses.filter { course in
            // Eğer "Katıldığım Dersler" sekmesindeyse, sadece kayıtlı olduğum dersleri göster
            let matchesEnrollment = selectedTab == 0 || (selectedTab == 1 && course.isEnrolled == true)
            
            // Arama filtresi - Basit içerip içermeme kontrolü
            let matchesSearch: Bool
            if trimmedSearchText.isEmpty {
                matchesSearch = true
            } else {
                // Arama kelimelerini böl
                let searchTerms = trimmedSearchText.lowercased().split(separator: " ")
                
                // Ders bilgileri
                let courseInfo = "\(course.courseName) \(course.courseCode) \(course.departmentName)".lowercased()
                
                // Arama terimlerinin HEPSİ ders bilgilerinde geçiyor mu?
                matchesSearch = searchTerms.allSatisfy { searchTerm in
                    courseInfo.contains(searchTerm)
                }
            }
            
            // Bölüm filtresi
            let matchesDepartment = selectedDepartment == nil || course.departmentName == selectedDepartment
            
            return matchesEnrollment && matchesSearch && matchesDepartment
        }
        
        // Ders adına göre alfabetik sıralama
        return filteredResults.sorted { $0.courseName.localizedCaseInsensitiveCompare($1.courseName) == .orderedAscending }
    }
    
    var body: some View {
        VStack {
            // Arama ve filtreleme
            VStack(spacing: 10) {
                TextField("Ders ara...", text: $searchText)
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
            .padding()
            
            // Seçilen üniversite ve bölüm bilgisi gösterimi
            HStack(spacing: 8) {
                if let university = user.university, !university.isEmpty {
                    HStack {
                        Text("Üniversite: \(university)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                } else if !selectedUniversity.isEmpty {
                    HStack {
                        Text("Üniversite: \(selectedUniversity)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                }
                Spacer()
                if !user.department.isEmpty {
                    HStack {
                        Text("Bölüm: \(user.department)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                } else if !savedDepartment.isEmpty {
                    HStack {
                        Text("Bölüm: \(savedDepartment)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            // Sekme seçimi
            Picker("Dersler", selection: $selectedTab) {
                Text("Tüm Dersler").tag(0)
                Text("Katıldığım Dersler").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            // Çevrimdışı mod uyarısı
            if isOfflineMode {
                HStack {
                    Image(systemName: "wifi.slash")
                        .foregroundColor(.orange)
                    
                    Text("Çevrimdışı mod - Veriler önbellekten yüklendi")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    Spacer()
                    
                    Button(action: {
                        loadCourses(forceRefresh: true) // Yeniden bağlantı denemesi
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.blue)
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
                Text(selectedTab == 0 
                     ? (searchText.isEmpty && selectedDepartment == nil ? "Henüz ders yok" : "Arama kriterlerine uygun ders bulunamadı")
                     : "Henüz bir derse katılmadınız")
                    .foregroundColor(.gray)
                Spacer()
            } else {
                List {
                    ForEach(filteredCourses) { course in
                        NavigationLink(destination: ChatView(user: user, course: course)) {
                            CourseRow(course: course, isEnrolled: course.isEnrolled ?? false)
                        }
                        .swipeActions {
                            if course.isEnrolled ?? false {
                                Button(role: .destructive) {
                                    unenrollCourse(course: course)
                                } label: {
                                    if processingCourseId == course.id && isProcessingEnrollment {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Label("Ayrıl", systemImage: "person.fill.xmark")
                                    }
                                }
                                .disabled(processingCourseId != nil)
                            } else {
                                Button {
                                    enrollCourse(course: course)
                                } label: {
                                    if processingCourseId == course.id && isProcessingEnrollment {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Label("Katıl", systemImage: "person.fill.badge.plus")
                                    }
                                }
                                .tint(.green)
                                .disabled(processingCourseId != nil)
                            }
                        }
                        .alert(item: $alertMessage) { alertMessage in
                            Alert(
                                title: Text("Hata"),
                                message: Text(alertMessage.message),
                                dismissButton: .default(Text("Tamam"))
                            )
                        }
                    }
                }
            }
        }
        .navigationTitle("Dersler")
        .navigationBarBackButtonHidden(true)
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
            // Varsayılan değerleri User modelinden al
            if let userUniversity = user.university, !userUniversity.isEmpty {
                selectedUniversity = userUniversity
            }
            
            if !user.department.isEmpty {
                selectedDepartment = user.department
            } else if !savedDepartment.isEmpty {
                selectedDepartment = savedDepartment
            }
            
            // UserDefaults'tan önbellekteki verileri yükle
            loadCachedDataFromUserDefaults()
            
            // Eğer üniversite seçilmişse ve henüz yüklenmemişse, dersleri yükle
            if !selectedUniversity.isEmpty || (user.university != nil && !user.university!.isEmpty) {
                loadCourses()
            } else if !cachedCourses.isEmpty {
                // Üniversite seçili değil ama cache var ise en azından listeyi göster
                self.isOfflineMode = true
            }
        }
        .refreshable {
            loadCourses()
        }
        // Üniversite değiştiğinde dersleri yükle
        .onChange(of: selectedUniversity) { oldValue, newValue in
            if !newValue.isEmpty {
                // Yeni üniversite seçildiğinde önbelleği temizle ve dersleri yeniden yükle
                if oldValue != newValue {
                    cachedCourses = []
                    cachedDepartments = []
                    lastCacheUpdate = nil
                    selectedDepartment = nil
                    // UserDefaults'tan kaydedilmiş bölümü temizle
                    UserDefaults.standard.removeObject(forKey: "selectedDepartment")
                }
                loadCourses()
            }
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
    
    // UserDefaults'tan önbelleklenmiş verileri yükleme
    private func loadCachedDataFromUserDefaults() {
        if let courseData = UserDefaults.standard.data(forKey: kCachedCoursesKey),
           let courses = try? JSONDecoder().decode([Course].self, from: courseData) {
            self.cachedCourses = courses
            print("Önbellekten \(courses.count) ders yüklendi")
        }
        
        if let departmentsData = UserDefaults.standard.data(forKey: kCachedDepartmentsKey),
           let departments = try? JSONDecoder().decode([String].self, from: departmentsData) {
            self.cachedDepartments = departments
            self.departments = departments
            print("Önbellekten \(departments.count) bölüm yüklendi")
        }
        
        if let lastUpdateDate = UserDefaults.standard.object(forKey: kLastCacheUpdateKey) as? Date {
            self.lastCacheUpdate = lastUpdateDate
        }
    }
    
    // Önbellekteki verileri UserDefaults'a kaydetme
    private func saveCachedDataToUserDefaults() {
        if !cachedCourses.isEmpty {
            if let courseData = try? JSONEncoder().encode(cachedCourses) {
                UserDefaults.standard.set(courseData, forKey: kCachedCoursesKey)
                print("Dersler önbelleğe kaydedildi")
            }
        }
        
        if !cachedDepartments.isEmpty {
            if let departmentsData = try? JSONEncoder().encode(cachedDepartments) {
                UserDefaults.standard.set(departmentsData, forKey: kCachedDepartmentsKey)
                print("Bölümler önbelleğe kaydedildi")
            }
        }
        
        if let lastUpdate = lastCacheUpdate {
            UserDefaults.standard.set(lastUpdate, forKey: kLastCacheUpdateKey)
        }
        
        UserDefaults.standard.synchronize()
    }
    
    private func loadCourses(forceRefresh: Bool = false) {
        // Zaten yükleme yapılıyorsa çık
        if isLoading { return }

        // Eğer üniversite seçilmemişse ve User modelinde de üniversite belirtilmemişse, sessizce çık
        let effectiveUniversity = selectedUniversity.isEmpty ? (user.university ?? "") : selectedUniversity
        if effectiveUniversity.isEmpty { return }

        // Internet bağlantısını kontrol et
        let isConnected = checkInternetConnection()

        // Önbellekteki verinin geçerli olduğunu kontrol et
        let cacheValid = (lastCacheUpdate != nil) && (Date().timeIntervalSince(lastCacheUpdate!) < cacheDuration)

        // Önbellek geçerliyse ve zorla yenileme istenmiyorsa, önbellekteki veriyi kullan
        if !forceRefresh && cacheValid {
            if !cachedDepartments.isEmpty {
                departments = cachedDepartments
            }
            return
        }

        // İnternet bağlantısı yoksa ve önbellekte hiç veri yoksa uyarı göster
        if !isConnected && cachedCourses.isEmpty {
            self.showError("İnternet bağlantısı yok ve önbellekte veri bulunamadı")
            self.isOfflineMode = true
            return
        }

        // İnternet varsa sunucudan yükle, yoksa önbelleği kullan
        if isConnected {
            isLoading = true
            errorMessage = nil
            isOfflineMode = false

            let trimmedSearchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

            APIService.shared.getCourses(
                studentId: user.studentNumber,
                search: trimmedSearchText.isEmpty ? nil : trimmedSearchText,
                department: selectedDepartment,
                university: effectiveUniversity.isEmpty ? nil : effectiveUniversity
            ) { result in
                DispatchQueue.main.async {
                    self.isLoading = false

                    switch result {
                    case .success(let (fetchedCourses, fetchedDepartments)):
                        // Tekrarlanan dersleri temizle (id bazlı unique)
                        let uniqueCourses = Array(Dictionary(grouping: fetchedCourses) { $0.id }.values.compactMap { $0.first })

                        // SwiftData güncellemesi güvenli blok (varsa)
                        // Tam sil-yükle yerine upsert/diff uygula
                        do {
                            // Mevcut Course kayıtlarını çekmeye çalış
                            let descriptor = FetchDescriptor<Course>()
                            let existingCourses = try? modelContext.fetch(descriptor) ?? []

                            // Index by id
                            var existingById: [String: Course] = [:]
                            existingCourses?.forEach { existingById[$0.id] = $0 }

                            // Upsert
                            for newCourse in uniqueCourses {
                                if let existing = existingById[newCourse.id] {
                                    // Güncelle
                                    existing.courseCode = newCourse.courseCode
                                    existing.courseName = newCourse.courseName
                                    existing.departmentName = newCourse.departmentName
                                    existing.isEnrolled = newCourse.isEnrolled
                                } else {
                                    // Ekle
                                    self.modelContext.insert(newCourse)
                                }
                            }

                            // Silinecekler (sunucuda yoksa)
                            let incomingIds = Set(uniqueCourses.map { $0.id })
                            existingCourses?.forEach { existing in
                                if !incomingIds.contains(existing.id) {
                                    try? self.modelContext.delete(existing)
                                }
                            }
                        }

                        // Önbelleğe al ve kalıcı kaydet
                        self.cachedCourses = uniqueCourses
                        self.cachedDepartments = fetchedDepartments
                        self.lastCacheUpdate = Date()
                        self.saveCachedDataToUserDefaults()

                        // Bölüm listesini güncelle
                        if !fetchedDepartments.isEmpty {
                            self.departments = fetchedDepartments
                            if let selectedDepartment = self.selectedDepartment, !fetchedDepartments.contains(selectedDepartment) {
                                self.selectedDepartment = nil
                            }
                        }

                    case .failure(let error):
                        // Hata durumunda önbelleği kullan
                        if !self.cachedCourses.isEmpty {
                            self.isOfflineMode = true
                            self.showError("Sunucuya erişilemiyor, önbellekteki veriler gösteriliyor")
                        } else {
                            self.showError("Dersler yüklenemedi: \(error.localizedDescription)")
                        }
                    }
                }
            }
        } else {
            // İnternet yok ve önbellekte veri var
            isOfflineMode = true
        }
    }
    
    // İnternet bağlantısı kontrolü yapan yardımcı fonksiyon
    private func checkInternetConnection() -> Bool {
        // Basit bir kontrol - gerçek uygulamada daha kapsamlı kontrol mekanizmaları kullanılmalı
        // Bu örnekte varsayılan olarak bağlantı var kabul ediyoruz
        return true
    }
    
    private func isEnrolled(course: Course) -> Bool {
        return course.isEnrolled ?? false
    }
    
    private func enrollCourse(course: Course) {
        // Sadece ilgili butonun durumunu göster
        processingCourseId = course.id
        isProcessingEnrollment = true
        errorMessage = nil
        
        APIService.shared.enrollCourse(studentId: user.studentNumber, courseCode: course.courseCode, action: "enroll") { result in
            DispatchQueue.main.async {
                // İşlem tamamlandığında yükleme durumunu kapat
                self.processingCourseId = nil
                self.isProcessingEnrollment = false
                
                switch result {
                case .success:
                    // Sadece ilgili dersin durumunu güncelle
                    // Önbellekteki dersi güncelle
                    if let index = self.cachedCourses.firstIndex(where: { $0.id == course.id }) {
                        self.cachedCourses[index].isEnrolled = true
                    }
                    
                    // SwiftData'da dersi güncelle (güvenli)
                    if let descriptor = try? FetchDescriptor<Course>(predicate: #Predicate { $0.id == course.id }),
                       let match = try? self.modelContext.fetch(descriptor).first {
                        match.isEnrolled = true
                    }
                    
                case .failure(let error):
                    self.showError("Derse katılınamadı: \(error.localizedDescription)")
                    
                    // Hata ayrıntılarını yazdır
                    print("Derse katılma hatası: \(error)")
                    if let nsError = error as NSError? {
                        print("NSError ayrıntıları: \(nsError.domain), \(nsError.code), \(nsError.userInfo)")
                    }
                }
            }
        }
    }
    
    private func unenrollCourse(course: Course) {
        // Sadece ilgili butonun durumunu göster
        processingCourseId = course.id
        isProcessingEnrollment = true
        errorMessage = nil
        
        APIService.shared.enrollCourse(studentId: user.studentNumber, courseCode: course.courseCode, action: "unenroll") { result in
            DispatchQueue.main.async {
                // İşlem tamamlandığında yükleme durumunu kapat
                self.processingCourseId = nil
                self.isProcessingEnrollment = false
                
                switch result {
                case .success:
                    // Sadece ilgili dersin durumunu güncelle                    
                    // Önbellekteki dersi güncelle
                    if let index = self.cachedCourses.firstIndex(where: { $0.id == course.id }) {
                        self.cachedCourses[index].isEnrolled = false
                    }
                    
                    // SwiftData'da dersi güncelle (güvenli)
                    if let descriptor = try? FetchDescriptor<Course>(predicate: #Predicate { $0.id == course.id }),
                       let match = try? self.modelContext.fetch(descriptor).first {
                        match.isEnrolled = false
                    }
                    
                case .failure(let error):
                    self.showError("Dersten ayrılınamadı: \(error.localizedDescription)")
                    
                    // Hata ayrıntılarını yazdır
                    print("Dersten ayrılma hatası: \(error)")
                    if let nsError = error as NSError? {
                        print("NSError ayrıntıları: \(nsError.domain), \(nsError.code), \(nsError.userInfo)")
                    }
                }
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
                
                // UserDefaults'taki tüm kullanıcı bilgilerini temizle
                UserDefaults.standard.removeObject(forKey: "com.socialuniversity.userId")
                UserDefaults.standard.removeObject(forKey: "com.socialuniversity.userName")
                UserDefaults.standard.removeObject(forKey: "com.socialuniversity.userSurname")
                UserDefaults.standard.removeObject(forKey: "com.socialuniversity.userEmail")
                UserDefaults.standard.removeObject(forKey: "com.socialuniversity.userStudentNumber")
                UserDefaults.standard.removeObject(forKey: "com.socialuniversity.userDepartment")
                UserDefaults.standard.removeObject(forKey: "com.socialuniversity.userUniversity")
                UserDefaults.standard.removeObject(forKey: "com.socialuniversity.isDemo")
                
                // Önbellek verilerini de temizle
                UserDefaults.standard.removeObject(forKey: self.kCachedCoursesKey)
                UserDefaults.standard.removeObject(forKey: self.kCachedDepartmentsKey)
                UserDefaults.standard.removeObject(forKey: self.kLastCacheUpdateKey)
                
                // Değişiklikleri hemen kaydet ve yayınla
                UserDefaults.standard.synchronize()
                
                // Önbelleği temizle
                self.cachedCourses = []
                self.cachedDepartments = []
                self.lastCacheUpdate = nil
                
                // Giriş durumunu false olarak ayarla - bu @AppStorage bağlı olduğundan Social_UniversityApp'i tetikleyecek
                self.isAuthenticated = false
                
                // NotificationCenter aracılığıyla uygulama genelinde bildirim yayınla
                NotificationCenter.default.post(name: NSNotification.Name("LogoutNotification"), object: nil)
                
                print("Çıkış yapıldı, login sayfasına yönlendiriliyor...")
            }
        }
    }
    
    // Hata gösterme yardımcı fonksiyonu
    private func showError(_ message: String) {
        self.errorMessage = message // Genel display için 
        self.alertMessage = AlertMessage(message: message) // Alert için
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
