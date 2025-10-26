import SwiftUI

struct FilterPreviewView: View {
  let filter: PhotoFilter
  let isSelected: Bool
  let onTap: () -> Void

  var body: some View {
    VStack(spacing: 8) {
      // Vista previa del filtro
      RoundedRectangle(cornerRadius: 8)
        .fill(Color.clear) // Fondo transparente
        .frame(width: 50, height: 50)
        .overlay(
          RoundedRectangle(cornerRadius: 8)
            .stroke(
              isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: isSelected ? 3 : 1)
        )
        .overlay(
          Image(systemName: filterIcon)
            .font(.title2)
            .foregroundColor(.white)
        )
        .padding(isSelected ? 2 : 0) // Padding adicional cuando está seleccionado para evitar que se corte el borde

      // Nombre del filtro
      Text(filter.name)
        .font(.system(size: 10))
        .foregroundColor(isSelected ? .blue : .primary)
        .multilineTextAlignment(.center)
    }
    .onTapGesture {
      onTap()
    }
  }

  private var filterIcon: String {
    switch filter {
    case .none: return "photo"
    case .sepia: return "sun.max"
    case .vivid: return "sparkles"
    case .gritty: return "cube"
    case .kodak: return "cube"
    case .lut2: return "cube"
    }
  }
}

#Preview {
  HStack {
    FilterPreviewView(
      filter: .none,
      isSelected: true,
      onTap: {}
    )
  }
  .padding()
}
