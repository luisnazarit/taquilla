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

      CreditsTabView()
        .tabItem {
          Image(systemName: "heart.fill")
          Text("Créditos")
        }
        .tag(2)
    }
    .accentColor(.blue)
  }
}

// MARK: - Credits View
extension ContentView {
  struct CreditsTabView: View {
    var body: some View {
      NavigationView {
        ZStack {
          // Fondo de la aplicación
          Image("Background")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .ignoresSafeArea()

          ScrollView {
            VStack(spacing: 30) {

              // Logo
              Image("Logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 200, height: 200)
                .padding(.horizontal, 40)

              // Texto de agradecimiento
              VStack(spacing: 20) {
                Text("¡Gracias por usar Taquilla!")
                  .font(.title3)
                  .fontWeight(.semibold)
                  .foregroundColor(.white)
                  .multilineTextAlignment(.center)

                Text(
                  "Taquilla es una aplicación diseñada con ❤️ en Chile para ayudarte a crear fotos increíbles con textos, filtros y plantillas únicas."
                )
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 30)

                Text(
                  "Nuestra misión es hacer que la edición de fotos sea simple, divertida y accesible para todos."
                )
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 30)
              }
              .padding(.horizontal, 30)


              // Footer
              VStack(spacing: 10) {
                Text("Desarrollado con ❤️ en Chile")
                  .font(.caption)
                  .foregroundColor(.white.opacity(0.7))

                Text("Versión 1.0")
                  .font(.caption2)
                  .foregroundColor(.white.opacity(0.5))
              }
              .padding(.top, 20)

              Spacer()
                .frame(height: 50)
            }
          }
        }
        .navigationTitle("Créditos")
        .navigationBarTitleDisplayMode(.inline)
      }
    }
  }

  struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
      HStack(spacing: 12) {
        Image(systemName: icon)
          .font(.system(size: 16))
          .foregroundColor(.white)
          .frame(width: 20)

        Text(text)
          .font(.body)
          .foregroundColor(.white.opacity(0.9))
          .multilineTextAlignment(.leading)

        Spacer()
      }
    }
  }
}

#Preview {
  ContentView()
}
