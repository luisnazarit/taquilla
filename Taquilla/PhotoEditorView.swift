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

  // Imagen con filtro aplicado
  private var displayImage: UIImage? {
    guard let image = selectedImage else { return nil }
    return currentFilter.apply(to: image)
  }

  var body: some View {
    NavigationView {
      VStack(spacing: 0) {
        // Logo en la parte superior
        HStack {
          Spacer()
          Image("Logo")
            .resizable()
            .scaledToFit()
            .frame(height: 30)
            .padding(.vertical, 8)
          Spacer()
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
            }

            if selectedImage != nil {
              Button(action: { saveImage() }) {
                VStack {
                  Image(systemName: "square.and.arrow.down")
                    .font(.title2)
                  Text("Guardar")
                    .font(.caption)
                }
                .foregroundColor(.green)
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
}

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
          .lineLimit(1)
          .fixedSize()
          .blur(radius: shadow.radius)
          .offset(x: shadow.x, y: shadow.y)
      }
      
      // Texto principal
      Text(textElement.text)
        .font(textElement.customFontName != nil 
              ? .custom(textElement.customFontName!, size: textElement.fontSize)
              : .system(size: textElement.fontSize, weight: textElement.fontWeight))
        .foregroundColor(textElement.color)
        .lineLimit(1)
        .fixedSize()
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
              let sensitivity: CGFloat = 0.3
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

struct ShadowStyle {
  let color: Color
  let radius: CGFloat
  let x: CGFloat
  let y: CGFloat
}

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

        // Campo de entrada - usando directamente la fuente personalizada
        TextField("", text: $text)
          .font(fontStyle.customFontName != nil 
                ? .custom(fontStyle.customFontName!, size: fontStyle.size)
                : .system(size: fontStyle.size, weight: fontStyle.weight))
          .foregroundColor(fontStyle.color)
          .multilineTextAlignment(.center)
          .padding()
          .background(Color.white.opacity(0.05))
          .cornerRadius(10)
          .padding(.horizontal, 20)
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

// MARK: - Curved Text Views

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
            .font(
              .system(size: curvedText.fontSize * curvedText.scale, weight: curvedText.fontWeight)
            )
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
    let font = UIFont.systemFont(
      ofSize: curvedText.fontSize, weight: convertToUIFontWeight(curvedText.fontWeight))
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

#Preview {
  PhotoEditorView()
}
