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
    @State private var errorMessage: String?
    @State private var showingLogoutAlert = false
    
    // Uygulama genelinde oturum durumunu takip eden değişkenlere erişim
    @AppStorage("com.socialuniversity.isAuthenticated") private var isAuthenticated = false
    
    // Oturum durumunu güncelleyebilmek için Environment değişkeni
    @Environment(\.presentationMode) private var presentationMode
    
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
            }
            .padding()
            
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
            loadCourses()
        }
        .refreshable {
            loadCourses()
        }
    }
    
    private func loadCourses() {
        isLoading = true
        errorMessage = nil
        
        APIService.shared.getCourses(studentId: user.studentNumber) { result in
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
                
                // Bölümleri güncelle - API'den gelen bölüm listesini kullan
                departments = fetchedDepartments
                
                // Eğer seçili bölüm artık mevcut değilse, seçimi temizle
                if let selectedDepartment = selectedDepartment, !fetchedDepartments.contains(selectedDepartment) {
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
        MicrosoftAuthManager.shared.signOut { success in
            if success {
                // UserDefaults'taki oturum durumunu güncelle
                // Bu değişim Social_UniversityApp tarafından izleniyor 
                // ve otomatik olarak giriş ekranına yönlendiriliyor
                DispatchQueue.main.async {
                    isAuthenticated = false
                    UserDefaults.standard.synchronize() // Değişiklikleri hemen kaydet
                    
                    // Aktif tüm görünümleri kapatıp, ana görünüme dön
                    if let window = UIApplication.shared.windows.first,
                       let rootViewController = window.rootViewController {
                        // Tüm açık viewController'ları kapat
                        rootViewController.dismiss(animated: true)
                    }
                }
            } else {
                errorMessage = "Çıkış yapılırken bir hata oluştu. Lütfen tekrar deneyin."
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
