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
            }
            .padding()
            .onAppear {
                // 2 saniye sonra otomatik yönlendirme
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    isShowingLoginView = true
                }
            }
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
