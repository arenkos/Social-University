//
//  UniversitySelectionView.swift
//  Social University
//
//  Created by Aren Koş on 8.03.2025.
//

import SwiftUI
import SwiftData

struct UniversitySelectionView: View {
    @Environment(\.modelContext) private var modelContext
    var user: User
    
    // Seçilen değerler için state değişkenleri
    @State private var selectedUniversity: String?
    @State private var selectedDepartment: String?
    
    // Şu anki aşama (üniversite seçimi veya bölüm seçimi)
    @State private var currentStep = 0
    
    // Seçimi tamamladıktan sonra ders listesine geçiş için
    @State private var navigateToCourseList = false
    
    // Dinamik bölüm listesi ve yükleme durumu
    @State private var departments: [String] = []
    @State private var isLoadingDepartments = false
    @State private var departmentError: String? = nil
    
    // Üniversite listesi
    let universities = [
        "Abdullah Gül Üniversitesi",
        "Acıbadem Mehmet Ali Aydınlar Üniversitesi",
        "Adana Alparslan Türkeş Bilim ve Teknoloji Üniversitesi",
        "Adıyaman Üniversitesi",
        "Afyon Kocatepe Üniversitesi",
        "Afyonkarahisar Sağlık Bilimleri Üniversitesi",
        "Ağrı İbrahim Çeçen Üniversitesi",
        "Akdeniz Üniversitesi",
        "Aksaray Üniversitesi",
        "Alanya Alaaddin Keykubat Üniversitesi",
        "Altınbaş Üniversitesi",
        "Amasya Üniversitesi",
        "Anadolu Üniversitesi",
        "Anka Teknoloji Üniversitesi",
        "Ankara Bilim Üniversitesi",
        "Ankara Hacı Bayram Veli Üniversitesi",
        "Ankara Medipol Üniversitesi",
        "Ankara Müzik ve Güzel Sanatlar Üniversitesi",
        "Ankara Sosyal Bilimler Üniversitesi",
        "Ankara Üniversitesi",
        "Ankara Yıldırım Beyazıt Üniversitesi",
        "Antalya Belek Üniversitesi",
        "Antalya Bilim Üniversitesi",
        "Ardahan Üniversitesi",
        "Artvin Çoruh Üniversitesi",
        "Ataşehir Adıgüzel Üniversitesi",
        "Atatürk Üniversitesi",
        "Atılım Üniversitesi",
        "Avrasya Üniversitesi",
        "Aydın Adnan Menderes Üniversitesi",
        "Bahçeşehir Üniversitesi",
        "Balıkesir Üniversitesi",
        "Bandırma Onyedi Eylül Üniversitesi",
        "Bartın Üniversitesi",
        "Başkent Üniversitesi",
        "Batman Üniversitesi",
        "Bayburt Üniversitesi",
        "Beykent Üniversitesi",
        "Beykoz Üniversitesi",
        "Bezmialem Vakıf Üniversitesi",
        "Bilecik Şeyh Edebali Üniversitesi",
        "Bingöl Üniversitesi",
        "Biruni Üniversitesi",
        "Bitlis Eren Üniversitesi",
        "Boğaziçi Üniversitesi",
        "Bolu Abant İzzet Baysal Üniversitesi",
        "Burdur Mehmet Akif Ersoy Üniversitesi",
        "Bursa Teknik Üniversitesi",
        "Bursa Uludağ Üniversitesi",
        "Çanakkale Onsekiz Mart Üniversitesi",
        "Çankaya Üniversitesi",
        "Çankırı Karatekin Üniversitesi",
        "Çiğli Bakırçay Üniversitesi",
        "Çukurova Üniversitesi",
        "Dicle Üniversitesi",
        "Doğuş Üniversitesi",
        "Dokuz Eylül Üniversitesi",
        "Düzce Üniversitesi",
        "Ege Üniversitesi",
        "Erzincan Binali Yıldırım Üniversitesi",
        "Erzurum Teknik Üniversitesi",
        "Eskişehir Osmangazi Üniversitesi",
        "Eskişehir Teknik Üniversitesi",
        "Fatih Sultan Mehmet Vakıf Üniversitesi",
        "Fenerbahçe Üniversitesi",
        "Fırat Üniversitesi",
        "Galatasaray Üniversitesi",
        "Gazi Üniversitesi",
        "Gaziantep İslam Bilim ve Teknoloji Üniversitesi",
        "Gaziantep Üniversitesi",
        "Gebze Teknik Üniversitesi",
        "Giresun Üniversitesi",
        "Gümüşhane Üniversitesi",
        "Hacı Bektaş Veli Üniversitesi",
        "Hakkari Üniversitesi",
        "Haliç Üniversitesi",
        "Harran Üniversitesi",
        "Hasan Kalyoncu Üniversitesi",
        "Hatay Mustafa Kemal Üniversitesi",
        "Hitit Üniversitesi",
        "Iğdır Üniversitesi",
        "Işık Üniversitesi",
        "İbn Haldun Üniversitesi",
        "İhsan Doğramacı Bilkent Üniversitesi",
        "İnönü Üniversitesi",
        "İskenderun Teknik Üniversitesi",
        "İstanbul 29 Mayıs Üniversitesi",
        "İstanbul Arel Üniversitesi",
        "İstanbul Atlas Üniversitesi",
        "İstanbul Aydın Üniversitesi",
        "İstanbul Beykent Üniversitesi",
        "İstanbul Bilgi Üniversitesi",
        "İstanbul Cerrahpaşa Üniversitesi",
        "İstanbul Esenyurt Üniversitesi",
        "İstanbul Gedik Üniversitesi",
        "İstanbul Gelişim Üniversitesi",
        "İstanbul İbn Haldun Üniversitesi",
        "İstanbul Kent Üniversitesi",
        "İstanbul Kültür Üniversitesi",
        "İstanbul Medeniyet Üniversitesi",
        "İstanbul Medipol Üniversitesi",
        "İstanbul Okan Üniversitesi",
        "İstanbul Rumeli Üniversitesi",
        "İstanbul Sabahattin Zaim Üniversitesi",
        "İstanbul Sağlık ve Teknoloji Üniversitesi",
        "İstanbul Teknik Üniversitesi",
        "İstanbul Ticaret Üniversitesi",
        "İstanbul Topkapı Üniversitesi",
        "İstanbul Üniversitesi",
        "İstanbul Yeni Yüzyıl Üniversitesi",
        "İzmir Bakırçay Üniversitesi",
        "İzmir Demokrasi Üniversitesi",
        "İzmir Ekonomi Üniversitesi",
        "İzmir Katip Çelebi Üniversitesi",
        "İzmir Tınaztepe Üniversitesi",
        "İzmir Yüksek Teknoloji Enstitüsü",
        "Kafkas Üniversitesi",
        "Kahramanmaraş İstiklal Üniversitesi",
        "Kahramanmaraş Sütçü İmam Üniversitesi",
        "Kapadokya Üniversitesi",
        "Karadeniz Teknik Üniversitesi",
        "Karabük Üniversitesi",
        "Karamanoğlu Mehmetbey Üniversitesi",
        "Kastamonu Üniversitesi",
        "Kadir Has Üniversitesi",
        "Kayseri Üniversitesi",
        "Kırıkkale Üniversitesi",
        "Kırklareli Üniversitesi",
        "Kırşehir Ahi Evran Üniversitesi",
        "Kilis 7 Aralık Üniversitesi",
        "Kocaeli Sağlık ve Teknoloji Üniversitesi",
        "Kocaeli Üniversitesi",
        "Koç Üniversitesi",
        "Konya Gıda ve Tarım Üniversitesi",
        "Konya Teknik Üniversitesi",
        "Kütahya Dumlupınar Üniversitesi",
        "Kütahya Sağlık Bilimleri Üniversitesi",
        "Lokman Hekim Üniversitesi",
        "Malatya Turgut Özal Üniversitesi",
        "Maltepe Üniversitesi",
        "Manisa Celal Bayar Üniversitesi",
        "Mardin Artuklu Üniversitesi",
        "Marmara Üniversitesi",
        "Mersin Üniversitesi",
        "Mimar Sinan Güzel Sanatlar Üniversitesi",
        "Muğla Sıtkı Koçman Üniversitesi",
        "Munzur Üniversitesi",
        "Muş Alparslan Üniversitesi",
        "Namık Kemal Üniversitesi",
        "Necmettin Erbakan Üniversitesi",
        "Nevşehir Hacı Bektaş Veli Üniversitesi",
        "Niğde Ömer Halisdemir Üniversitesi",
        "Nişantaşı Üniversitesi",
        "Ondokuz Mayıs Üniversitesi",
        "Ordu Üniversitesi",
        "Orta Doğu Teknik Üniversitesi",
        "Osmaniye Korkut Ata Üniversitesi",
        "Özyeğin Üniversitesi",
        "Pamukkale Üniversitesi",
        "Piri Reis Üniversitesi",
        "Recep Tayyip Erdoğan Üniversitesi",
        "Sabancı Üniversitesi",
        "Sağlık Bilimleri Üniversitesi",
        "Sakarya Üniversitesi",
        "Sakarya Uygulamalı Bilimler Üniversitesi",
        "Samsun Üniversitesi",
        "Sanko Üniversitesi",
        "Selçuk Üniversitesi",
        "Siirt Üniversitesi",
        "Sinop Üniversitesi",
        "Sivas Bilim ve Teknoloji Üniversitesi",
        "Sivas Cumhuriyet Üniversitesi",
        "Süleyman Demirel Üniversitesi",
        "Şırnak Üniversitesi",
        "Tarsus Üniversitesi",
        "TED Üniversitesi",
        "Tekirdağ Namık Kemal Üniversitesi",
        "TOBB Ekonomi ve Teknoloji Üniversitesi",
        "Tokat Gaziosmanpaşa Üniversitesi",
        "Trabzon Üniversitesi",
        "Trakya Üniversitesi",
        "Türk-Alman Üniversitesi",
        "Türk-Japon Bilim ve Teknoloji Üniversitesi",
        "Türkiye Uluslararası İslam, Bilim ve Teknoloji Üniversitesi",
        "Turgut Özal Üniversitesi",
        "Ufuk Üniversitesi",
        "Üsküdar Üniversitesi",
        "Van Yüzüncü Yıl Üniversitesi",
        "Yakın Doğu Üniversitesi",
        "Yalova Üniversitesi",
        "Yaşar Üniversitesi",
        "Yeditepe Üniversitesi",
        "Yıldız Teknik Üniversitesi",
        "Yozgat Bozok Üniversitesi",
        "Yüksek İhtisas Üniversitesi",
        "Zonguldak Bülent Ecevit Üniversitesi"
    ]
    
