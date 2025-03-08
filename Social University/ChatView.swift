//
//  ChatView.swift
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

#if canImport(UIKit)
import UIKit
#endif

struct ChatView: View {
    @Environment(\.modelContext) private var modelContext
    @Query var messages: [Message]
    
    var user: User
    var course: Course
    
    @State private var messageText = ""
    @State private var scrollToBottom = false
    @FocusState private var isTextFieldFocused: Bool
    
    init(user: User, course: Course) {
        self.user = user
        self.course = course
        
        // Sorguyu bu derse ait mesajlarla sınırla
        let courseId = course.id
        let predicate = #Predicate<Message> { message in
            message.courseId == courseId
        }
        let sort = [SortDescriptor(\Message.timestamp, order: .forward)]
        self._messages = Query(filter: predicate, sort: sort)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Sohbet başlığı
            HStack {
                VStack(alignment: .leading) {
                    Text(course.courseName)
                        .font(.headline)
                    Text(course.courseCode)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            
            // Mesaj listesi
            ScrollViewReader { scrollView in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(messages) { message in
                            MessageBubble(message: message, isCurrentUser: message.senderId == user.id, user: user)
                                .id(message.id)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                .onChange(of: messages.count) { _, _ in
                    scrollToBottom = true
                }
                .onChange(of: scrollToBottom) { _, newValue in
                    if newValue, let lastMessage = messages.last {
                        withAnimation {
                            scrollView.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                        scrollToBottom = false
                    }
                }
                .onAppear {
                    if let lastMessage = messages.last {
                        scrollView.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
            
            // Mesaj giriş alanı
            HStack {
                TextField("Mesajınızı yazın...", text: $messageText)
                    .padding(10)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(20)
                    .focused($isTextFieldFocused)
                
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.blue)
                        .padding(10)
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
            .shadow(radius: 1)
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if messages.isEmpty {
                addSampleMessages()
            }
        }
    }
    
    private func sendMessage() {
        let trimmedText = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !trimmedText.isEmpty {
            let newMessage = Message(
                id: UUID().uuidString,
                content: trimmedText,
                timestamp: Date(),
                senderId: user.id,
                courseId: course.id
            )
            
            modelContext.insert(newMessage)
            messageText = ""
            scrollToBottom = true
        }
    }
    
    private func addSampleMessages() {
        // Örnek mesajlar ekle
        let sampleMessages = [
            Message(
                id: UUID().uuidString,
                content: "Merhaba, bu derse hoş geldiniz!",
                timestamp: Date().addingTimeInterval(-3600 * 24),
                senderId: nil,
                courseId: course.id
            ),
            Message(
                id: UUID().uuidString,
                content: "Ödev teslim tarihi ne zaman?",
                timestamp: Date().addingTimeInterval(-3600 * 12),
                senderId: user.id,
                courseId: course.id
            ),
            Message(
                id: UUID().uuidString,
                content: "Ödevler gelecek hafta Cuma günü teslim edilecek.",
                timestamp: Date().addingTimeInterval(-3600 * 6),
                senderId: nil,
                courseId: course.id
            )
        ]
        
        for message in sampleMessages {
            modelContext.insert(message)
        }
    }
}

struct MessageBubble: View {
    var message: Message
    var isCurrentUser: Bool
    var user: User
    
    var body: some View {
        HStack {
            if isCurrentUser {
                Spacer()
            }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 2) {
                if let _ = message.senderId {
                    Text(isCurrentUser ? "\(user.name) \(user.surname)" : "Diğer Kullanıcı")
                        .font(.caption)
                        .foregroundColor(isCurrentUser ? .white.opacity(0.8) : .black.opacity(0.8))
                } else {
                    Text("Sistem")
                        .font(.caption)
                        .foregroundColor(isCurrentUser ? .white.opacity(0.8) : .black.opacity(0.8))
                }
                
                Text(message.content)
                    .padding(10)
                    .background(isCurrentUser ? Color.blue : Color.gray.opacity(0.2))
                    .foregroundColor(isCurrentUser ? .white : .black)
                    .cornerRadius(16)
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if !isCurrentUser {
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    VStack {
        Text("Preview için ChatView")
            .font(.headline)
        
        Text("Gerçek bir önizleme için Xcode'da projeyi çalıştırın")
            .font(.subheadline)
            .foregroundColor(.secondary)
    }
    .padding()
} 
