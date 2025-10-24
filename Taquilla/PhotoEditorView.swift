import PhotosUI
import SwiftUI

struct PhotoEditorView: View {
  @State private var selectedImage: UIImage?
  @State private var showingImagePicker = false
  @State private var currentFilter: PhotoFilter = .none
  @State private var textElements: [TextElement] = []
  @State private var selectedTextElement: TextElement?
  @State private var showingTextEditor = false
  @State private var showingFilterPicker = false
  @State private var showingFontMenu = false
  @State private var editingText = ""
  @State private var showingKeyboard = false
  @State private var currentFontStyle: FontStyle?

  // Curved text states
  @State private var curvedTextElements: [CurvedTextElement] = []
  @State private var isDrawingMode = false
  @State private var currentDrawingPath: [CGPoint] = []
  @State private var drawingMode: DrawingMode = .none
  @State private var showingCurvedTextEditor = false
  @State private var editingCurvedText = ""
  @State private var currentDrawnPath: [CGPoint] = []
  @State private var selectedCurvedTextIndex: Int? = nil
  
  // Template states
  @State private var showingTemplatePicker = false
  @State private var weatherOverlay: WeatherOverlay?

  // Imagen con filtro aplicado
  private var displayImage: UIImage? {
    guard let image = selectedImage else { return nil }
    return currentFilter.apply(to: image)
  }