    // Arama terimleri için state değişkenleri
    @State private var universitySearchText = ""
    @State private var departmentSearchText = ""
    
    // Kullanıcı seçimlerini kaydetmek için UserDefaults
    @AppStorage("selectedUniversity") var savedUniversity = ""
    @AppStorage("selectedDepartment") var savedDepartment = ""
    
    // Bölüm listesini yüklemek için API çağrısı yapan fonksiyon
    private func loadDepartments(for university: String) {
        isLoadingDepartments = true
        departmentError = nil
        
        // API ile bölümleri çek
        APIService.shared.getDepartments(university: university) { result in
            DispatchQueue.main.async {
                self.isLoadingDepartments = false
                
                switch result {
                case .success(let fetchedDepartments):
                    self.departments = fetchedDepartments
                    
                    // Eğer daha önce seçilmiş bir bölüm yoksa ve liste doluysa, ilk bölümü seç
                    if self.selectedDepartment == nil && !fetchedDepartments.isEmpty {
                        self.selectedDepartment = fetchedDepartments[0]
                    }
                    
                case .failure(let error):
                    self.departmentError = "Bölümler yüklenemedi: \(error.localizedDescription)"
                    // Hata durumunda statik bölüm listesini göster
                    self.departments = [
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
                        "Elektrik-Elektronik Mühendisliği",
                        "Gastronomi ve Mutfak Sanatları",
                        "Grafik Tasarımı",
                        "Hukuk",
                        "İşletme",
                        "Makine Mühendisliği",
                        "Mimarlık",
                        "Psikoloji",
                        "Yazılım Mühendisliği",
                        "Yönetim Bilişim Sistemleri"
                    ]
                }
            }
        }
    }
    
