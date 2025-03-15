import Foundation
import SwiftData

@Model
public final class User {
    @Attribute(.unique) public var id: String
    public var email: String
    public var name: String
    public var surname: String
    public var studentNumber: String
    public var department: String
    public var university: String
    
    public init(id: String, email: String, name: String, surname: String, studentNumber: String, department: String, university: String = "") {
        self.id = id
        self.email = email
        self.name = name
        self.surname = surname
        self.studentNumber = studentNumber
        self.department = department
        self.university = university
    }
} 