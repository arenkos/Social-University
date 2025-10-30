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
    @AppStorage("com.socialuniversity.university") var savedUniversity = ""
    @AppStorage("com.socialuniversity.department") var savedDepartment = ""
    
    // Bölüm listesini yüklemek için API çağrısı yapan fonksiyon
    private func loadDepartments(for university: String) {
        isLoadingDepartments = true
        departmentError = nil
        
        // Üniversite adını URL için uygun şekilde kodla
        guard let encodedUniversity = university.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            departmentError = "Üniversite adı kodlanamadı."
            isLoadingDepartments = false
            return
        }
        
        // API ile bölümleri çek
        let urlString = "https://aryazilimdanismanlik.com/social/get_departments.php?university=\(encodedUniversity)"
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
    
    // Devam et ve bölüm seçimini kaydet
    private func saveDepartmentSelection() {
        guard let selectedUniversity = selectedUniversity, let selectedDepartment = selectedDepartment else {
            print("Üniversite veya bölüm seçilmedi!")
            return
        }
        
        print("🚀 Üniversite ve bölüm seçimi kaydediliyor...")
        print("📍 Seçilen Üniversite: \(selectedUniversity)")
        print("📍 Seçilen Bölüm: \(selectedDepartment)")
        print("👤 Kullanıcı ID: \(user.id)")
        
        // Önce local modeli güncelle
        user.university = selectedUniversity
        user.department = selectedDepartment
        
        // SwiftData context'i kaydet
        do {
            try modelContext.save()
            print("✅ SwiftData başarıyla kaydedildi")
        } catch {
            print("❌ SwiftData kaydetme hatası: \(error.localizedDescription)")
        }
        
        // Seçimleri UserDefaults'a kaydet
        savedUniversity = selectedUniversity
        savedDepartment = selectedDepartment
        print("💾 UserDefaults kaydedildi: University=\(savedUniversity), Department=\(savedDepartment)")

        // API'ye kaydet
        // İlk önce kullanıcı bilgilerini al ve gerçek database ID'sini bul
        print("📞 Kullanıcı bilgilerini alıp gerçek ID'yi bulalım...")
        APIService.shared.getUserInfo(email: user.email) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let userInfo):
                    print("🔍 Email ile kullanıcı bilgileri başarıyla alındı")
                    
                    // Başarılı yanıt kontrolü - API'de 'status' kullanılıyor, 'success' değil
                    if let success = userInfo["status"] as? Bool, success,
                       let data = userInfo["data"] as? [String: Any],
                       let databaseId = data["id"] as? Int {
                        
                        let databaseIdString = String(databaseId)
                        print("🎯 Veritabanı ID'si bulundu: \(databaseIdString)")
                        
                        // Gerçek database ID ile güncelleme yap
                        self.tryUpdateWithDatabaseId(databaseIdString)
                        
                    } else {
                        print("⚠️ Kullanıcı bilgilerinden ID çıkarılamadı, fallback ile devam ediliyor...")
                        self.tryUpdateWithUserId()
                    }
                    
                case .failure(let error):
                    print("❌ Kullanıcı bilgileri alınamadı: \(error.localizedDescription)")
                    print("🔄 Fallback ile devam ediliyor...")
                    self.tryUpdateWithUserId()
                }
            }
        }
    }
    
    // Database ID ile güncelleme deneme fonksiyonu
    private func tryUpdateWithDatabaseId(_ databaseId: String) {
        guard let selectedUniversity = selectedUniversity, let selectedDepartment = selectedDepartment else {
            print("❌ Seçilen değerler kayboldu!")
            return
        }
        
        APIService.shared.updateUserWithDatabaseId(databaseId: databaseId, university: selectedUniversity, department: selectedDepartment) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let isSuccess):
                    if isSuccess {
                        print("✅ Database ID ile API başarıyla güncellendi!")
                        self.navigateToCourseList = true
                    } else {
                        print("⚠️ Database ID ile de API güncelleme başarısız, UUID ile deneniyor...")
                        self.tryUpdateWithUserId()
                    }
                    
                case .failure(let error):
                    print("❌ Database ID ile API güncelleme hatası: \(error.localizedDescription)")
                    print("🔄 UUID ile deneniyor...")
                    self.tryUpdateWithUserId()
                }
            }
        }
    }
    
    // User ID ile güncelleme deneme fonksiyonu
    private func tryUpdateWithUserId() {
        guard let selectedUniversity = selectedUniversity, let selectedDepartment = selectedDepartment else {
            print("❌ Seçilen değerler kayboldu!")
            return
        }
        
        APIService.shared.updateUser(userId: user.id, email: user.email, university: selectedUniversity, department: selectedDepartment) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let isSuccess):
                    if isSuccess {
                        print("✅ User ID ile API başarıyla güncellendi")
                    } else {
                        print("⚠️ User ID ile de API güncelleme başarısız")
                    }
                    // Her durumda devam et (local'da zaten kaydedildi)
                    self.navigateToCourseList = true
                    
                case .failure(let error):
                    print("❌ User ID ile de API güncelleme hatası: \(error.localizedDescription)")
                    // Hata durumunda bile devam et, çünkü local'da kaydedildi
                    self.navigateToCourseList = true
                }
            }
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
                    if isLoadingDepartments {
                        ProgressView("Bölümler yükleniyor...")
                            .padding()
                    } else if let error = departmentError {
                        VStack {
                            Text(error)
                                .foregroundColor(.red)
                                .padding()
                            
                            Button(action: {
                                // Üniversiteyi yeniden seçtir
                                currentStep = 0
                            }) {
                                Text("Üniversite Seçimine Dön")
                                    .foregroundColor(.blue)
                            }
                            .padding()
                        }
                    } else {
                        List {
                            ForEach(filteredDepartments, id: \.self) { department in
                                Button(action: {
                                    selectedDepartment = department
                                    savedDepartment = department
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
                        
                        // Bölüm seçimi tamamlandığında gösterilecek ileri butonu
                        if selectedDepartment != nil {
                            VStack {
                                // Debug bilgisi göster
                                Text("Debug: User ID = \(user.id)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .padding(.top, 4)
                                
                                Text("Debug: Email = \(user.email)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                Button(action: {
                                    // Debug: Kullanıcı bilgilerini sunucudan çek (test için)
                                    // İlk önce email ile dene
                                    APIService.shared.getUserInfo(email: user.email) { result in
                                        switch result {
                                        case .success(let userInfo):
                                            print("🔍 Email ile kullanıcı bilgileri: \(userInfo)")
                                            
                                            // Eğer email ile başarısız olursa userId ile dene
                                            if let success = userInfo["success"] as? Bool, !success {
                                                print("🔍 Email ile başarısız, User ID ile deneniyor...")
                                                APIService.shared.getUserInfo(userId: user.id) { result2 in
                                                    switch result2 {
                                                    case .success(let userInfo2):
                                                        print("🔍 User ID ile kullanıcı bilgileri: \(userInfo2)")
                                                    case .failure(let error2):
                                                        print("🔍 User ID ile de başarısız: \(error2.localizedDescription)")
                                                    }
                                                }
                                            }
                                        case .failure(let error):
                                            print("🔍 Kullanıcı bilgileri çekilemedi: \(error.localizedDescription)")
                                        }
                                    }
                                    
                                    saveDepartmentSelection()
                                }) {
                                    Text("Devam Et")
                                        .fontWeight(.semibold)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }
                                .padding(.horizontal)
                            }
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
            // API bağlantı testi (sadece debug için)
            APIService.shared.testConnection { result in
                switch result {
                case .success(let response):
                    print("🔍 API Test Başarılı: \(response)")
                case .failure(let error):
                    print("🔍 API Test Hatası: \(error.localizedDescription)")
                }
            }
            
            // ÖNCE: Kullanıcının gerçek verilerini kontrol et
            // Eğer kullanıcının veritabanındaki university veya department değerleri boş ise
            // UserDefaults'u da temizle
            if user.university?.isEmpty != false || user.department.isEmpty {
                // UserDefaults'taki eski değerleri temizle
                savedUniversity = ""
                savedDepartment = ""
                UserDefaults.standard.removeObject(forKey: "com.socialuniversity.university")
                UserDefaults.standard.removeObject(forKey: "com.socialuniversity.department")
                print("Kullanıcı verileri boş olduğu için UserDefaults temizlendi")
            }
            
            // Kullanıcının mevcut verilerini kontrol et
            if let userUniversity = user.university, !userUniversity.isEmpty {
                selectedUniversity = userUniversity
                savedUniversity = userUniversity
                
                if !user.department.isEmpty {
                    selectedDepartment = user.department
                    savedDepartment = user.department
                    
                    // Hem üniversite hem bölüm seçili ise direkt ders listesine git
                    navigateToCourseList = true
                    return
                } else {
                    // Üniversite var ama bölüm yok, bölüm seçimine git
                    currentStep = 1
                    loadDepartments(for: userUniversity)
                    return
                }
            }
            
            // Kullanıcı verileri boş ise, UserDefaults'tan da kontrol et (güvenlik için)
            let userDefaultsUniversity = UserDefaults.standard.string(forKey: "com.socialuniversity.university") ?? ""
            let userDefaultsDepartment = UserDefaults.standard.string(forKey: "com.socialuniversity.department") ?? ""
            
            if !userDefaultsUniversity.isEmpty && !userDefaultsDepartment.isEmpty {
                // Eğer UserDefaults'ta değerler varsa ama kullanıcı modelinde yoksa
                // Bu durumda kullanıcıya seçim yaptırmalıyız, otomatik atama yapmamalıyız
                print("Uyarı: UserDefaults'ta değerler var ama kullanıcı modelinde yok. Temizleniyor...")
                savedUniversity = ""
                savedDepartment = ""
                UserDefaults.standard.removeObject(forKey: "com.socialuniversity.university")
                UserDefaults.standard.removeObject(forKey: "com.socialuniversity.department")
            }
            
            // Son olarak, eğer hiçbir şey yoksa sıfırdan başlat
            currentStep = 0
            selectedUniversity = nil
            selectedDepartment = nil
        }
    }
}

#Preview {
    // Preview için geçerli bir User nesnesi oluşturmalısınız
    // Eğer AppSchema modelContainer erişimi yoksa, basit bir User ile test edilebilir
    let previewUser = User(id: "preview", email: "test@example.com", name: "Test", surname: "User", studentNumber: "12345", department: "", university: "")
    return UniversitySelectionView(user: previewUser)
    // .modelContainer(...) // Preview için model container eklemek gerekebilir
} 
