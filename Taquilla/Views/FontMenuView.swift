import SwiftUI

struct FontStyle: Identifiable {
  let id = UUID()
  let name: String
  let size: CGFloat
  let weight: Font.Weight
  let color: Color
  let customFontName: String? // Nombre de la fuente personalizada
  let shadows: [ShadowStyle] // Sombras para efectos
  let backgroundOpacity: CGFloat // Opacidad del fondo
  let cornerRadius: CGFloat // Radio de las esquinas
}

struct ShadowStyle: Identifiable {
  let id = UUID()
  let color: Color
  let radius: CGFloat
  let x: CGFloat
  let y: CGFloat
}

struct FontMenuView: View {
  let onFontSelected: (FontStyle) -> Void
  @Environment(\.dismiss) private var dismiss
  
  private let fontStyles: [FontStyle] = [
    // Dogica Pixel - Fondo 100% negro sin bordes redondeados
    FontStyle(
      name: "Dogica Pixel",
      size: 28,
      weight: .regular,
      color: .white,
      customFontName: "Dogica_Pixel",
      shadows: [],
      backgroundOpacity: 1.0,
      cornerRadius: 0
    ),
    // Dogica Bold - Fondo 100% negro sin bordes redondeados
    FontStyle(
      name: "Dogica Bold",
      size: 28,
      weight: .bold,
      color: .white,
      customFontName: "Dogica_Pixel_Bold",
      shadows: [],
      backgroundOpacity: 1.0,
      cornerRadius: 0
    ),
    // Retrock - Sombra sutil, sin marco
    FontStyle(
      name: "Retrock",
      size: 36,
      weight: .regular,
      color: .white,
      customFontName: "Retrock",
      shadows: [
        ShadowStyle(color: .black.opacity(0.5), radius: 4, x: 2, y: 2)
      ],
      backgroundOpacity: 0,
      cornerRadius: 0
    ),
    // Returns - Triple sombra dura hacia abajo (negro, cyan, magenta)
    FontStyle(
      name: "Returns",
      size: 36,
      weight: .regular,
      color: .white,
      customFontName: "Returns",
      shadows: [
        ShadowStyle(color: .black, radius: 0, x: 6, y: 6),
        ShadowStyle(color: .cyan, radius: 0, x: 4, y: 4),
        ShadowStyle(color: Color(red: 1.0, green: 0.0, blue: 1.0), radius: 0, x: 2, y: 2) // Magenta
      ],
      backgroundOpacity: 0,
      cornerRadius: 0
    ),
    // Ari Display - Fuente moderna y limpia
    FontStyle(
      name: "Ari Display",
      size: 34,
      weight: .regular,
      color: .white,
      customFontName: "Ari-W9500Display",
      shadows: [],
      backgroundOpacity: 0,
      cornerRadius: 0
    ),
    // Ari Bold - Fuente moderna en negrita
    FontStyle(
      name: "Ari Bold",
      size: 34,
      weight: .bold,
      color: .white,
      customFontName: "Ari-W9500Bold",
      shadows: [],
      backgroundOpacity: 0,
      cornerRadius: 0
    ),
  ]
  
  var body: some View {
    NavigationView {
      VStack(spacing: 20) {
        Text("Elige un estilo de texto")
          .font(.title2)
          .fontWeight(.semibold)
          .padding(.top)
        
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 20) {
          ForEach(fontStyles, id: \.name) { fontStyle in
            Button(action: {
              onFontSelected(fontStyle)
            }) {
              VStack(spacing: 8) {
                Text("Aa")
                  .font(fontStyle.customFontName != nil 
                        ? .custom(fontStyle.customFontName!, size: 32)
                        : .system(size: 32, weight: fontStyle.weight))
                  .foregroundColor(fontStyle.color)
                  .frame(width: 80, height: 80)
                  .background(
                    RoundedRectangle(cornerRadius: 12)
                      .fill(Color.gray.opacity(0.2))
                  )
                
                Text(fontStyle.name)
                  .font(.caption)
                  .foregroundColor(.primary)
              }
            }
            .buttonStyle(PlainButtonStyle())
          }
        }
        .padding(.horizontal)
        
        Spacer()
      }
      .navigationTitle("Tipos de Letra")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Cerrar") {
            dismiss()
          }
        }
      }
    }
  }
}

