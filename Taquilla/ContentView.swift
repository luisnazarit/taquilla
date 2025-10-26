import SwiftUI

struct ContentView: View {
    @StateObject private var photoManager = PhotoManager()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            PhotoEditorView()
                .environmentObject(photoManager)
                .tabItem {
                    Image(systemName: "photo")
                    Text("Editor")
                }
                .tag(0)
            
            CollageView()
                .environmentObject(photoManager)
                .tabItem {
                    Image(systemName: "grid")
                    Text("Collage")
                }
                .tag(1)
            
            GalleryView()
                .environmentObject(photoManager)
                .tabItem {
                    Image(systemName: "photo.on.rectangle")
                    Text("Galería")
                }
                .tag(2)
        }
        .accentColor(.blue)
    }
}

#Preview {
    ContentView()
}
