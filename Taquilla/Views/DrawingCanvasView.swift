import SwiftUI

struct DrawingCanvasView: View {
  @Binding var currentPath: [CGPoint]
  @Binding var drawingMode: DrawingMode
  let onFinish: ([CGPoint]) -> Void
  
  var body: some View {
    ZStack {
      // Canvas para dibujar
      Canvas { context, size in
        if !currentPath.isEmpty {
          let path = PathUtilities.createPath(from: currentPath)
          context.stroke(
            path,
            with: .color(.blue),
            lineWidth: 3
          )
          
          // Dibujar puntos de inicio y fin
          if let first = currentPath.first {
            context.fill(
              Path(ellipseIn: CGRect(x: first.x - 5, y: first.y - 5, width: 10, height: 10)),
              with: .color(.green)
            )
          }
          
          if let last = currentPath.last, currentPath.count > 1 {
            context.fill(
              Path(ellipseIn: CGRect(x: last.x - 5, y: last.y - 5, width: 10, height: 10)),
              with: .color(.red)
            )
          }
        }
      }
      .gesture(
        DragGesture(minimumDistance: 0)
          .onChanged { value in
            if drawingMode == .none {
              drawingMode = .drawing
              currentPath = [value.location]
            } else if drawingMode == .drawing {
              currentPath.append(value.location)
            }
          }
          .onEnded { _ in
            if drawingMode == .drawing && currentPath.count > 1 {
              drawingMode = .finished
              // Simplificar el path antes de finalizar
              let simplifiedPath = PathUtilities.simplifyPath(currentPath, tolerance: 3.0)
              onFinish(simplifiedPath)
            }
          }
      )
    }
  }
}

