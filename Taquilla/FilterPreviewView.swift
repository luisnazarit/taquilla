import SwiftUI

struct FilterPreviewView: View {
    let filter: PhotoFilter
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            // Vista previa del filtro
            RoundedRectangle(cornerRadius: 8)
                .fill(filter.previewColor)
                .frame(width: 60, height: 60)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: isSelected ? 3 : 1)
                )
                .overlay(
                    Image(systemName: filterIcon)
                        .font(.title2)
                        .foregroundColor(.white)
                )
            
            // Nombre del filtro
            Text(filter.name)
                .font(.caption)
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
        case .vintage: return "camera.vintage"
        case .blackAndWhite: return "circle.lefthalf.filled"
        case .sepia: return "sun.max"
        case .vivid: return "sparkles"
        case .cool: return "snowflake"
        case .warm: return "flame"
        case .dramatic: return "bolt"
        case .gritty: return "cube"
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
        
        FilterPreviewView(
            filter: .vintage,
            isSelected: false,
            onTap: {}
        )
        
        FilterPreviewView(
            filter: .blackAndWhite,
            isSelected: false,
            onTap: {}
        )
    }
    .padding()
}