    var filteredUniversities: [String] {
        if universitySearchText.isEmpty {
            return universities
        } else {
            return universities.filter { $0.localizedCaseInsensitiveContains(universitySearchText) }
        }
    }
    
    var filteredDepartments: [String] {
        if departmentSearchText.isEmpty {
            return departments
        } else {
            return departments.filter { $0.localizedCaseInsensitiveContains(departmentSearchText) }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // Başlık
                HStack {
                    if currentStep == 1 {
                        Button(action: {
                            currentStep = 0
                        }) {
                            Image(systemName: "arrow.left")
                                .foregroundColor(.blue)
                                .padding(.trailing, 8)
                        }
                    }
                    
                    Text(currentStep == 0 ? "Üniversitenizi Seçin" : "Bölümünüzü Seçin")
                        .font(.headline)
                        .padding()
                    
                    Spacer()
                }
                .padding(.horizontal)
                
                // Arama çubuğu
                if currentStep == 0 {
                    TextField("Üniversite ara...", text: $universitySearchText)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                } else {
                    TextField("Bölüm ara...", text: $departmentSearchText)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                }
                
                // Seçim listesi
                if currentStep == 0 {
                    // Üniversite seçim listesi
                    List {
                        ForEach(filteredUniversities, id: \.self) { university in
                            Button(action: {
                                selectedUniversity = university
                                savedUniversity = university
                                currentStep = 1
                                
                                // Üniversite seçildiğinde bölümleri yükle
                                loadDepartments(for: university)
                            }) {
                                HStack {
                                    Text(university)
                                    
                                    Spacer()
                                    
                                    if university == selectedUniversity {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                                .contentShape(Rectangle())
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                } else {
                    // Bölüm seçim listesi
                    List {
                        ForEach(filteredDepartments, id: \.self) { department in
                            Button(action: {
                                selectedDepartment = department
                                savedDepartment = department
                                
                                // Kullanıcı bilgisini güncelle
                                let updatedUser = user
                                updatedUser.department = department
                                modelContext.insert(updatedUser)
                                
                                // API ile bölüm bilgisini güncelle - Eğer API varsa eklenebilir
                                // updateUserDepartment(userId: user.id, department: department)
                                
                                // Ders listesine yönlendir
                                navigateToCourseList = true
                            }) {
                                HStack {
                                    Text(department)
                                    
                                    Spacer()
                                    
                                    if department == selectedDepartment {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                                .contentShape(Rectangle())
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
            .navigationBarBackButtonHidden(true)
            .navigationDestination(isPresented: $navigateToCourseList) {
                CourseListView(user: user)
            }
        }
        .onAppear {
            // Daha önce seçilmiş değerler varsa yükle
            if !savedUniversity.isEmpty {
                selectedUniversity = savedUniversity
            }
            
            if !savedDepartment.isEmpty {
                selectedDepartment = savedDepartment
                // Önceden seçim yapıldıysa ve doğrulanırsa direkt olarak ders listesine yönlendir
                if !savedUniversity.isEmpty && !savedDepartment.isEmpty {
                    // Kullanıcı bilgilerini güncelle
                    user.department = savedDepartment
                    navigateToCourseList = true
                }
            }
        }
    }
}

#Preview {
    UniversitySelectionView(user: User(id: "preview", email: "test@example.com", name: "Test", surname: "User", studentNumber: "12345", department: ""))
} 