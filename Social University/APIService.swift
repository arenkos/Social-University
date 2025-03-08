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
    
    private let baseURL = "https://your-server.com/api" // Sunucu adresinizi buraya yazın
    private let session = URLSession.shared
    
    private init() {}
    
    // MARK: - Kullanıcı İşlemleri
    
    func login(email: String, completion: @escaping (Result<Social_University.User, Error>) -> Void) {
        let url = URL(string: "\(baseURL)/login.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["email": email]
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
                
                guard let status = json?["status"] as? Bool, status else {
                    let message = json?["message"] as? String ?? "Bilinmeyen hata"
                    throw NSError(domain: "APIService", code: 0, userInfo: [NSLocalizedDescriptionKey: message])
                }
                
                guard let userData = json?["data"] as? [String: Any],
                      let userInfo = userData["user"] as? [String: Any],
                      let id = userInfo["id"] as? String,
                      let email = userInfo["email"] as? String,
                      let name = userInfo["name"] as? String,
                      let surname = userInfo["surname"] as? String,
                      let studentNumber = userInfo["studentNumber"] as? String,
                      let department = userInfo["department"] as? String else {
                    throw NSError(domain: "APIService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Kullanıcı bilgileri alınamadı"])
                }
                
                let user = Social_University.User(
                    id: id,
                    email: email,
                    name: name,
                    surname: surname,
                    studentNumber: studentNumber,
                    department: department
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
    
    // MARK: - Ders İşlemleri
    
    func getCourses(userId: String? = nil, search: String? = nil, department: String? = nil, completion: @escaping (Result<([Social_University.Course], [String]), Error>) -> Void) {
        var urlComponents = URLComponents(string: "\(baseURL)/courses.php")!
        
        var queryItems: [URLQueryItem] = []
        
        if let userId = userId {
            queryItems.append(URLQueryItem(name: "user_id", value: userId))
        }
        
        if let search = search, !search.isEmpty {
            queryItems.append(URLQueryItem(name: "search", value: search))
        }
        
        if let department = department, !department.isEmpty {
            queryItems.append(URLQueryItem(name: "department", value: department))
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
                
                guard let status = json?["status"] as? Bool, status else {
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
                    guard let id = courseData["id"] as? String,
                          let courseCode = courseData["course_code"] as? String,
                          let courseName = courseData["course_name"] as? String,
                          let departmentName = courseData["department_name"] as? String else {
                        continue
                    }
                    
                    let course = Social_University.Course(
                        id: id,
                        courseCode: courseCode,
                        courseName: courseName,
                        departmentName: departmentName
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
    
    func enrollCourse(userId: String, courseId: String, action: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let url = URL(string: "\(baseURL)/enroll.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "user_id": userId,
            "course_id": courseId,
            "action": action // "enroll" veya "unenroll"
        ]
        
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
                
                guard let status = json?["status"] as? Bool, status else {
                    let message = json?["message"] as? String ?? "Bilinmeyen hata"
                    throw NSError(domain: "APIService", code: 0, userInfo: [NSLocalizedDescriptionKey: message])
                }
                
                DispatchQueue.main.async {
                    completion(.success(()))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
        
        task.resume()
    }
    
    // MARK: - Mesaj İşlemleri
    
    func getMessages(courseId: String, lastId: String? = nil, completion: @escaping (Result<[Social_University.Message], Error>) -> Void) {
        var urlComponents = URLComponents(string: "\(baseURL)/messages.php")!
        
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "course_id", value: courseId)
        ]
        
        if let lastId = lastId {
            queryItems.append(URLQueryItem(name: "last_id", value: lastId))
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
                
                guard let status = json?["status"] as? Bool, status else {
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
                          let content = messageData["content"] as? String,
                          let timestampString = messageData["timestamp"] as? String,
                          let courseId = messageData["course_id"] as? String else {
                        continue
                    }
                    
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    let timestamp = dateFormatter.date(from: timestampString) ?? Date()
                    
                    let senderId = messageData["sender_id"] as? String
                    
                    let message = Social_University.Message(
                        id: id,
                        content: content,
                        timestamp: timestamp,
                        senderId: senderId,
                        courseId: courseId
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
    
    func sendMessage(courseId: String, content: String, senderId: String?, completion: @escaping (Result<Social_University.Message, Error>) -> Void) {
        let url = URL(string: "\(baseURL)/messages.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var body: [String: Any] = [
            "course_id": courseId,
            "content": content
        ]
        
        if let senderId = senderId {
            body["sender_id"] = senderId
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
                
                guard let status = json?["status"] as? Bool, status else {
                    let message = json?["message"] as? String ?? "Bilinmeyen hata"
                    throw NSError(domain: "APIService", code: 0, userInfo: [NSLocalizedDescriptionKey: message])
                }
                
                guard let responseData = json?["data"] as? [String: Any],
                      let messageData = responseData["message"] as? [String: Any],
                      let id = messageData["id"] as? String,
                      let content = messageData["content"] as? String,
                      let timestampString = messageData["timestamp"] as? String,
                      let courseId = messageData["course_id"] as? String else {
                    throw NSError(domain: "APIService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Mesaj bilgileri alınamadı"])
                }
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                let timestamp = dateFormatter.date(from: timestampString) ?? Date()
                
                let senderId = messageData["sender_id"] as? String
                
                let message = Social_University.Message(
                    id: id,
                    content: content,
                    timestamp: timestamp,
                    senderId: senderId,
                    courseId: courseId
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