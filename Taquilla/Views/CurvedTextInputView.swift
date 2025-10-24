import SwiftUI

struct CurvedTextInputView: View {
  @Binding var text: String
  let path: [CGPoint]
  let onDone: () -> Void
  let onCancel: () -> Void
  @FocusState private var isFocused: Bool
  
  private let maxCharacters = 50
  
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
            onDone()
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
      }
    }
  }
}

