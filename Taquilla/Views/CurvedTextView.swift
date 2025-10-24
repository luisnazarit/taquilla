import SwiftUI

struct CurvedTextView: View {
  let curvedText: CurvedTextElement
  let onDrag: (CGSize) -> Void
  let onScale: (CGFloat) -> Void
  let onTap: () -> Void
  
  @State private var lastDragPosition: CGSize = .zero
  @State private var currentMagnification: CGFloat = 1.0
  
  var body: some View {
    ZStack {
      // Renderizar cada letra siguiendo el path con escala y offset aplicados
      ForEach(Array(curvedText.text.enumerated()), id: \.offset) { index, character in
        if let letterInfo = calculateLetterPosition(for: index) {
          Text(String(character))
            .font(.system(size: curvedText.fontSize * curvedText.scale, weight: curvedText.fontWeight))
            .foregroundColor(curvedText.color)
            .rotationEffect(Angle(radians: Double(letterInfo.angle)), anchor: .center)
            .position(
              x: letterInfo.point.x + curvedText.offset.width,
              y: letterInfo.point.y + curvedText.offset.height
            )
        }
      }
    }
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
            let sensitivity: CGFloat = 0.2
            let delta = (value - currentMagnification) * sensitivity
            currentMagnification = value
            
            let newScale = curvedText.scale + delta
            onScale(newScale / curvedText.scale)
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
  
  private func calculateBounds() -> CGRect {
    guard !curvedText.path.isEmpty else {
      return CGRect(x: 0, y: 0, width: 100, height: 100)
    }
    
    var minX = curvedText.path[0].x
    var maxX = curvedText.path[0].x
    var minY = curvedText.path[0].y
    var maxY = curvedText.path[0].y
    
    for point in curvedText.path {
      minX = min(minX, point.x)
      maxX = max(maxX, point.x)
      minY = min(minY, point.y)
      maxY = max(maxY, point.y)
    }
    
    // Agregar padding para el tamaño del texto
    let padding = curvedText.fontSize * 2
    return CGRect(
      x: minX - padding,
      y: minY - padding,
      width: (maxX - minX) + padding * 2,
      height: (maxY - minY) + padding * 2
    )
  }
  
  private func calculateLetterPosition(for index: Int) -> (point: CGPoint, angle: CGFloat)? {
    let pathLength = PathUtilities.pathLength(curvedText.path)
    guard pathLength > 0 else { return nil }
    
    let textCount = CGFloat(curvedText.text.count)
    guard textCount > 0 else { return nil }
    
    // Calcular ancho real del texto para usarlo como base
    let font = UIFont.systemFont(ofSize: curvedText.fontSize, weight: convertToUIFontWeight(curvedText.fontWeight))
    let fullText = curvedText.text as NSString
    let attributes: [NSAttributedString.Key: Any] = [.font: font]
    let textWidth = fullText.size(withAttributes: attributes).width
    
    // Si el texto cabe en el path, usar su ancho real
    // Si no, distribuir uniformemente
    let useRealWidth = textWidth < pathLength * 0.9
    
    if useRealWidth {
      // Usar anchos reales
      let characters = Array(curvedText.text)
      var characterWidths: [CGFloat] = []
      var totalWidth: CGFloat = 0
      
      for char in characters {
        let charString = String(char) as NSString
        let width = charString.size(withAttributes: attributes).width
        characterWidths.append(width)
        totalWidth += width
      }
      
      let startOffset = (pathLength - totalWidth) / 2
      var currentDistance = startOffset
      
      for i in 0..<index {
        currentDistance += characterWidths[i]
      }
      
      if index < characterWidths.count {
        currentDistance += characterWidths[index] / 2
      }
      
      return PathUtilities.pointAtDistance(curvedText.path, distance: currentDistance)
    } else {
      // Distribuir uniformemente
      let spacing = pathLength / textCount
      let distance = spacing * CGFloat(index) + (spacing / 2)
      
      return PathUtilities.pointAtDistance(curvedText.path, distance: distance)
    }
  }
  
  private func convertToUIFontWeight(_ fontWeight: Font.Weight) -> UIFont.Weight {
    switch fontWeight {
    case .ultraLight: return .ultraLight
    case .thin: return .thin
    case .light: return .light
    case .regular: return .regular
    case .medium: return .medium
    case .semibold: return .semibold
    case .bold: return .bold
    case .heavy: return .heavy
    case .black: return .black
    default: return .regular
    }
  }
}

