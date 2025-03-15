//
//  ContentView.swift
//  Social University
//
//  Created by Aren Koş on 8.03.2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var isShowingLoginView = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "graduationcap.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .foregroundColor(.blue)
                
                Text("Sosyal Üniversite")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Üniversite öğrencileri için sohbet uygulaması")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Button(action: {
                    isShowingLoginView = true
                }) {
                    Text("Giriş Yap")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.horizontal, 40)
                .padding(.top, 20)
            }
            .padding()
            .navigationDestination(isPresented: $isShowingLoginView) {
                LoginView()
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(AppSchema.modelContainer())
}
