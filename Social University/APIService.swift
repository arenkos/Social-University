//
//  APIService.swift
//  Social University
//
//  Created by Aren Koş on 8.03.2025.
//

import Foundation
import SwiftData
import SwiftUI

// Tüm model sınıflarını doğrudan kullanabilmek için
// MicrosoftAuthManager ile ilgili type alias
typealias MicrosoftAuthManagerUserInfo = MicrosoftAuthManager.UserInfo

// AppCore.swift dosyasını import ediyoruz
// @_exported import struct MicrosoftAuthManager.UserInfo

class APIService {
    static let shared = APIService()
    
    private let baseURL = "https://aryazilimdanismanlik.com/social" // Sunucu adresi
    private let session = URLSession.shared
    
    private init() {}
    
    // MARK: - Kullanıcı İşlemleri
    
    func login(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        let url = URL(string: "\(baseURL)/api/login.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let parameters: [String: Any] = [
            "email": email,
            "password": password
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        } catch {
            completion(.failure(error))
            return
        }
        
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "APIService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Veri alınamadı"])))
                }
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                
                guard let success = json?["success"] as? Bool, success else {
                    let message = json?["message"] as? String ?? "Bilinmeyen hata"
                    throw NSError(domain: "APIService", code: 0, userInfo: [NSLocalizedDescriptionKey: message])
                }
                
                guard let userData = json?["data"] as? [String: Any] else {
                    throw NSError(domain: "APIService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Kullanıcı bilgileri alınamadı"])
                }
                
                let id = userData["id"] as? String ?? UUID().uuidString
                let name = (userData["name_surname"] as? String)?.components(separatedBy: " ").first ?? ""
                let surname = (userData["name_surname"] as? String)?.components(separatedBy: " ").last ?? ""
                let studentNumber = userData["student_number"] as? String ?? ""
                
                // NULL değerleri boş string olarak işle ve debug için log
                let departmentFromAPI = userData["department"] as? String
                let universityFromAPI = userData["university"] as? String
                
                let department = (departmentFromAPI?.isEmpty == false) ? departmentFromAPI! : ""
                let university = (universityFromAPI?.isEmpty == false) ? universityFromAPI! : ""
                
                print("API'den gelen kullanıcı verileri:")
                print("- ID: \(id)")
                print("- Email: \(email)")
                print("- Department (raw): \(departmentFromAPI ?? "nil")")
                print("- University (raw): \(universityFromAPI ?? "nil")")
                print("- Department (processed): '\(department)'")
                print("- University (processed): '\(university)'")
                
                let user = User(
                    id: id,
                    email: email,
                    name: name,
                    surname: surname,
                    studentNumber: studentNumber,
                    department: department,
                    university: university
                )
                
                DispatchQueue.main.async {
                    completion(.success(user))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
        
        task.resume()
    }
    
    func register(email: String, password: String, nameSurname: String, studentNumber: String, phoneNumber: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        let url = URL(string: "\(baseURL)/api/register.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let parameters: [String: Any] = [
            "email": email,
            "password": password,
            "name_surname": nameSurname,
            "student_number": studentNumber,
            "phone_number": phoneNumber
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        } catch {
            completion(.failure(error))
            return
        }
        
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "APIService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Veri alınamadı"])))
                }
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                
                guard let success = json?["success"] as? Bool else {
                    let message = json?["message"] as? String ?? "Bilinmeyen hata"
                    throw NSError(domain: "APIService", code: 0, userInfo: [NSLocalizedDescriptionKey: message])
                }
                
                DispatchQueue.main.async {
                    completion(.success(success))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
        
        task.resume()
    }
    
    func loginWithMicrosoft(userInfo: MicrosoftAuthManager.UserInfo, completion: @escaping (Result<User, Error>) -> Void) {
        // Microsoft ile login işlemini yeni API ile değiştir
        loginWithMicrosoft(userInfo: userInfo, completion: completion)
    }
    
    // MARK: - Ders İşlemleri
    
    func getDepartments(university: String, completion: @escaping (Result<[String], Error>) -> Void) {
        var urlComponents = URLComponents(string: "\(baseURL)/get_departments.php")!
        
        let queryItems = [URLQueryItem(name: "university", value: university)]
        urlComponents.queryItems = queryItems
        
        let url = urlComponents.url!
        print("Departments API URL: \(url.absoluteString)")
        
        let request = URLRequest(url: url)
        
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    print("Network error: \(error.localizedDescription)")
                    completion(.failure(error))
                }
                return
            }
            
            // HTTP yanıtını kontrol et
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status Code: \(httpResponse.statusCode)")
                
                // Başarısız HTTP kodlarını kontrol et
                if httpResponse.statusCode != 200 {
                    let error = NSError(domain: "APIService", 
                                      code: httpResponse.statusCode, 
                                      userInfo: [NSLocalizedDescriptionKey: "HTTP error \(httpResponse.statusCode)"])
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                    return
                }
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    print("No data received")
                    completion(.failure(NSError(domain: "APIService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Veri alınamadı"])))
                }
                return
            }
            
            // Debug bilgisi
            if let dataStr = String(data: data, encoding: .utf8) {
                print("API Response: \(dataStr)")
            }
            
            do {
                // JSON yanıtını ayrıştır
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                
                // Başarılı yanıt kontrolü
                let success = json?["success"] as? Bool ?? false
                
                // Departman listesini al
                var departments: [String] = []
                
                if let departmentsData = json?["data"] as? [String] {
                    departments = departmentsData
                } else if let errorMessage = json?["message"] as? String {
                    print("API Error: \(errorMessage)")
                    // Hata olsa bile varsayılan departman listesiyle devam et
                    departments = self.getDefaultDepartments()
                } else {
                    // JSON başarısız veya hiç departman yoksa
                    departments = self.getDefaultDepartments()
                }
                
                DispatchQueue.main.async {
                    completion(.success(departments))
                }
            } catch {
                print("JSON parsing error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    // JSON hatası durumunda da varsayılan departman listesini döndür
                    let departments = self.getDefaultDepartments()
                    completion(.success(departments))
                }
            }
        }
        
        task.resume()
    }
    
    // Varsayılan departman listesi
    private func getDefaultDepartments() -> [String] {
        return [
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
    
    func getCourses(studentId: String? = nil, search: String? = nil, department: String? = nil, university: String? = nil, completion: @escaping (Result<([Course], [String]), Error>) -> Void) {
        var urlComponents = URLComponents(string: "\(baseURL)/get_courses.php")!
        
        var queryItems: [URLQueryItem] = []
        
        if let studentId = studentId {
            queryItems.append(URLQueryItem(name: "student_id", value: studentId))
        }
        
        if let search = search, !search.isEmpty {
            queryItems.append(URLQueryItem(name: "search", value: search))
        }
        
        if let department = department, !department.isEmpty {
            queryItems.append(URLQueryItem(name: "department", value: department))
        }
        
        if let university = university, !university.isEmpty {
            queryItems.append(URLQueryItem(name: "university", value: university))
        }
        
        urlComponents.queryItems = queryItems
        
        let request = URLRequest(url: urlComponents.url!)
        
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "APIService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Veri alınamadı"])))
                }
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                
                guard let success = json?["success"] as? Bool, success else {
                    let message = json?["message"] as? String ?? "Bilinmeyen hata"
                    throw NSError(domain: "APIService", code: 0, userInfo: [NSLocalizedDescriptionKey: message])
                }
                
                guard let responseData = json?["data"] as? [String: Any],
                      let coursesData = responseData["courses"] as? [[String: Any]],
                      let departments = responseData["departments"] as? [String] else {
                    throw NSError(domain: "APIService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Ders bilgileri alınamadı"])
                }
                
                var courses: [Course] = []
                
                for courseData in coursesData {
                    guard let courseCode = courseData["course_code"] as? String,
                          let courseName = courseData["course_name"] as? String,
                          let departmentName = courseData["course_department"] as? String else {
                        continue
                    }
                    
                    // Öğrencinin derse kayıtlı olup olmadığını kontrol et
                    let isEnrolled = courseData["is_enrolled"] as? Bool ?? false
                    
                    let course = Course(
                        id: courseCode, // Ders kodu aynı zamanda ID olarak kullanılıyor
                        courseCode: courseCode,
                        courseName: courseName,
                        departmentName: departmentName,
                        isEnrolled: isEnrolled
                    )
                    
                    courses.append(course)
                }
                
                DispatchQueue.main.async {
                    completion(.success((courses, departments)))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
        
        task.resume()
    }
    
    func enrollCourse(studentId: String, courseCode: String, action: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let url = URL(string: "\(baseURL)/update_enrollment.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "student_id": studentId,
            "course_code": courseCode,
            "action": action // "enroll" veya "unenroll"
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: body)
            request.httpBody = jsonData
            
            print("Sunucu istek gönderiliyor: \(body)")
            
            let task = session.dataTask(with: request) { data, response, error in
                if let error = error {
                    DispatchQueue.main.async {
                        print("Ağ hatası: \(error.localizedDescription)")
                        completion(.failure(error))
                    }
                    return
                }
                
                guard let data = data else {
                    DispatchQueue.main.async {
                        print("Veri alınamadı")
                        completion(.failure(NSError(domain: "APIService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Veri alınamadı"])))
                    }
                    return
                }
                
                // Debug: Sunucudan dönen veriyi yazdır
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Sunucu yanıtı: \(responseString)")
                }
                
                do {
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    print("Ayrıştırılan JSON: \(String(describing: json))")
                    
                    // Sunucudan dönen yanıtın yapısını kontrol et
                    guard let json = json else {
                        throw NSError(domain: "APIService", code: 0, userInfo: [NSLocalizedDescriptionKey: "JSON verisi bulunamadı"])
                    }
                    
                    // success değerini kontrol et
                    guard let success = json["success"] as? Bool else {
                        throw NSError(domain: "APIService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Sunucu yanıtında 'success' değeri bulunamadı"])
                    }
                    
                    if !success {
                        let message = json["message"] as? String ?? "Bilinmeyen hata"
                        throw NSError(domain: "APIService", code: 0, userInfo: [NSLocalizedDescriptionKey: message])
                    }
                    
                    DispatchQueue.main.async {
                        completion(.success(()))
                    }
                } catch {
                    DispatchQueue.main.async {
                        print("JSON ayrıştırma hatası: \(error.localizedDescription)")
                        completion(.success(()))
                    }
                }
            }
            
            task.resume()
        } catch {
            DispatchQueue.main.async {
                print("JSON oluşturma hatası: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Mesaj İşlemleri
    
    func getMessages(courseCode: String, completion: @escaping (Result<[Message], Error>) -> Void) {
        var urlComponents = URLComponents(string: "\(baseURL)/messages.php")!
        
        let queryItems: [URLQueryItem] = [
            URLQueryItem(name: "course_code", value: courseCode)
        ]
        
        urlComponents.queryItems = queryItems
        
        let request = URLRequest(url: urlComponents.url!)
        
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "APIService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Veri alınamadı"])))
                }
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                
                guard let success = json?["success"] as? Bool, success else {
                    let message = json?["message"] as? String ?? "Bilinmeyen hata"
                    throw NSError(domain: "APIService", code: 0, userInfo: [NSLocalizedDescriptionKey: message])
                }
                
                guard let responseData = json?["data"] as? [String: Any],
                      let messagesData = responseData["messages"] as? [[String: Any]] else {
                    throw NSError(domain: "APIService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Mesaj bilgileri alınamadı"])
                }
                
                var messages: [Message] = []
                
                for messageData in messagesData {
                    guard let id = messageData["id"] as? String,
                          let content = messageData["message"] as? String,
                          let timestampString = messageData["timestamp"] as? String,
                          let courseCode = messageData["course_code"] as? String else {
                        continue
                    }
                    
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    let timestamp = dateFormatter.date(from: timestampString) ?? Date()
                    
                    let senderId = messageData["student_id"] as? String
                    
                    let message = Message(
                        id: id,
                        content: content,
                        timestamp: timestamp,
                        senderId: senderId,
                        courseId: courseCode
                    )
                    
                    messages.append(message)
                }
                
                DispatchQueue.main.async {
                    completion(.success(messages))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
        
        task.resume()
    }
    
    func sendMessage(courseCode: String, message: String, studentId: String?, completion: @escaping (Result<Message, Error>) -> Void) {
        let url = URL(string: "\(baseURL)/messages.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var body: [String: Any] = [
            "course_code": courseCode,
            "message": message
        ]
        
        if let studentId = studentId {
            body["student_id"] = studentId
        }
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "APIService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Veri alınamadı"])))
                }
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                
                guard let success = json?["success"] as? Bool, success else {
                    let message = json?["message"] as? String ?? "Bilinmeyen hata"
                    throw NSError(domain: "APIService", code: 0, userInfo: [NSLocalizedDescriptionKey: message])
                }
                
                guard let responseData = json?["data"] as? [String: Any],
                      let messageData = responseData["message"] as? [String: Any],
                      let id = messageData["id"] as? String,
                      let content = messageData["message"] as? String,
                      let timestampString = messageData["timestamp"] as? String,
                      let courseCode = messageData["course_code"] as? String else {
                    throw NSError(domain: "APIService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Mesaj bilgileri alınamadı"])
                }
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                let timestamp = dateFormatter.date(from: timestampString) ?? Date()
                
                let senderId = messageData["student_id"] as? String
                
                let message = Message(
                    id: id,
                    content: content,
                    timestamp: timestamp,
                    senderId: senderId,
                    courseId: courseCode
                )
                
                DispatchQueue.main.async {
                    completion(.success(message))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
        
        task.resume()
    }
}

