import SwiftUI

struct GalleryView: View {
    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "photo.on.rectangle")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                
                Text("Galería")
                    .font(.title)
                    .fontWeight(.semibold)
                    .padding(.top)
                
                Text("Tus fotos editadas aparecerán aquí")
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .navigationTitle("Galería")
        }
    }
}

#Preview {
    GalleryView()
}
