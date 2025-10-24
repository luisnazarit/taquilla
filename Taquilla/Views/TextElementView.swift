import SwiftUI

struct TextElementView: View {
  let textElement: TextElement
  let onDrag: (CGSize) -> Void
  let onScale: (CGFloat) -> Void
  let onTap: () -> Void
  
  @State private var lastDragPosition: CGSize = .zero
  @State private var currentMagnification: CGFloat = 1.0
  
  // Área de toque mínima que se mantiene incluso cuando el texto es pequeño
  private var minimumTouchArea: CGFloat {
    // Cuando el texto es pequeño (scale < 1.0), el área es más grande
    if textElement.scale < 1.0 {
      return 100  // Área grande para facilitar el agarre
    } else {
      return max(40, 30 * textElement.scale)
    }
  }
  
  var body: some View {
    ZStack {
      // Aplicar múltiples sombras
      ForEach(Array(textElement.shadows.enumerated()), id: \.offset) { index, shadow in
        Text(textElement.text)
          .font(textElement.customFontName != nil 
                ? .custom(textElement.customFontName!, size: textElement.fontSize)
                : .system(size: textElement.fontSize, weight: textElement.fontWeight))
          .foregroundColor(shadow.color)
          .multilineTextAlignment(.center)
          .fixedSize() // Mantener tamaño natural sin restricciones
          .blur(radius: shadow.radius)
          .offset(x: shadow.x, y: shadow.y)
      }
      
      // Texto principal
      Text(textElement.text)
        .font(textElement.customFontName != nil 
              ? .custom(textElement.customFontName!, size: textElement.fontSize)
              : .system(size: textElement.fontSize, weight: textElement.fontWeight))
        .foregroundColor(textElement.color)
        .multilineTextAlignment(.center)
        .fixedSize() // Mantener tamaño natural sin restricciones
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 6)
    .background(
      textElement.backgroundOpacity > 0 
        ? Color.black.opacity(textElement.backgroundOpacity)
        : Color.clear
    )
    .cornerRadius(textElement.cornerRadius)
    .padding(minimumTouchArea)
    .contentShape(Rectangle())
    .scaleEffect(textElement.scale)
    .position(textElement.position)
      .gesture(
        SimultaneousGesture(
          DragGesture()
            .onChanged { value in
              let translation = CGSize(
                width: value.translation.width - lastDragPosition.width,
                height: value.translation.height - lastDragPosition.height
              )
              lastDragPosition = value.translation
              onDrag(translation)
            }
            .onEnded { _ in
              lastDragPosition = .zero
            },
          MagnificationGesture()
            .onChanged { value in
              // Sensibilidad muy reducida para cambios suaves y graduales
              let sensitivity: CGFloat = 0.2
              let delta = (value - currentMagnification) * sensitivity
              currentMagnification = value
              
              // Aplicar el cambio incremental
              let newScale = textElement.scale + delta
              onScale(newScale / textElement.scale)
            }
            .onEnded { _ in
              currentMagnification = 1.0
            }
        )
      )
      .onTapGesture {
        onTap()
      }
  }
}

