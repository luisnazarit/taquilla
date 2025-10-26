import SwiftUI

struct ContentView: View {
    @StateObject private var photoManager = PhotoManager()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            CollageView()
                .environmentObject(photoManager)
                .tabItem {
                    Image(systemName: "square.grid.2x2")
                    Text("Editor")
                }
                .tag(0)
            
            GalleryView()
                .environmentObject(photoManager)
                .tabItem {
                    Image(systemName: "photo.on.rectangle")
                    Text("Galería")
                }
                .tag(1)
        }
        .accentColor(.blue)
    }
}

#Preview {
    ContentView()
}
