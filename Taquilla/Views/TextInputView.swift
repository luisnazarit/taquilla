import SwiftUI

struct TextInputView: View {
  @Binding var text: String
  let fontStyle: FontStyle
  let onDone: () -> Void
  let onCancel: () -> Void
  @FocusState private var isFocused: Bool
  
  private let maxCharacters = 100
  
  var remainingCharacters: Int {
    maxCharacters - text.count
  }
  
  var body: some View {
    NavigationView {
      VStack(spacing: 20) {
        Spacer()
        
        // Campo de entrada multilínea - usando directamente la fuente personalizada
        ZStack(alignment: .topLeading) {
          TextEditor(text: $text)
            .font(fontStyle.customFontName != nil 
                  ? .custom(fontStyle.customFontName!, size: fontStyle.size)
                  : .system(size: fontStyle.size, weight: fontStyle.weight))
            .foregroundColor(fontStyle.color)
            .scrollContentBackground(.hidden)
            .background(Color.white.opacity(0.05))
            .cornerRadius(10)
            .padding(.horizontal, 20)
            .frame(minHeight: 150, maxHeight: 250)
            .focused($isFocused)
            .onChange(of: text) { oldValue, newValue in
              if newValue.count > maxCharacters {
                text = String(newValue.prefix(maxCharacters))
              }
            }
            .onAppear {
              // Debug: imprimir qué fuente estamos usando
              if let fontName = fontStyle.customFontName {
                print("🔤 Fuente personalizada: \(fontName)")
                // Verificar si la fuente existe
                if UIFont(name: fontName, size: fontStyle.size) != nil {
                  print("✅ Fuente cargada correctamente")
                } else {
                  print("❌ ERROR: Fuente '\(fontName)' no encontrada")
                  print("Fuentes disponibles que contienen '\(fontName)':")
                  for family in UIFont.familyNames {
                    let fonts = UIFont.fontNames(forFamilyName: family)
                    for font in fonts {
                      if font.lowercased().contains(fontName.lowercased()) {
                        print("  - \(font)")
                      }
                    }
                  }
                }
              } else {
                print("📝 Usando fuente del sistema")
              }
            }
        }
        
        Text("\(remainingCharacters) caracteres restantes")
          .font(.caption)
          .foregroundColor(remainingCharacters < 20 ? .red : .white.opacity(0.7))
        
        Spacer()
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(Color.black.opacity(0.9))
      .navigationTitle("")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Cancelar") {
            onCancel()
          }
          .foregroundColor(.white)
        }
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Listo") {
            onDone()
          }
          .foregroundColor(.white)
          .fontWeight(.bold)
        }
      }
      .toolbarBackground(Color.black.opacity(0.9), for: .navigationBar)
      .toolbarBackground(.visible, for: .navigationBar)
      .onAppear {
        // Pequeño delay para asegurar que el keyboard aparezca
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
          isFocused = true
        }
      }
    }
  }
}

