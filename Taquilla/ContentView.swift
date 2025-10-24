import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            PhotoEditorView()
                .tabItem {
                    Image(systemName: "photo")
                    Text("Editor")
                }
                .tag(0)
            
            CollageView()
                .tabItem {
                    Image(systemName: "grid")
                    Text("Collage")
                }
                .tag(1)
            
            GalleryView()
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
