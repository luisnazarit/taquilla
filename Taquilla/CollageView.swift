import SwiftUI

struct CollageView: View {
    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "grid")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                
                Text("Crear Collage")
                    .font(.title)
                    .fontWeight(.semibold)
                    .padding(.top)
                
                Text("Esta funcionalidad estará disponible próximamente")
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .navigationTitle("Collage")
        }
    }
}

#Preview {
    CollageView()
}
