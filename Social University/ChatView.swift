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
    @State private var isLoading = false
    @State private var errorMessage: String?
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
        VStack {
            if isLoading {
                ProgressView()
                    .padding()
            } else if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            } else if messages.isEmpty {
                VStack {
                    Spacer()
                    Text("Henüz mesaj yok")
                        .foregroundColor(.gray)
                    Spacer()
                }
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 10) {
                            ForEach(messages) { message in
                                MessageBubble(message: message, isCurrentUser: message.senderId == user.studentNumber)
                                    .id(message.id)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                    .onChange(of: messages.count) {
                        if scrollToBottom {
                            if let lastMessage = messages.last {
                                withAnimation {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                            scrollToBottom = false
                        }
                    }
                    .onChange(of: scrollToBottom) {
                        if scrollToBottom, let lastMessage = messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                    .onAppear {
                        loadMessages()
                        if let lastMessage = messages.last {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
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
        .navigationTitle(course.courseName)
    }
    
    private func loadMessages() {
        isLoading = true
        errorMessage = nil
        
        APIService.shared.getMessages(courseCode: course.courseCode) { result in
            isLoading = false
            
            switch result {
            case .success(let fetchedMessages):
                // Mevcut mesajları temizle
                for message in messages {
                    modelContext.delete(message)
                }
                
                // Yeni mesajları ekle
                for message in fetchedMessages {
                    modelContext.insert(message)
                }
                
                // Otomatik kaydırma
                scrollToBottom = true
                
            case .failure(let error):
                errorMessage = "Mesajlar yüklenemedi: \(error.localizedDescription)"
            }
        }
    }
    
    private func sendMessage() {
        let trimmedText = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !trimmedText.isEmpty {
            isLoading = true
            errorMessage = nil
            
            APIService.shared.sendMessage(courseCode: course.courseCode, message: trimmedText, studentId: user.studentNumber) { result in
                isLoading = false
                
                switch result {
                case .success(let newMessage):
                    // Yeni mesajı ekle
                    modelContext.insert(newMessage)
                    messageText = ""
                    scrollToBottom = true
                    
                case .failure(let error):
                    errorMessage = "Mesaj gönderilemedi: \(error.localizedDescription)"
                }
            }
        }
    }
}

struct MessageBubble: View {
    let message: Message
    let isCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isCurrentUser {
                Spacer()
            }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(10)
                    .background(isCurrentUser ? Color.blue : Color.gray.opacity(0.2))
                    .foregroundColor(isCurrentUser ? .white : .black)
                    .cornerRadius(16)
                
                Text(formatDate(message.timestamp))
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 8)
            }
            
            if !isCurrentUser {
                Spacer()
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
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
