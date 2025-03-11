//
//  APIService.swift
//  Social University
//
//  Created by Aren Koş on 8.03.2025.
//

import Foundation
import SwiftData

// AppCore.swift dosyasını import ediyoruz
// @_exported import struct MicrosoftAuthManager.UserInfo

class APIService {
    static let shared = APIService()
    
    private let baseURL = "https://aryazilimdanismanlik.com/social" // Sunucu adresi
    private let session = URLSession.shared
    
    private init() {}
    
    // MARK: - Kullanıcı İşlemleri
    
    func login(userInfo: MicrosoftAuthManager.UserInfo, completion: @escaping (Result<Social_University.User, Error>) -> Void) {
        // Microsoft kimlik doğrulama ile alınan bilgileri kullanarak kullanıcı oluştur
        let user = Social_University.User(
            id: userInfo.id,
            email: userInfo.email,
            name: userInfo.name,
            surname: userInfo.surname,
            studentNumber: userInfo.studentNumber,
            department: userInfo.department
        )
        
        // Başarılı yanıt döndür
        completion(.success(user))
    }
    
    // MARK: - Ders İşlemleri
    
    func getDepartments(university: String, completion: @escaping (Result<[String], Error>) -> Void) {
        var urlComponents = URLComponents(string: "\(baseURL)/get_courses.php")!
        
        let queryItems: [URLQueryItem] = [
            URLQueryItem(name: "university", value: university),
            URLQueryItem(name: "get_departments_only", value: "true")
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
                      let departments = responseData["departments"] as? [String] else {
                    throw NSError(domain: "APIService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Bölüm bilgileri alınamadı"])
                }
                
                DispatchQueue.main.async {
                    completion(.success(departments))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
        
        task.resume()
    }
    
    func getCourses(studentId: String? = nil, search: String? = nil, department: String? = nil, university: String? = nil, completion: @escaping (Result<([Social_University.Course], [String]), Error>) -> Void) {
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
                
                var courses: [Social_University.Course] = []
                
                for courseData in coursesData {
                    guard let courseCode = courseData["course_code"] as? String,
                          let courseName = courseData["course_name"] as? String,
                          let departmentName = courseData["course_department"] as? String else {
                        continue
                    }
                    
                    // Öğrencinin derse kayıtlı olup olmadığını kontrol et
                    let isEnrolled = courseData["is_enrolled"] as? Bool ?? false
                    
                    let course = Social_University.Course(
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
    
    func getMessages(courseCode: String, completion: @escaping (Result<[Social_University.Message], Error>) -> Void) {
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
                
                var messages: [Social_University.Message] = []
                
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
                    
                    let message = Social_University.Message(
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
    
    func sendMessage(courseCode: String, message: String, studentId: String?, completion: @escaping (Result<Social_University.Message, Error>) -> Void) {
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
                
                let message = Social_University.Message(
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