  var body: some View {
    NavigationView {
      VStack(spacing: 0) {
        // Logo y botón guardar en la parte superior
        HStack {
          Spacer()
          Image("Logo")
            .resizable()
            .scaledToFit()
            .frame(height: 30)
            .padding(.vertical, 8)
          Spacer()
          
          // Botón guardar en la esquina superior derecha
          if selectedImage != nil {
            Button(action: { saveImage() }) {
              Image(systemName: "square.and.arrow.down")
                .font(.title2)
                .foregroundColor(.green)
                .padding(.trailing, 16)
            }
          }
        }
        .background(Color(.systemBackground))

        ZStack {
          if let image = displayImage {
            Image(uiImage: image)
              .resizable()
              .aspectRatio(contentMode: .fit)
              .overlay(
                ZStack {
                  // Textos rectos normales
                  ForEach(textElements) { textElement in
                    TextElementView(
                      textElement: textElement,
                      onDrag: { translation in
                        if let index = textElements.firstIndex(where: { $0.id == textElement.id }) {
                          textElements[index].position.x += translation.width
                          textElements[index].position.y += translation.height
                        }
                      },
                      onScale: { scale in
                        if let index = textElements.firstIndex(where: { $0.id == textElement.id }) {
                          let newScale = textElement.scale * scale
                          textElements[index].scale = min(max(newScale, 0.3), 4.0)
                        }
                      },
                      onTap: {
                        selectedTextElement = textElement
                        editingText = textElement.text
                        // Restaurar el fontStyle basado en el textElement
                        currentFontStyle = FontStyle(
                          name: textElement.customFontName ?? "Default",
                          size: textElement.fontSize,
                          weight: textElement.fontWeight,
                          color: textElement.color,
                          customFontName: textElement.customFontName,
                          shadows: textElement.shadows.map { ShadowStyle(color: $0.color, radius: $0.radius, x: $0.x, y: $0.y) },
                          backgroundOpacity: textElement.backgroundOpacity,
                          cornerRadius: textElement.cornerRadius
                        )
                        showingTextEditor = true
                      }
                    )
                  }

                  // Textos curvos
                  ForEach(curvedTextElements) { curvedText in
                    CurvedTextView(
                      curvedText: curvedText,
                      onDrag: { translation in
                        if let index = curvedTextElements.firstIndex(where: {
                          $0.id == curvedText.id
                        }) {
                          curvedTextElements[index].offset.width += translation.width
                          curvedTextElements[index].offset.height += translation.height
                        }
                      },
                      onScale: { scale in
                        if let index = curvedTextElements.firstIndex(where: {
                          $0.id == curvedText.id
                        }) {
                          let newScale = curvedText.scale * scale
                          curvedTextElements[index].scale = min(max(newScale, 0.3), 4.0)
                        }
                      },
                      onTap: {
                        // Editar texto curvo existente
                        if let index = curvedTextElements.firstIndex(where: {
                          $0.id == curvedText.id
                        }) {
                          editingCurvedText = curvedText.text
                          currentDrawnPath = curvedText.path
                          showingCurvedTextEditor = true
                          // Guardamos el índice para actualizar después
                          selectedCurvedTextIndex = index
                        }
                      }
                    )
                  }

                  // Canvas para dibujar cuando está en modo dibujo
                  if isDrawingMode {
                    DrawingCanvasView(
                      currentPath: $currentDrawingPath,
                      drawingMode: $drawingMode,
                      onFinish: { path in
                        currentDrawnPath = path
                        isDrawingMode = false
                        selectedCurvedTextIndex = nil  // Nuevo texto
                        showingCurvedTextEditor = true
                      }
                    )
                    .allowsHitTesting(true)  // Solo capturar toques cuando está activo
                  }
                  
                  // Weather overlay
                  if let weather = weatherOverlay {
                    VStack {
                      Spacer()
                      HStack {
                        Spacer()
                        WeatherOverlayView(weather: weather, onRemove: {
                          weatherOverlay = nil
                        })
                        .padding(20)
                      }
                    }
                  }
                }
              )
          } else {
            VStack {
              Image(systemName: "photo")
                .font(.system(size: 60))
                .foregroundColor(.gray)
              Text("Selecciona una foto para editar")
                .foregroundColor(.gray)
            }
          }
        }
        .frame(maxHeight: .infinity)
        .background(Color.black)

        VStack(spacing: 16) {
          HStack(spacing: 20) {
            Button(action: { showingImagePicker = true }) {
              VStack {
                Image(systemName: "photo.badge.plus")
                  .font(.title2)
                Text("Foto")
                  .font(.caption)
              }
              .foregroundColor(.blue)
            }

            if selectedImage != nil {
              Button(action: { showingFontMenu = true }) {
                VStack {
                  Image(systemName: "text.badge.plus")
                    .font(.title2)
                  Text("Texto")
                    .font(.caption)
                }
                .foregroundColor(.purple)
              }

              Button(action: {
                isDrawingMode = true
                drawingMode = .none
                currentDrawingPath = []
              }) {
                VStack {
                  Image(systemName: "scribble.variable")
                    .font(.title2)
                  Text("Curvo")
                    .font(.caption)
                }
                .foregroundColor(isDrawingMode ? .orange : .purple)
              }

              Button(action: { showingFilterPicker.toggle() }) {
                VStack {
                  Image(systemName: "slider.horizontal.3")
                    .font(.title2)
                  Text("Filtros")
                    .font(.caption)
                }
                .foregroundColor(showingFilterPicker ? .orange : .blue)
              }
              
              Button(action: { showingTemplatePicker.toggle() }) {
                VStack {
                  Image(systemName: "square.grid.2x2")
                    .font(.title2)
                  Text("Plantillas")
                    .font(.caption)
                }
                .foregroundColor(showingTemplatePicker ? .orange : .blue)
              }
            }
          }
          .padding(.horizontal)

          if showingFilterPicker {
            ScrollView(.horizontal, showsIndicators: false) {
              HStack(spacing: 12) {
                ForEach(PhotoFilter.allCases, id: \.self) { filter in
                  FilterPreviewView(
                    filter: filter,
                    isSelected: currentFilter == filter,
                    onTap: { currentFilter = filter }
                  )
                }
              }
              .padding(.horizontal)
            }
          }
          
          if showingTemplatePicker {
            ScrollView(.horizontal, showsIndicators: false) {
              HStack(spacing: 12) {
                // Plantilla: Clima y ubicación
                Button(action: {
                  Task {
                    await loadWeatherData()
                  }
                }) {
                  VStack(spacing: 4) {
                    Image(systemName: "cloud.sun.fill")
                      .font(.system(size: 32))
                      .foregroundColor(.orange)
                    Text("Clima y\nUbicación")
                      .font(.caption2)
                      .multilineTextAlignment(.center)
                      .foregroundColor(.primary)
                  }
                  .frame(width: 80, height: 80)
                  .background(Color.gray.opacity(0.2))
                  .cornerRadius(12)
                }
              }
              .padding(.horizontal)
            }
          }
        }
        .padding()
        .background(Color(.systemBackground))
      }
      .navigationBarHidden(true)
      .sheet(isPresented: $showingImagePicker) {
        ImagePicker(selectedImage: $selectedImage)
      }
      .sheet(isPresented: $showingFontMenu) {
        FontMenuView { fontStyle in
          currentFontStyle = fontStyle
          print("🎨 Fuente seleccionada en el menú: \(fontStyle.customFontName ?? "sistema")")
          showingFontMenu = false
          editingText = ""
          
          // Usar un pequeño delay para asegurar que currentFontStyle se actualice antes de abrir el editor
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            showingTextEditor = true
          }
        }
      }
      .sheet(item: Binding(
        get: { showingTextEditor ? (currentFontStyle ?? FontStyle(
          name: "Default",
          size: 32,
          weight: .regular,
          color: .white,
          customFontName: nil,
          shadows: [],
          backgroundOpacity: 0.3,
          cornerRadius: 8
        )) : nil },
        set: { _ in }
      )) { fontStyle in
        let _ = print("📋 Abriendo editor con fuente: \(fontStyle.customFontName ?? "sistema")")
        
        TextInputView(
          text: $editingText,
          fontStyle: fontStyle,
          onDone: {
            if !editingText.isEmpty {
              if let selectedElement = selectedTextElement,
                let index = textElements.firstIndex(where: { $0.id == selectedElement.id })
              {
                textElements[index].text = editingText
              } else {
                let newElement = TextElement(
                  text: editingText,
                  position: CGPoint(x: UIScreen.main.bounds.width / 2, y: 200),
                  fontSize: fontStyle.size,
                  fontWeight: fontStyle.weight,
                  color: fontStyle.color,
                  customFontName: fontStyle.customFontName,
                  shadows: fontStyle.shadows.map { TextShadow(color: $0.color, radius: $0.radius, x: $0.x, y: $0.y) },
                  backgroundOpacity: fontStyle.backgroundOpacity,
                  cornerRadius: fontStyle.cornerRadius
                )
                textElements.append(newElement)
              }
            }
            editingText = ""
            selectedTextElement = nil
            currentFontStyle = nil
            showingTextEditor = false
          },
          onCancel: {
            editingText = ""
            selectedTextElement = nil
            currentFontStyle = nil
            showingTextEditor = false
          }
        )
      }
      .sheet(isPresented: $showingCurvedTextEditor) {
        CurvedTextInputView(
          text: $editingCurvedText,
          path: currentDrawnPath,
          onDone: {
            if !editingCurvedText.isEmpty && !currentDrawnPath.isEmpty {
              // Calcular el tamaño de fuente óptimo basado en la longitud de la línea
              let pathLength = PathUtilities.pathLength(currentDrawnPath)
              let optimalFontSize = calculateOptimalFontSize(
                for: editingCurvedText,
                pathLength: pathLength
              )

              if let index = selectedCurvedTextIndex {
                // Editar texto curvo existente
                curvedTextElements[index].text = editingCurvedText
                // Mantener el mismo path, fontSize, etc.
              } else {
                // Crear nuevo texto curvo
                let newCurvedText = CurvedTextElement(
                  text: editingCurvedText,
                  path: currentDrawnPath,
                  fontSize: optimalFontSize,
                  fontWeight: .semibold,
                  color: .white
                )
                curvedTextElements.append(newCurvedText)
              }
            }
            editingCurvedText = ""
            currentDrawnPath = []
            currentDrawingPath = []
            drawingMode = .none
            selectedCurvedTextIndex = nil
            showingCurvedTextEditor = false
          },
          onCancel: {
            editingCurvedText = ""
            currentDrawnPath = []
            currentDrawingPath = []
            drawingMode = .none
            selectedCurvedTextIndex = nil
            showingCurvedTextEditor = false
          }
        )
      }
    }
  }

  func saveImage() {
    guard let image = displayImage else { return }
    let finalImage = createImageWithTexts(from: image)
    UIImageWriteToSavedPhotosAlbum(finalImage, nil, nil, nil)
  }

  func createImageWithTexts(from image: UIImage) -> UIImage {
    let renderer = UIGraphicsImageRenderer(size: image.size)
    return renderer.image { context in
      image.draw(at: .zero)

      // Dibujar textos rectos
      for textElement in textElements {
        let scaledFontSize = textElement.fontSize * textElement.scale
        
        // Usar fuente personalizada si está disponible, sino fuente del sistema
        let font: UIFont
        if let customFontName = textElement.customFontName,
           let customFont = UIFont(name: customFontName, size: scaledFontSize) {
          font = customFont
        } else {
          let uiFontWeight = convertToUIFontWeight(textElement.fontWeight)
          font = UIFont.systemFont(ofSize: scaledFontSize, weight: uiFontWeight)
        }
        
        // Calcular tamaño y posición del texto
        let baseAttributes: [NSAttributedString.Key: Any] = [
          .font: font,
          .foregroundColor: UIColor(textElement.color),
        ]
        let attributedString = NSAttributedString(string: textElement.text, attributes: baseAttributes)
        let textSize = attributedString.size()
        
        // Calcular el área con padding
        let paddingH: CGFloat = 12
        let paddingV: CGFloat = 6
        let backgroundRect = CGRect(
          x: textElement.position.x - (textSize.width + paddingH * 2) / 2,
          y: textElement.position.y - (textSize.height + paddingV * 2) / 2,
          width: textSize.width + paddingH * 2,
          height: textSize.height + paddingV * 2
        )
        
        // Dibujar fondo si tiene opacidad
        if textElement.backgroundOpacity > 0 {
          context.cgContext.saveGState()
          context.cgContext.setFillColor(UIColor.black.withAlphaComponent(textElement.backgroundOpacity).cgColor)
          
          if textElement.cornerRadius > 0 {
            let path = UIBezierPath(roundedRect: backgroundRect, cornerRadius: textElement.cornerRadius)
            path.fill()
          } else {
            context.cgContext.fill(backgroundRect)
          }
          
          context.cgContext.restoreGState()
        }
        
        let textRect = CGRect(
          x: textElement.position.x - textSize.width / 2,
          y: textElement.position.y - textSize.height / 2,
          width: textSize.width,
          height: textSize.height
        )
        
        // Dibujar sombras primero
        context.cgContext.saveGState()
        for shadow in textElement.shadows {
          let shadowAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor(shadow.color),
          ]
          let shadowString = NSAttributedString(string: textElement.text, attributes: shadowAttributes)
          let shadowRect = textRect.offsetBy(dx: shadow.x, dy: shadow.y)
          
          // Simular blur usando múltiples capas con opacidad reducida
          let blurSteps = Int(shadow.radius / 2)
          for i in 0...max(1, blurSteps) {
            context.cgContext.setAlpha(0.3 / CGFloat(max(1, blurSteps)))
            let offset = CGFloat(i) * 0.5
            shadowString.draw(in: shadowRect.offsetBy(dx: offset, dy: 0))
            shadowString.draw(in: shadowRect.offsetBy(dx: -offset, dy: 0))
            shadowString.draw(in: shadowRect.offsetBy(dx: 0, dy: offset))
            shadowString.draw(in: shadowRect.offsetBy(dx: 0, dy: -offset))
          }
        }
        context.cgContext.restoreGState()
        
        // Dibujar texto principal
        attributedString.draw(in: textRect)
      }

      // Dibujar textos curvos
      for curvedText in curvedTextElements {
        drawCurvedText(curvedText, in: context.cgContext)
      }
    }
  }

  func drawCurvedText(_ curvedText: CurvedTextElement, in context: CGContext) {
    let pathLength = PathUtilities.pathLength(curvedText.path)
    guard pathLength > 0 else { return }

    let uiFontWeight = convertToUIFontWeight(curvedText.fontWeight)
    // Aplicar la escala al fontSize
    let scaledFontSize = curvedText.fontSize * curvedText.scale
    let font = UIFont.systemFont(ofSize: scaledFontSize, weight: uiFontWeight)
    let characters = Array(curvedText.text)
    let textCount = CGFloat(characters.count)
    guard textCount > 0 else { return }

    // Distribuir las letras uniformemente a lo largo del path
    let spacing = pathLength / textCount

    context.saveGState()

    // Aplicar el offset (traslación)
    context.translateBy(x: curvedText.offset.width, y: curvedText.offset.height)

    for (index, character) in characters.enumerated() {
      let distance = spacing * CGFloat(index) + (spacing / 2)

      if let positionInfo = PathUtilities.pointAtDistance(curvedText.path, distance: distance) {
        let attributes: [NSAttributedString.Key: Any] = [
          .font: font,
          .foregroundColor: UIColor(curvedText.color),
        ]

        let charString = String(character) as NSString
        let charSize = charString.size(withAttributes: attributes)

        context.saveGState()
        context.translateBy(x: positionInfo.point.x, y: positionInfo.point.y)
        // Usar el ángulo de la tangente directamente
        context.rotate(by: positionInfo.angle)
        context.translateBy(x: -charSize.width / 2, y: -charSize.height / 2)

        charString.draw(at: .zero, withAttributes: attributes)

        context.restoreGState()
      }
    }

    context.restoreGState()
  }

  func convertToUIFontWeight(_ fontWeight: Font.Weight) -> UIFont.Weight {
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

  func calculateOptimalFontSize(for text: String, pathLength: CGFloat) -> CGFloat {
    // Rango de tamaños de fuente a probar
    let minFontSize: CGFloat = 12
    let maxFontSize: CGFloat = 60

    // Usar búsqueda binaria para encontrar el tamaño óptimo
    var low = minFontSize
    var high = maxFontSize
    var optimalSize = minFontSize

    while low <= high {
      let mid = (low + high) / 2
      let font = UIFont.systemFont(ofSize: mid, weight: .semibold)

      // Calcular el ancho total del texto con este tamaño
      var totalWidth: CGFloat = 0
      for char in text {
        let charString = String(char) as NSString
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        totalWidth += charString.size(withAttributes: attributes).width
      }

      // Dejar un 10% de margen
      let requiredLength = totalWidth * 1.1

      if requiredLength <= pathLength {
        optimalSize = mid
        low = mid + 1
      } else {
        high = mid - 1
      }
    }

    return optimalSize
  }
  
  func loadWeatherData() async {
    // Por ahora, vamos a usar datos de ejemplo
    // En la próxima iteración integraremos una API real de clima
    let exampleWeather = WeatherOverlay(
      temperature: "22°C",
      location: "Santiago, Chile",
      weatherIcon: "sun.max.fill"
    )
    
    await MainActor.run {
      weatherOverlay = exampleWeather
      showingTemplatePicker = false
    }
  }
}


#Preview {
  PhotoEditorView()
}