// MARK: - Kullanıcı İşlemleri - Login / Register Fonksiyonları
    
extension APIService {
    // Kullanıcı e-posta ve şifre ile giriş
    func loginWithEmailPassword(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        let url = URL(string: "\(baseURL)/api/login.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let parameters: [String: Any] = [
            "email": email,
            "password": password
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        } catch {
            completion(.failure(error))
            return
        }
        
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "APIService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Veri alınamadı"])))
                }
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                
                guard let success = json?["success"] as? Bool, success else {
                    let message = json?["message"] as? String ?? "Bilinmeyen hata"
                    throw NSError(domain: "APIService", code: 0, userInfo: [NSLocalizedDescriptionKey: message])
                }
                
                guard let userData = json?["data"] as? [String: Any] else {
                    throw NSError(domain: "APIService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Kullanıcı bilgileri alınamadı"])
                }
                
                let id = userData["id"] as? String ?? UUID().uuidString
                let nameSurname = userData["name_surname"] as? String ?? ""
                let nameParts = nameSurname.components(separatedBy: " ")
                let name = nameParts.first ?? ""
                let surname = nameParts.count > 1 ? nameParts.last ?? "" : ""
                let studentNumber = userData["student_number"] as? String ?? ""
                let department = userData["department"] as? String ?? ""
                let university = userData["university"] as? String ?? ""
                
                let user = User(
                    id: id,
                    email: email,
                    name: name,
                    surname: surname,
                    studentNumber: studentNumber,
                    department: department,
                    university: university
                )
                
                DispatchQueue.main.async {
                    completion(.success(user))
                    print("login değerleri alındı")
                    print("deparment: \(user.department)")
                    print("universite: \(user.university)")
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                    
                    print("login değerleri alınamadı")
                }
            }
        }
        
        task.resume()
    }
    
    // Kullanıcı kaydı
    func registerUser(email: String, password: String, nameSurname: String, studentNumber: String, phoneNumber: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        let url = URL(string: "\(baseURL)/register.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let parameters: [String: Any] = [
            "email": email,
            "password": password,
            "name_surname": nameSurname,
            "student_number": studentNumber,
            "phone_number": phoneNumber
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        } catch {
            completion(.failure(error))
            return
        }
        
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "APIService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Veri alınamadı"])))
                }
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                
                guard let success = json?["success"] as? Bool else {
                    let message = json?["message"] as? String ?? "Bilinmeyen hata"
                    throw NSError(domain: "APIService", code: 0, userInfo: [NSLocalizedDescriptionKey: message])
                }
                
                DispatchQueue.main.async {
                    completion(.success(success))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
        
        task.resume()
    }
    
    // Microsoft kullanıcısı ile giriş
    func loginWithMicrosoftAccount(userInfo: MicrosoftAuthManager.UserInfo, completion: @escaping (Result<User, Error>) -> Void) {
        let url = URL(string: "\(baseURL)/api/login_microsoft.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let parameters: [String: Any] = [
            "email": userInfo.email,
            "name": userInfo.name,
            "surname": userInfo.surname,
            "student_number": userInfo.studentNumber,
            "department": userInfo.department
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        } catch {
            completion(.failure(error))
            return
        }
        
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "APIService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Veri alınamadı"])))
                }
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                
                guard let success = json?["success"] as? Bool, success else {
                    let message = json?["message"] as? String ?? "Bilinmeyen hata"
                    throw NSError(domain: "APIService", code: 0, userInfo: [NSLocalizedDescriptionKey: message])
                }
                
                guard let userData = json?["data"] as? [String: Any] else {
                    throw NSError(domain: "APIService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Kullanıcı bilgileri alınamadı"])
                }
                
                let id = userData["id"] as? String ?? UUID().uuidString
                let email = userData["mail"] as? String ?? userInfo.email
                let nameSurname = userData["name_surname"] as? String ?? "\(userInfo.name) \(userInfo.surname)"
                let nameParts = nameSurname.components(separatedBy: " ")
                let name = nameParts.first ?? userInfo.name
                let surname = nameParts.count > 1 ? nameParts.last ?? "" : userInfo.surname
                let studentNumber = userData["student_number"] as? String ?? userInfo.studentNumber
                let department = userData["department"] as? String ?? userInfo.department
                let university = userData["university"] as? String ?? ""
                
                let user = User(
                    id: id,
                    email: email,
                    name: name,
                    surname: surname,
                    studentNumber: studentNumber,
                    department: department,
                    university: university
                )
                
                DispatchQueue.main.async {
                    completion(.success(user))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
        
        task.resume()
    }
    
    // Kullanıcı profil bilgilerini güncelleme (mevcut user ID ile)
    func updateUserWithDatabaseId(databaseId: String, university: String?, department: String?, completion: @escaping (Result<Bool, Error>) -> Void) {
        let url = URL(string: "\(baseURL)/api/update_user.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var parameters: [String: Any] = [
            "user_id": databaseId  // Veritabanından aldığımız gerçek ID
        ]
        
        if let university = university {
            parameters["university"] = university
        }
        
        if let department = department {
            parameters["department"] = department
        }
        
        print("📡 Database ID ile güncelleme isteği:")
        print("   - Database ID: \(databaseId)")
        print("   - University: \(university ?? "nil")")
        print("   - Department: \(department ?? "nil")")
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: parameters)
            request.httpBody = jsonData
            
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("📡 Gönderilen JSON: \(jsonString)")
            }
        } catch {
            print("❌ JSON oluşturma hatası: \(error)")
            completion(.failure(error))
            return
        }
        
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Network error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 Database ID Update HTTP Status: \(httpResponse.statusCode)")
            }
            
            guard let data = data else {
                print("❌ No data received")
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "APIService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Veri alınamadı"])))
                }
                return
            }
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("📡 Database ID Update Response: \(responseString)")
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                print("📡 Database ID Update JSON: \(String(describing: json))")
                
                guard let success = json?["success"] as? Bool else {
                    let message = json?["message"] as? String ?? "Sunucu yanıtında 'success' alanı bulunamadı"
                    throw NSError(domain: "APIService", code: 0, userInfo: [NSLocalizedDescriptionKey: message])
                }
                
                DispatchQueue.main.async {
                    completion(.success(success))
                }
            } catch {
                print("❌ JSON parsing error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
        
        task.resume()
    }
    
    // Kullanıcı profil bilgilerini güncelleme (mevcut fonksiyon)
    func updateUser(userId: String, email: String? = nil, university: String?, department: String?, completion: @escaping (Result<Bool, Error>) -> Void) {
        let url = URL(string: "\(baseURL)/api/update_user.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var parameters: [String: Any] = [
            "user_id": userId
        ]
        
        // Email parametresini de ekle (bazı API'ler bunu gerektirebilir)
        if let email = email {
            parameters["email"] = email
        }
        
        if let university = university {
            parameters["university"] = university
        }
        
        if let department = department {
            parameters["department"] = department
        }
        
        print("📡 API Request URL: \(url.absoluteString)")
        print("📡 Kullanıcı güncelleme isteği gönderiliyor:")
        print("   - User ID: \(userId)")
        print("   - Email: \(email ?? "nil")")
        print("   - University: \(university ?? "nil")")
        print("   - Department: \(department ?? "nil")")
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: parameters)
            request.httpBody = jsonData
            
            // Debug: Gönderilen JSON'u yazdır
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("📡 Gönderilen JSON: \(jsonString)")
            }
        } catch {
            print("❌ JSON oluşturma hatası: \(error)")
            completion(.failure(error))
            return
        }
        
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Network error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            // HTTP yanıtını kontrol et
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 HTTP Status Code: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode != 200 {
                    let error = NSError(domain: "APIService", 
                                      code: httpResponse.statusCode, 
                                      userInfo: [NSLocalizedDescriptionKey: "HTTP error \(httpResponse.statusCode)"])
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                    return
                }
            }
            
            guard let data = data else {
                print("❌ No data received")
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "APIService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Veri alınamadı"])))
                }
                return
            }
            
            // Debug: Ham yanıtı yazdır
            if let responseString = String(data: data, encoding: .utf8) {
                print("📡 Sunucu yanıtı (raw): \(responseString)")
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                print("📡 Ayrıştırılan JSON: \(String(describing: json))")
                
                guard let success = json?["success"] as? Bool else {
                    let message = json?["message"] as? String ?? "Sunucu yanıtında 'success' alanı bulunamadı"
                    print("❌ JSON parsing error: \(message)")
                    throw NSError(domain: "APIService", code: 0, userInfo: [NSLocalizedDescriptionKey: message])
                }
                
                print("📡 Kullanıcı güncelleme sonucu: \(success)")
                if let message = json?["message"] as? String {
                    print("📡 Sunucu mesajı: \(message)")
                }
                
                // Debug: Tüm yanıt verilerini yazdır
                if let allData = json {
                    for (key, value) in allData {
                        print("📡 Response[\(key)]: \(value)")
                    }
                }
                
                DispatchQueue.main.async {
                    completion(.success(success))
                }
            } catch {
                print("❌ JSON parsing error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
        
        task.resume()
    }
    
    // MARK: - Debug ve Test Fonksiyonları
    
    /// API bağlantısını test etmek için basit bir fonksiyon
    func testConnection(completion: @escaping (Result<String, Error>) -> Void) {
        let url = URL(string: "\(baseURL)/api/test.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        print("🔍 API bağlantı testi yapılıyor: \(url.absoluteString)")
        
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("🔍 Test HTTP Status: \(httpResponse.statusCode)")
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "APIService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Test: Veri alınamadı"])))
                }
                return
            }
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("🔍 Test Response: \(responseString)")
                DispatchQueue.main.async {
                    completion(.success(responseString))
                }
            } else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "APIService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Test: Yanıt çözülemedi"])))
                }
            }
        }
        
        task.resume()
    }
    
    /// Kullanıcı bilgilerini sunucudan çekmek için test fonksiyonu
    func getUserInfo(userId: String? = nil, email: String? = nil, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        var urlComponents = URLComponents(string: "\(baseURL)/api/get_user.php")!
        
        var queryItems: [URLQueryItem] = []
        
        // PHP kodu 'id' parametresini bekliyor ama bu email olmalı
        if let email = email {
            queryItems.append(URLQueryItem(name: "id", value: email)) // 'id' parametresi aslında email
        } else if let userId = userId {
            queryItems.append(URLQueryItem(name: "user_id", value: userId))
        }
        
        // Eğer hiç parametre yoksa hata ver
        if queryItems.isEmpty {
            DispatchQueue.main.async {
                completion(.failure(NSError(domain: "APIService", code: 0, userInfo: [NSLocalizedDescriptionKey: "user_id veya email parametresi gerekli"])))
            }
            return
        }
        
        urlComponents.queryItems = queryItems
        
        let url = urlComponents.url!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        print("🔍 Kullanıcı bilgileri çekiliyor: \(url.absoluteString)")
        
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("🔍 Get User HTTP Status: \(httpResponse.statusCode)")
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "APIService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Kullanıcı verisi alınamadı"])))
                }
                return
            }
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("🔍 Get User Response: \(responseString)")
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                print("🔍 Get User JSON: \(String(describing: json))")
                
                DispatchQueue.main.async {
                    completion(.success(json ?? [:]))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
        
        task.resume()
    }
    
    /// UserDefaults'taki kullanıcı tercihlerini temizler
    static func clearUserDefaults() {
        let userDefaults = UserDefaults.standard
        let keysToRemove = [
            "com.socialuniversity.university",
            "com.socialuniversity.department",
            "com.socialuniversity.isAuthenticated",
            "com.socialuniversity.userId",
            "com.socialuniversity.userEmail",
            "com.socialuniversity.userName",
            "com.socialuniversity.userSurname",
            "com.socialuniversity.userStudentNumber"
        ]
        
        for key in keysToRemove {
            userDefaults.removeObject(forKey: key)
        }
        
        userDefaults.synchronize()
        print("UserDefaults temizlendi")
    }
    
    /// Mevcut UserDefaults değerlerini console'a yazdırır
    static func debugUserDefaults() {
        let userDefaults = UserDefaults.standard
        let keys = [
            "com.socialuniversity.university",
            "com.socialuniversity.department",
            "com.socialuniversity.isAuthenticated",
            "com.socialuniversity.userId",
            "com.socialuniversity.userEmail",
            "com.socialuniversity.userName",
            "com.socialuniversity.userSurname",
            "com.socialuniversity.userStudentNumber"
        ]
        
        print("=== UserDefaults Debug ===")
        for key in keys {
            let value = userDefaults.object(forKey: key) ?? "nil"
            print("\(key): \(value)")
        }
        print("========================")
    }
} 
