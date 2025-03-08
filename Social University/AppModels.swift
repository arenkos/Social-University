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
public final class Course {
    @Attribute(.unique) public var id: String
    public var courseCode: String
    public var courseName: String
    public var departmentName: String
    
    public init(id: String, courseCode: String, courseName: String, departmentName: String) {
        self.id = id
        self.courseCode = courseCode
        self.courseName = courseName
        self.departmentName = departmentName
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