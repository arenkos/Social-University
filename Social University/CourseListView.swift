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
        NavigationStack {
            VStack {
                // Arama ve Filtreleme Alanı
                VStack(spacing: 10) {
                    TextField("Ders Ara", text: $searchText)
                        .padding(10)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    
                    Picker("Bölüm", selection: $selectedDepartment) {
                        Text("Tüm Bölümler").tag(nil as String?)
                        ForEach(departments, id: \.self) { department in
                            Text(department).tag(department as String?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding(.horizontal)
                }
                .padding(.vertical)
                .shadow(radius: 1)
                
                // Ders Listesi
                List {
                    ForEach(filteredCourses) { course in
                        NavigationLink(destination: ChatView(user: user, course: course)) {
                            CourseRow(course: course, user: user, modelContext: modelContext)
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Dersler")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Örnek ders ekle
                        addSampleCourses()
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .onAppear {
                loadDepartments()
                if courses.isEmpty {
                    addSampleCourses()
                }
            }
        }
    }
    
    private func loadDepartments() {
        // Tüm bölümleri kurslardan çıkar
        let allDepartments = Set(courses.map { $0.departmentName })
        departments = Array(allDepartments).sorted()
    }
    
    private func addSampleCourses() {
        let sampleCourses = [
            Course(id: UUID().uuidString, courseCode: "BIL101", courseName: "Bilgisayar Programlama", departmentName: "Bilgisayar Mühendisliği"),
            Course(id: UUID().uuidString, courseCode: "BIL203", courseName: "Veri Yapıları", departmentName: "Bilgisayar Mühendisliği"),
            Course(id: UUID().uuidString, courseCode: "MAT101", courseName: "Kalkülüs I", departmentName: "Matematik"),
            Course(id: UUID().uuidString, courseCode: "FIZ101", courseName: "Fizik I", departmentName: "Fizik"),
            Course(id: UUID().uuidString, courseCode: "ENG101", courseName: "İngilizce I", departmentName: "Yabancı Diller")
        ]
        
        for course in sampleCourses {
            modelContext.insert(course)
        }
        
        // Bölümleri güncelle
        loadDepartments()
    }
}

struct CourseRow: View {
    var course: Course
    var user: User
    var modelContext: ModelContext
    
    @State private var isEnrolled: Bool = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(course.courseCode)
                    .font(.headline)
                Text(course.courseName)
                    .font(.subheadline)
                Text(course.departmentName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                toggleEnrollment()
            }) {
                Text(isEnrolled ? "Ayrıl" : "Katıl")
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(isEnrolled ? Color.red : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            checkEnrollmentStatus()
        }
    }
    
    private func checkEnrollmentStatus() {
        // Burada API ile kullanıcının derse kayıtlı olup olmadığını kontrol edebilirsiniz
        // Bu örnek için basit bir simülasyon yapıyoruz
        isEnrolled = false
    }
    
    private func toggleEnrollment() {
        // Burada API ile kullanıcının derse kaydını değiştirebilirsiniz
        // Bu örnek için basit bir simülasyon yapıyoruz
        isEnrolled.toggle()
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
