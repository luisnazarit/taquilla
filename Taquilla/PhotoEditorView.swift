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
  
  // Para calcular el factor de escala entre pantalla e imagen
  @State private var displayedImageSize: CGSize = .zero
  
  // Para mostrar mensaje de éxito
  @State private var showingSaveSuccess = false

  // Imagen con filtro aplicado
  private var displayImage: UIImage? {
    guard let image = selectedImage else { return nil }
    return currentFilter.apply(to: image)
  }

  var body: some View {
    NavigationView {
      VStack(spacing: 0) {
        // Logo y botones en la parte superior
        HStack {
          // Botón para descartar imagen (izquierda)
          if selectedImage != nil {
            Button(action: {
              // Descartar imagen y limpiar todo
              selectedImage = nil
              textElements = []
              curvedTextElements = []
              weatherOverlay = nil
              currentFilter = .none
            }) {
              Image(systemName: "xmark.circle.fill")
                .font(.title2)
                .foregroundColor(.white)
                .padding(.leading, 16)
            }
          } else {
            Spacer()
              .frame(width: 56)
          }
          
          Spacer()
          
          Image("Logo")
            .resizable()
            .scaledToFit()
            .frame(height: 30)
            .padding(.vertical, 8)
          
          Spacer()
          
          // Botones de compartir y guardar en la esquina superior derecha
          if selectedImage != nil {
            HStack(spacing: 12) {
              // Botón de compartir
              Button(action: { shareToInstagramStory() }) {
                Image(systemName: "square.and.arrow.up")
                  .font(.title2)
                  .foregroundColor(.white)
              }
              
              // Botón guardar
              Button(action: { saveImage() }) {
                Image(systemName: "square.and.arrow.down")
                  .font(.title2)
                  .foregroundColor(.white)
              }
            }
            .padding(.trailing, 16)
          } else {
            Spacer()
              .frame(width: 56)
          }
        }
        .background(Color(.systemBackground))

        ZStack {
          if let image = displayImage {
            GeometryReader { geometry in
              Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .background(
                  GeometryReader { imageGeometry in
                    Color.clear.onAppear {
                      displayedImageSize = imageGeometry.size
                    }
                    .onChange(of: imageGeometry.size) { oldValue, newValue in
                      displayedImageSize = newValue
                    }
                  }
                )
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
            }
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
              .foregroundColor(.white)
            }

            if selectedImage != nil {
              Button(action: { showingFontMenu = true }) {
                VStack {
                  Image(systemName: "text.badge.plus")
                    .font(.title2)
                  Text("Texto")
                    .font(.caption)
                }
                .foregroundColor(.white)
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
                .foregroundColor(.white)
              }

              Button(action: { showingFilterPicker.toggle() }) {
                VStack {
                  Image(systemName: "slider.horizontal.3")
                    .font(.title2)
                  Text("Filtros")
                    .font(.caption)
                }
                .foregroundColor(.white)
              }
              
              Button(action: { showingTemplatePicker.toggle() }) {
                VStack {
                  Image(systemName: "square.grid.2x2")
                    .font(.title2)
                  Text("Plantillas")
                    .font(.caption)
                }
                .foregroundColor(.white)
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
      .overlay(
        Group {
          if showingSaveSuccess {
            VStack {
              Spacer()
              HStack {
                Image(systemName: "checkmark.circle.fill")
                  .foregroundColor(.green)
                  .font(.title2)
                Text("Imagen guardada exitosamente")
                  .foregroundColor(.white)
                  .fontWeight(.semibold)
              }
              .padding()
              .background(Color.black.opacity(0.8))
              .cornerRadius(12)
              .padding(.bottom, 50)
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.spring(), value: showingSaveSuccess)
          }
        }
      )
    }
  }

  func saveImage() {
    guard let image = displayImage else { return }
    let finalImage = createImageWithTexts(from: image)
    UIImageWriteToSavedPhotosAlbum(finalImage, nil, nil, nil)
    
    // Mostrar mensaje de éxito
    withAnimation {
      showingSaveSuccess = true
    }
    
    // Ocultar mensaje después de 2 segundos
    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
      withAnimation {
        showingSaveSuccess = false
      }
    }
  }
  
  func shareToInstagramStory() {
    guard let image = displayImage else { return }
    
    // Crear la imagen final en un contexto válido
    let finalImage = createImageWithTexts(from: image)
    
    // Optimizar la imagen para compartir (JPEG con compresión)
    let optimizedImage = optimizeImageForSharing(finalImage)
    
    // Crear el activity view controller para compartir
    let activityViewController = UIActivityViewController(
      activityItems: [optimizedImage],
      applicationActivities: nil
    )
    
    // Excluir algunas actividades que no tienen sentido para una imagen
    activityViewController.excludedActivityTypes = [
      .addToReadingList,
      .assignToContact,
      .openInIBooks,
      .markupAsPDF
    ]
    
    // Configurar para iPad (necesario para evitar crashes en iPad)
    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
       let rootViewController = windowScene.windows.first?.rootViewController {
      
      // Para iPad, necesitamos configurar el popover
      if let popoverController = activityViewController.popoverPresentationController {
        popoverController.sourceView = rootViewController.view
        popoverController.sourceRect = CGRect(
          x: rootViewController.view.bounds.midX,
          y: rootViewController.view.bounds.midY,
          width: 0,
          height: 0
        )
        popoverController.permittedArrowDirections = []
      }
      
      rootViewController.present(activityViewController, animated: true)
    }
  }

  func createImageWithTexts(from image: UIImage) -> UIImage {
    // Limitar el tamaño máximo de la imagen para evitar problemas de memoria
    let maxSize: CGFloat = 2048
    var targetSize = image.size
    
    if image.size.width > maxSize || image.size.height > maxSize {
      let aspectRatio = image.size.width / image.size.height
      if image.size.width > image.size.height {
        targetSize = CGSize(width: maxSize, height: maxSize / aspectRatio)
      } else {
        targetSize = CGSize(width: maxSize * aspectRatio, height: maxSize)
      }
    }
    
    let renderer = UIGraphicsImageRenderer(size: targetSize)
    return renderer.image { context in
      // Dibujar la imagen base redimensionada
      image.draw(in: CGRect(origin: .zero, size: targetSize))
      
      // Calcular el factor de escala entre la imagen mostrada y la imagen final
      // Usar un valor por defecto si displayedImageSize es inválido
      let validDisplaySize = displayedImageSize.width > 0 && displayedImageSize.height > 0 
        ? displayedImageSize 
        : CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height * 0.6)
      
      let scaleX = targetSize.width / validDisplaySize.width
      let scaleY = targetSize.height / validDisplaySize.height
      let scale = min(scaleX, scaleY) // Usar el menor para mantener todo visible

      // Dibujar textos rectos
      for textElement in textElements {
        // Aplicar escala al tamaño de fuente
        let scaledFontSize = textElement.fontSize * textElement.scale * scale
        
        // Usar fuente personalizada si está disponible, sino fuente del sistema
        let font: UIFont
        if let customFontName = textElement.customFontName,
           let customFont = UIFont(name: customFontName, size: scaledFontSize) {
          font = customFont
        } else {
          let uiFontWeight = convertToUIFontWeight(textElement.fontWeight)
          font = UIFont.systemFont(ofSize: scaledFontSize, weight: uiFontWeight)
        }
        
        // Calcular tamaño y posición del texto con escala
        let baseAttributes: [NSAttributedString.Key: Any] = [
          .font: font,
          .foregroundColor: UIColor(textElement.color),
        ]
        let attributedString = NSAttributedString(string: textElement.text, attributes: baseAttributes)
        let textSize = attributedString.size()
        
        // Aplicar escala a las posiciones y padding
        let scaledPosition = CGPoint(
          x: textElement.position.x * scale,
          y: textElement.position.y * scale
        )
        
        // Calcular el área con padding escalado
        let paddingH: CGFloat = 12 * scale
        let paddingV: CGFloat = 6 * scale
        let backgroundRect = CGRect(
          x: scaledPosition.x - (textSize.width + paddingH * 2) / 2,
          y: scaledPosition.y - (textSize.height + paddingV * 2) / 2,
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
          x: scaledPosition.x - textSize.width / 2,
          y: scaledPosition.y - textSize.height / 2,
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
          // Escalar el offset de la sombra
          let shadowRect = textRect.offsetBy(dx: shadow.x * scale, dy: shadow.y * scale)
          
          // Simular blur usando capas limitadas (optimizado para memoria)
          let blurSteps = min(3, Int((shadow.radius * scale) / 2)) // Máximo 3 pasos
          if blurSteps > 0 {
            for i in 0...blurSteps {
              context.cgContext.setAlpha(0.3 / CGFloat(max(1, blurSteps)))
              let offset = CGFloat(i) * 0.5 * scale
              shadowString.draw(in: shadowRect.offsetBy(dx: offset, dy: 0))
              shadowString.draw(in: shadowRect.offsetBy(dx: -offset, dy: 0))
              shadowString.draw(in: shadowRect.offsetBy(dx: 0, dy: offset))
              shadowString.draw(in: shadowRect.offsetBy(dx: 0, dy: -offset))
            }
          } else {
            // Si no hay blur, solo dibujar una vez
            context.cgContext.setAlpha(1.0)
            shadowString.draw(in: shadowRect)
          }
        }
        context.cgContext.restoreGState()
        
        // Dibujar texto principal
        attributedString.draw(in: textRect)
      }

      // Dibujar textos curvos
      for curvedText in curvedTextElements {
        drawCurvedText(curvedText, in: context.cgContext, scale: scale)
      }
      
      // Dibujar weather overlay
      if let weather = weatherOverlay {
        drawWeatherOverlay(weather, in: context.cgContext, imageSize: targetSize, scale: scale)
      }
    }
  }
  
  func optimizeImageForSharing(_ image: UIImage) -> UIImage {
    // Tamaño óptimo para redes sociales (Instagram, WhatsApp, etc.)
    let maxSize: CGFloat = 1920
    var targetSize = image.size
    
    // Redimensionar si es necesario
    if image.size.width > maxSize || image.size.height > maxSize {
      let aspectRatio = image.size.width / image.size.height
      if image.size.width > image.size.height {
        targetSize = CGSize(width: maxSize, height: maxSize / aspectRatio)
      } else {
        targetSize = CGSize(width: maxSize * aspectRatio, height: maxSize)
      }
    }
    
    // Redimensionar la imagen si es necesario
    let renderer = UIGraphicsImageRenderer(size: targetSize, format: UIGraphicsImageRendererFormat())
    let resizedImage = renderer.image { context in
      image.draw(in: CGRect(origin: .zero, size: targetSize))
    }
    
    // Convertir a JPEG con compresión de calidad 0.85 (balance entre calidad y tamaño)
    guard let jpegData = resizedImage.jpegData(compressionQuality: 0.85),
          let optimizedImage = UIImage(data: jpegData) else {
      return image // Si falla, devolver la imagen original
    }
    
    return optimizedImage
  }

  func drawCurvedText(_ curvedText: CurvedTextElement, in context: CGContext, scale: CGFloat) {
    // Escalar el path
    let scaledPath = curvedText.path.map { CGPoint(x: $0.x * scale, y: $0.y * scale) }
    let pathLength = PathUtilities.pathLength(scaledPath)
    guard pathLength > 0 else { return }

    let uiFontWeight = convertToUIFontWeight(curvedText.fontWeight)
    // Aplicar la escala al fontSize y al scale del elemento
    let scaledFontSize = curvedText.fontSize * curvedText.scale * scale
    let font = UIFont.systemFont(ofSize: scaledFontSize, weight: uiFontWeight)
    let characters = Array(curvedText.text)
    let textCount = CGFloat(characters.count)
    guard textCount > 0 else { return }

    // Distribuir las letras uniformemente a lo largo del path
    let spacing = pathLength / textCount

    context.saveGState()

    // Aplicar el offset escalado
    context.translateBy(x: curvedText.offset.width * scale, y: curvedText.offset.height * scale)

    for (index, character) in characters.enumerated() {
      let distance = spacing * CGFloat(index) + (spacing / 2)

      if let positionInfo = PathUtilities.pointAtDistance(scaledPath, distance: distance) {
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
  
  func drawWeatherOverlay(_ weather: WeatherOverlay, in context: CGContext, imageSize: CGSize, scale: CGFloat) {
    context.saveGState()
    
    // Configuración de posicionamiento: esquina inferior derecha con padding escalado
    let padding: CGFloat = 20 * scale
    
    // Cargar la imagen del clima (SVG convertido a UIImage)
    guard let weatherImage = UIImage(named: weather.weatherType.imageName) else { return }
    let iconSize: CGFloat = 48 * scale
    
    // Fuentes con tamaños escalados
    guard let tempFont = UIFont(name: "Ari-W9500Display", size: 40 * scale) else { return }
    guard let locationFont = UIFont(name: "Ari-W9500Display", size: 12 * scale) else { return }
    
    // Atributos de texto
    let tempAttributes: [NSAttributedString.Key: Any] = [
      .font: tempFont,
      .foregroundColor: UIColor.white
    ]
    
    let locationAttributes: [NSAttributedString.Key: Any] = [
      .font: locationFont,
      .foregroundColor: UIColor.white
    ]
    
    // Calcular tamaños
    let tempString = weather.temperature as NSString
    let tempSize = tempString.size(withAttributes: tempAttributes)
    
    let locationString = weather.location.uppercased() as NSString
    let locationSize = locationString.size(withAttributes: locationAttributes)
    
    // Calcular el ancho total del HStack (icono + spacing + temperatura) - con spacing escalado
    let hStackSpacing: CGFloat = 12 * scale
    let hStackWidth = iconSize + hStackSpacing + tempSize.width
    
    // Calcular el ancho máximo (para centrar la ubicación)
    let maxWidth = max(hStackWidth, locationSize.width)
    
    // Calcular la altura total - con spacing escalado
    let vStackSpacing: CGFloat = 8 * scale
    let totalHeight = iconSize + vStackSpacing + locationSize.height
    
    // Posición inicial (esquina inferior derecha)
    let baseX = imageSize.width - maxWidth - padding
    let baseY = imageSize.height - totalHeight - padding
    
    // Dibujar el icono del clima
    let iconRect = CGRect(
      x: baseX + (maxWidth - hStackWidth) / 2,  // Centrar el HStack
      y: baseY,
      width: iconSize,
      height: iconSize
    )
    weatherImage.draw(in: iconRect)
    
    // Dibujar la temperatura (al lado derecho del icono)
    let tempRect = CGRect(
      x: iconRect.maxX + hStackSpacing,
      y: baseY + (iconSize - tempSize.height) / 2,  // Centrar verticalmente con el icono
      width: tempSize.width,
      height: tempSize.height
    )
    
    // Dibujar sombra para la temperatura (escalada)
    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: 4 * scale), blur: 8 * scale, color: UIColor.black.withAlphaComponent(0.5).cgColor)
    tempString.draw(in: tempRect, withAttributes: tempAttributes)
    context.restoreGState()
    
    // Dibujar la ubicación (centrada debajo)
    let locationRect = CGRect(
      x: baseX + (maxWidth - locationSize.width) / 2,  // Centrar la ubicación
      y: baseY + iconSize + vStackSpacing,
      width: locationSize.width,
      height: locationSize.height
    )
    
    // Dibujar sombra para la ubicación (escalada)
    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: 4 * scale), blur: 8 * scale, color: UIColor.black.withAlphaComponent(0.5).cgColor)
    locationString.draw(in: locationRect, withAttributes: locationAttributes)
    context.restoreGState()
    
    context.restoreGState()
  }
  
  func loadWeatherData() async {
    // Por ahora, vamos a usar datos de ejemplo
    // En la próxima iteración integraremos una API real de clima
    
    // Ejemplos para probar:
    // temperature: "28°C"  → 😎 (soleado, >= 25°C)
    // temperature: "8°C"   → 🥶 (frío, <= 10°C)
    // temperature: "18°C"  → 🌤️ (normal, entre 11-24°C)
    
    let exampleWeather = WeatherOverlay(
      temperature: "22°C",
      location: "Santiago, Chile"
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
