import SwiftUI

struct CurvedTextInputView: View {
  @Binding var text: String
  let path: [CGPoint]
  let onDone: (FontStyle?) -> Void
  let onCancel: () -> Void
  let initialFontStyle: FontStyle? // Fuente inicial para edición
  @FocusState private var isFocused: Bool
  @State private var selectedFontStyle: FontStyle?
  @State private var showingFontMenu = false
  
  private let maxCharacters = 50
  
  // Inicializador personalizado
  init(text: Binding<String>, path: [CGPoint], onDone: @escaping (FontStyle?) -> Void, onCancel: @escaping () -> Void, initialFontStyle: FontStyle? = nil) {
    self._text = text
    self.path = path
    self.onDone = onDone
    self.onCancel = onCancel
    self.initialFontStyle = initialFontStyle
  }
  
  var remainingCharacters: Int {
    maxCharacters - text.count
  }
  
  var body: some View {
    NavigationView {
      VStack(spacing: 16) {
        Spacer()
        
        // Vista previa de la línea
        ZStack {
          Canvas { context, size in
            if !path.isEmpty {
              let pathShape = PathUtilities.createPath(from: path)
              context.stroke(
                pathShape,
                with: .color(.blue.opacity(0.5)),
                lineWidth: 2
              )
            }
          }
          .frame(height: 200)
          .padding()
        }
        
        TextField("Escribe tu texto aquí", text: $text)
          .font(.title3)
          .foregroundColor(.white)
          .multilineTextAlignment(.center)
          .padding()
          .focused($isFocused)
          .onChange(of: text) { oldValue, newValue in
            if newValue.count > maxCharacters {
              text = String(newValue.prefix(maxCharacters))
            }
          }
        
        // Botón para seleccionar fuente
        Button(action: {
          showingFontMenu = true
        }) {
          HStack {
            Image(systemName: "textformat")
              .font(.title2)
            Text(selectedFontStyle?.name ?? "Seleccionar fuente")
              .font(.body)
          }
          .foregroundColor(.white)
          .padding(.horizontal, 20)
          .padding(.vertical, 12)
          .background(Color.white.opacity(0.2))
          .cornerRadius(8)
        }
        
        Text("\(remainingCharacters) caracteres restantes")
          .font(.caption)
          .foregroundColor(remainingCharacters < 10 ? .red : .white.opacity(0.7))
          .padding(.bottom, 8)
        
        Spacer()
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(Color.black.opacity(0.8))
      .navigationTitle("Texto Curvo")
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
            onDone(selectedFontStyle)
          }
          .foregroundColor(.white)
          .fontWeight(.bold)
          .disabled(text.isEmpty)
        }
      }
      .toolbarBackground(Color.black.opacity(0.9), for: .navigationBar)
      .toolbarBackground(.visible, for: .navigationBar)
      .onAppear {
        isFocused = true
        // Establecer la fuente inicial si está disponible
        if let initialFont = initialFontStyle {
          selectedFontStyle = initialFont
        }
      }
      .sheet(isPresented: $showingFontMenu) {
        FontMenuView { fontStyle in
          selectedFontStyle = fontStyle
          print("🎨 CurvedTextInputView: Fuente seleccionada: \(fontStyle.customFontName ?? "nil")")
          showingFontMenu = false
        }
      }
    }
  }
}

