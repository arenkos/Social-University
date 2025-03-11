import Foundation
import SwiftData

// Kullanıcı modeli
@Model
public final class User {
    @Attribute(.unique) public var id: String
    public var email: String
    public var name: String
    public var surname: String
    public var studentNumber: String
    public var department: String
    
    public init(id: String, email: String, name: String, surname: String, studentNumber: String, department: String) {
        self.id = id
        self.email = email
        self.name = name
        self.surname = surname
        self.studentNumber = studentNumber
        self.department = department
    }
}

// Ders modeli
@Model
public final class Course: Codable {
    @Attribute(.unique) public var id: String
    public var courseCode: String
    public var courseName: String
    public var departmentName: String
    public var isEnrolled: Bool?
    
    public init(id: String, courseCode: String, courseName: String, departmentName: String, isEnrolled: Bool? = nil) {
        self.id = id
        self.courseCode = courseCode
        self.courseName = courseName
        self.departmentName = departmentName
        self.isEnrolled = isEnrolled
    }
    
    // Codable için gerekli kodlama methodları
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(courseCode, forKey: .courseCode)
        try container.encode(courseName, forKey: .courseName)
        try container.encode(departmentName, forKey: .departmentName)
        try container.encode(isEnrolled, forKey: .isEnrolled)
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        courseCode = try container.decode(String.self, forKey: .courseCode)
        courseName = try container.decode(String.self, forKey: .courseName)
        departmentName = try container.decode(String.self, forKey: .departmentName)
        isEnrolled = try container.decodeIfPresent(Bool.self, forKey: .isEnrolled)
    }
    
    // SwiftData ve Codable arasındaki uyumluluk için gerekli
    private enum CodingKeys: String, CodingKey {
        case id, courseCode, courseName, departmentName, isEnrolled
    }
}

// Mesaj modeli
@Model
public final class Message {
    @Attribute(.unique) public var id: String
    public var content: String
    public var timestamp: Date
    public var senderId: String?
    public var courseId: String
    
    public init(id: String, content: String, timestamp: Date, senderId: String?, courseId: String) {
        self.id = id
        self.content = content
        self.timestamp = timestamp
        self.senderId = senderId
        self.courseId = courseId
    }
}

// Eski Item modeli (uyumluluk için)
@Model
public final class Item {
    public var timestamp: Date
    
    public init(timestamp: Date) {
        self.timestamp = timestamp
    }
} 