import CoreLocation
import MapKit
import PhotosUI
import SwiftUI

struct PhotoEditorView: View {
  @StateObject private var locationManager = LocationManager()
  @EnvironmentObject var photoManager: PhotoManager

    @State private var selectedImage: UIImage?

  // Inicializador para permitir imagen inicial
  init(initialImage: UIImage? = nil) {
    if let image = initialImage {
      _selectedImage = State(initialValue: image)
    }
  }
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
  @State private var currentCurvedTextFontStyle: FontStyle? = nil

  // Template states
  @State private var showingTemplatePicker = false
  @State private var weatherOverlay: WeatherOverlay?
  @State private var locationOverlay: LocationOverlay?
  @State private var isLoadingTemplate = false
  
  // Sticker states
  @State private var showingStickerPicker = false
  @State private var stickerElements: [StickerElement] = []
  @State private var availableStickers: [StickerInfo] = []
  @State private var nextZIndex = 0
  @State private var isLoadingStickers = false

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
            mainContentView
        }
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
        .sheet(isPresented: $showingTextEditor) {
            textEditorSheet
        }
        .sheet(isPresented: $showingCurvedTextEditor) {
            curvedTextEditorSheet
        }
        .sheet(isPresented: $showingStickerPicker) {
            StickerPickerSheetView(
                availableStickers: availableStickers,
                isLoadingStickers: $isLoadingStickers,
                onStickerSelected: { stickerInfo in
                    let newSticker = StickerElement(
                        imageName: stickerInfo.name,
                        imageURL: stickerInfo.url,
                        position: CGPoint(x: displayedImageSize.width * 0.5, y: displayedImageSize.height * 0.5),
                        scale: 1.0,
                        rotation: 0.0,
                        zIndex: nextZIndex
                    )
                    stickerElements.append(newSticker)
                    nextZIndex += 1
                    showingStickerPicker = false
                },
                onLoadStickers: {
                    Task {
                        isLoadingStickers = true
                        availableStickers = await StickerManager.shared.loadAvailableStickers()
                        isLoadingStickers = false
                    }
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
                                .font(.title)
                            Text("¡Foto guardada!")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(10)
                        Spacer()
                    }
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showingSaveSuccess = false
                        }
                    }
                }
            }
        )
    }
    
    // MARK: - Sheet Views
    @ViewBuilder
    private var textEditorSheet: some View {
        if let fontStyle = currentFontStyle {
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
                                shadows: fontStyle.shadows.map {
                                    TextShadow(color: $0.color, radius: $0.radius, x: $0.x, y: $0.y)
                                },
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
    }
    
    @ViewBuilder
    private var curvedTextEditorSheet: some View {
        CurvedTextInputView(
            text: $editingCurvedText,
            path: currentDrawnPath,
            onDone: { selectedFontStyle in
                if !editingCurvedText.isEmpty && !currentDrawnPath.isEmpty {
                    // Calcular el tamaño de fuente óptimo basado en la longitud de la línea
                    let pathLength = PathUtilities.pathLength(currentDrawnPath)
                    let optimalFontSize = calculateOptimalFontSize(
                        for: editingCurvedText,
                        pathLength: pathLength
                    )

                    if let index = selectedCurvedTextIndex {
                        // Editar texto curvo existente - actualizar todas las propiedades de fuente
                        curvedTextElements[index].text = editingCurvedText
                        curvedTextElements[index].fontSize = optimalFontSize
                        curvedTextElements[index].fontWeight = selectedFontStyle?.weight ?? curvedTextElements[index].fontWeight
                        curvedTextElements[index].color = selectedFontStyle?.color ?? curvedTextElements[index].color
                        curvedTextElements[index].customFontName = selectedFontStyle?.customFontName
                        print("🎨 Editando texto curvo con fuente: \(selectedFontStyle?.customFontName ?? "nil")")
                    } else {
                        // Crear nuevo texto curvo con fuente personalizada si está disponible
                        print("🎨 Creando texto curvo con fuente: \(selectedFontStyle?.customFontName ?? "nil")")
                        let newCurvedText = CurvedTextElement(
                            text: editingCurvedText,
                            path: currentDrawnPath,
                            fontSize: optimalFontSize,
                            fontWeight: selectedFontStyle?.weight ?? .semibold,
                            color: selectedFontStyle?.color ?? .white,
                            customFontName: selectedFontStyle?.customFontName
                        )
                        print("✅ Texto curvo creado con customFontName: \(newCurvedText.customFontName ?? "nil")")
                        curvedTextElements.append(newCurvedText)
                    }
                }
                editingCurvedText = ""
                currentDrawnPath = []
                currentDrawingPath = []
                drawingMode = .none
                selectedCurvedTextIndex = nil
                currentCurvedTextFontStyle = nil
                showingCurvedTextEditor = false
            },
            onCancel: {
                editingCurvedText = ""
                currentDrawnPath = []
                currentDrawingPath = []
                drawingMode = .none
                selectedCurvedTextIndex = nil
                currentCurvedTextFontStyle = nil
                showingCurvedTextEditor = false
            },
            initialFontStyle: currentCurvedTextFontStyle
        )
    }
    
    private var mainContentView: some View {
        ZStack {
            // Fondo de la aplicación
            Image("Background")
              .resizable()
              .aspectRatio(contentMode: .fill)
              .ignoresSafeArea()

            VStack(spacing: 0) {
              GeometryReader { geometry in
                if let image = displayImage {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                          if let index = textElements.firstIndex(where: { $0.id == textElement.id })
                          {
                            textElements[index].position.x += translation.width
                            textElements[index].position.y += translation.height
                          }
                        },
                        onScale: { scale in
                          if let index = textElements.firstIndex(where: { $0.id == textElement.id })
                          {
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
                            shadows: textElement.shadows.map {
                              ShadowStyle(color: $0.color, radius: $0.radius, x: $0.x, y: $0.y)
                            },
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
                            // Crear FontStyle basado en el texto curvo actual
                            currentCurvedTextFontStyle = FontStyle(
                              name: curvedText.customFontName ?? "Default",
                              size: curvedText.fontSize,
                              weight: curvedText.fontWeight,
                              color: curvedText.color,
                              customFontName: curvedText.customFontName,
                              shadows: [],
                              backgroundOpacity: 0,
                              cornerRadius: 0
                            )
                            showingCurvedTextEditor = true
                            // Guardamos el índice para actualizar después
                            selectedCurvedTextIndex = index
                          }
                        }
                      )
                    }

                    // Stickers
                    ForEach(stickerElements.sorted(by: { $0.zIndex < $1.zIndex })) { sticker in
                      StickerElementView(
                        stickerElement: sticker,
                        onDrag: { translation in
                          if let index = stickerElements.firstIndex(where: { $0.id == sticker.id }) {
                            stickerElements[index].position.x += translation.width
                            stickerElements[index].position.y += translation.height
                          }
                        },
                        onScale: { scale in
                          if let index = stickerElements.firstIndex(where: { $0.id == sticker.id }) {
                            let newScale = sticker.scale * scale
                            stickerElements[index].scale = min(max(newScale, 0.8), 2.5)
                          }
                        },
                        onRotation: { rotation in
                          if let index = stickerElements.firstIndex(where: { $0.id == sticker.id }) {
                            stickerElements[index].rotation += rotation
                          }
                        },
                        onDelete: {
                          print("🗑️ onDelete called - removing sticker")
                          stickerElements.removeAll { $0.id == sticker.id }
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
                          WeatherOverlayView(
                            weather: weather,
                            onRemove: {
                              weatherOverlay = nil
                            }
                          )
                          .padding(20)
                        }
                      }
                    }

                    // Location overlay
                    if let location = locationOverlay {
                        VStack {
                        Spacer()
                        HStack {
                          Spacer()
                          LocationOverlayView(
                            location: location,
                            onRemove: {
                              locationOverlay = nil
                            }
                          )
                          .padding(20)
                        }
                      }
                    }
                  }
                )
                .clipped()
            } else {
              emptyStateView
                    }
                }
                .frame(maxHeight: .infinity)
                
          // Barra de herramientas (solo cuando hay imagen)
          if selectedImage != nil {
                VStack(spacing: 16) {
                    HStack(spacing: 20) {
                Button(action: { 
                  // Cerrar otros paneles antes de abrir texto
                  showingFilterPicker = false
                  showingTemplatePicker = false
                  showingFontMenu = true 
                }) {
                            VStack {
                    Image(systemName: "text.badge.plus")
                                    .font(.title2)
                    Text("Texto")
                                    .font(.caption)
                            }
                  .foregroundColor(showingFontMenu ? .white : .white.opacity(0.6))
                }

                Button(action: {
                  // Cerrar otros paneles antes de abrir curvo
                  showingFilterPicker = false
                  showingTemplatePicker = false
                  showingFontMenu = false
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
                  .foregroundColor(isDrawingMode ? .white : .white.opacity(0.6))
                }

                Button(action: { 
                  // Cerrar otros paneles antes de abrir filtros
                  showingTemplatePicker = false
                  showingFontMenu = false
                  showingFilterPicker.toggle() 
                }) {
                            VStack {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.title2)
                                Text("Filtros")
                                    .font(.caption)
                            }
                  .foregroundColor(showingFilterPicker ? .white : .white.opacity(0.6))
                        }
                        
                Button(action: { 
                  // Cerrar otros paneles antes de abrir plantillas
                  showingFilterPicker = false
                  showingFontMenu = false
                  showingTemplatePicker.toggle() 
                }) {
                            VStack {
                    Image(systemName: "square.grid.2x2")
                                    .font(.title2)
                    Text("Plantillas")
                                    .font(.caption)
                            }
                  .foregroundColor(showingTemplatePicker ? .white : .white.opacity(0.6))
                        }
                        
                Button(action: { 
                  // Cerrar otros paneles antes de abrir stickers
                  showingFilterPicker = false
                  showingTemplatePicker = false
                  showingFontMenu = false
                  showingStickerPicker = true
                }) {
                            VStack {
                    Image(systemName: "face.smiling")
                                    .font(.title2)
                    Text("Stickers")
                                    .font(.caption)
                            }
                  .foregroundColor(showingStickerPicker ? .white : .white.opacity(0.6))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(12)
                    
                    if showingFilterPicker {
                        ScrollView(.horizontal, showsIndicators: false) {
                  HStack(spacing: 6) {
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
                        isLoadingTemplate = true
                        await loadWeatherData()
                        isLoadingTemplate = false
                      }
                    }) {
                      VStack(spacing: 4) {
                        if isLoadingTemplate {
                          ProgressView()
                            .scaleEffect(0.8)
                            .foregroundColor(.white)
                        } else {
                          Image(systemName: "cloud.sun.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                        }
                        Text("Clima y\nUbicación")
                          .font(.caption2)
                          .multilineTextAlignment(.center)
                          .foregroundColor(.primary)
                      }
                      .frame(width: 80, height: 80)
                      .background(Color.gray.opacity(0.2))
                      .cornerRadius(12)
                    }
                    .disabled(isLoadingTemplate)

                    // Plantilla: Ubicación
                    Button(action: {
                      isLoadingTemplate = true
                      loadLocationData()
                    }) {
                      VStack(spacing: 4) {
                        if isLoadingTemplate {
                          ProgressView()
                            .scaleEffect(0.8)
                            .foregroundColor(.white)
                        } else {
                          Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                        }
                        Text("Ubicación")
                          .font(.caption2)
                          .multilineTextAlignment(.center)
                          .foregroundColor(.primary)
                      }
                      .frame(width: 80, height: 80)
                      .background(Color.gray.opacity(0.2))
                      .cornerRadius(12)
                    }
                    .disabled(isLoadingTemplate)
                  }
                  .padding(.horizontal)
                }
                .padding(.bottom, 20)  // Padding reducido para mejor layout
              }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
          }
        }
      }
      .toolbar {
        if selectedImage != nil {
          ToolbarItem(placement: .navigationBarTrailing) {
            HStack(spacing: 20) {
              // Botón de compartir
              Button(action: { shareToInstagramStory() }) {
                Image(systemName: "square.and.arrow.up")
                  .font(.body)
                  .foregroundColor(.white)
              }

              // Botón guardar
              Button(action: { saveImage() }) {
                Image(systemName: "square.and.arrow.down")
                  .font(.body)
                  .foregroundColor(.white)
              }
            }
          }
        }
      }
    }
    
    // Vista de estado vacío (sin imagen)
    private var emptyStateView: some View {
        Button(action: { showingImagePicker = true }) {
            VStack(spacing: 10) {
                Spacer()

                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 180)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)

                Image(systemName: "plus.circle")
                    .font(.system(size: 50))
                    .foregroundColor(Color(red: 1.0, green: 0.0, blue: 1.0))

                Text("Seleccionar una foto")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.bottom, 5)

                Text("Elige tu foto más taquillera")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))

                Spacer()

                Text(
                    "Taquilla es una app que periódicamente actualiza sus diseños,\ntotalmente gratuita, diseñada en Chile con <3"
                )
                .font(.caption)
                .foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

  func saveImage() {
    guard let image = displayImage else { return }
    let finalImage = createImageWithTexts(from: image)

    // Usar PhotoManager para guardar y registrar la foto
    photoManager.savePhoto(finalImage) { success in
      if success {
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
      } else {
        print("❌ Error guardando la foto")
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
      .markupAsPDF,
    ]

    // Configurar para iPad (necesario para evitar crashes en iPad)
    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
      let rootViewController = windowScene.windows.first?.rootViewController
    {

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
      let validDisplaySize =
        displayedImageSize.width > 0 && displayedImageSize.height > 0
        ? displayedImageSize
        : CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height * 0.6)

      let scaleX = targetSize.width / validDisplaySize.width
      let scaleY = targetSize.height / validDisplaySize.height
      let scale = min(scaleX, scaleY)  // Usar el menor para mantener todo visible

      // Dibujar textos rectos
            for textElement in textElements {
        // Aplicar escala al tamaño de fuente
        let scaledFontSize = textElement.fontSize * textElement.scale * scale

        // Usar fuente personalizada si está disponible, sino fuente del sistema
        let font: UIFont
        if let customFontName = textElement.customFontName,
          let customFont = UIFont(name: customFontName, size: scaledFontSize)
        {
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
        let attributedString = NSAttributedString(
          string: textElement.text, attributes: baseAttributes)
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
          context.cgContext.setFillColor(
            UIColor.black.withAlphaComponent(textElement.backgroundOpacity).cgColor)

          if textElement.cornerRadius > 0 {
            let path = UIBezierPath(
              roundedRect: backgroundRect, cornerRadius: textElement.cornerRadius)
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
          let shadowString = NSAttributedString(
            string: textElement.text, attributes: shadowAttributes)
          // Escalar el offset de la sombra
          let shadowRect = textRect.offsetBy(dx: shadow.x * scale, dy: shadow.y * scale)

          // Simular blur usando capas limitadas (optimizado para memoria)
          let blurSteps = min(3, Int((shadow.radius * scale) / 2))  // Máximo 3 pasos
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

      // Dibujar location overlay
      if let location = locationOverlay {
        drawLocationOverlay(location, in: context.cgContext, imageSize: targetSize, scale: scale)
      }

      // Dibujar stickers
      for sticker in stickerElements {
        drawSticker(sticker, in: context.cgContext, scale: scale)
      }
    }
  }

  func drawSticker(_ sticker: StickerElement, in context: CGContext, scale: CGFloat) {
    // Calcular la posición escalada del sticker
    let scaledPosition = CGPoint(
      x: sticker.position.x * scale,
      y: sticker.position.y * scale
    )
    
    // Calcular el tamaño escalado del sticker
    let stickerSize = CGSize(width: 80 * sticker.scale * scale, height: 80 * sticker.scale * scale)
    
    // Crear el rectángulo donde se dibujará el sticker
    let stickerRect = CGRect(
      x: scaledPosition.x - stickerSize.width / 2,
      y: scaledPosition.y - stickerSize.height / 2,
      width: stickerSize.width,
      height: stickerSize.height
    )
    
    // Guardar el estado del contexto
    context.saveGState()
    
    // Aplicar rotación
    context.translateBy(x: scaledPosition.x, y: scaledPosition.y)
    context.rotate(by: CGFloat(sticker.rotation) * .pi / 180)
    context.translateBy(x: -scaledPosition.x, y: -scaledPosition.y)
    
    // Cargar la imagen del sticker
    var stickerImage: UIImage?
    
    if let imageURL = sticker.imageURL, !imageURL.isEmpty {
      // Cargar desde URL (esto es síncrono, puede causar problemas en producción)
      if let url = URL(string: imageURL),
         let data = try? Data(contentsOf: url),
         let image = UIImage(data: data) {
        stickerImage = image
      }
    } else {
      // Usar imagen local
      stickerImage = UIImage(named: sticker.imageName)
    }
    
    // Dibujar el sticker si se pudo cargar
    if let image = stickerImage {
      image.draw(in: stickerRect)
    }
    
    // Restaurar el estado del contexto
    context.restoreGState()
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
    let renderer = UIGraphicsImageRenderer(
      size: targetSize, format: UIGraphicsImageRendererFormat())
    let resizedImage = renderer.image { context in
      image.draw(in: CGRect(origin: .zero, size: targetSize))
    }

    // Convertir a JPEG con compresión de calidad 0.85 (balance entre calidad y tamaño)
    guard let jpegData = resizedImage.jpegData(compressionQuality: 0.85),
      let optimizedImage = UIImage(data: jpegData)
    else {
      return image  // Si falla, devolver la imagen original
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
    
    // Usar fuente personalizada si está disponible, sino fuente del sistema
    let font: UIFont
    print("🎨 drawCurvedText: customFontName = \(curvedText.customFontName ?? "nil")")
    if let customFontName = curvedText.customFontName,
       let customFont = UIFont(name: customFontName, size: scaledFontSize) {
      font = customFont
      print("✅ drawCurvedText: Usando fuente personalizada \(customFontName)")
    } else {
      font = UIFont.systemFont(ofSize: scaledFontSize, weight: uiFontWeight)
      print("❌ drawCurvedText: Usando fuente del sistema (customFontName: \(curvedText.customFontName ?? "nil"))")
    }
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

  func drawWeatherOverlay(
    _ weather: WeatherOverlay, in context: CGContext, imageSize: CGSize, scale: CGFloat
  ) {
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
      .foregroundColor: UIColor.white,
    ]

    let locationAttributes: [NSAttributedString.Key: Any] = [
      .font: locationFont,
      .foregroundColor: UIColor.white,
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
    context.setShadow(
      offset: CGSize(width: 0, height: 4 * scale), blur: 8 * scale,
      color: UIColor.black.withAlphaComponent(0.5).cgColor)
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
    context.setShadow(
      offset: CGSize(width: 0, height: 4 * scale), blur: 8 * scale,
      color: UIColor.black.withAlphaComponent(0.5).cgColor)
    locationString.draw(in: locationRect, withAttributes: locationAttributes)
    context.restoreGState()

    context.restoreGState()
  }

  func drawLocationOverlay(
    _ location: LocationOverlay, in context: CGContext, imageSize: CGSize, scale: CGFloat
  ) {
    context.saveGState()

    // Configuración de posicionamiento: esquina inferior derecha con padding escalado
    let padding: CGFloat = 20 * scale

    // Fuentes con tamaños escalados
    guard let neighborhoodFont = UIFont(name: "Ari-W9500Bold", size: 22 * scale) else { return }
    guard let infoFont = UIFont(name: "Ari-W9500Display", size: 14 * scale) else { return }

    // Atributos de texto
    let neighborhoodAttributes: [NSAttributedString.Key: Any] = [
      .font: neighborhoodFont,
      .foregroundColor: UIColor.white,
    ]

    let infoAttributes: [NSAttributedString.Key: Any] = [
      .font: infoFont,
      .foregroundColor: UIColor.white.withAlphaComponent(0.9),
    ]

    // Calcular tamaños
    let neighborhoodString = location.neighborhood.uppercased() as NSString
    let neighborhoodSize = neighborhoodString.size(withAttributes: neighborhoodAttributes)

    let dateString = location.date as NSString
    let dateSize = dateString.size(withAttributes: infoAttributes)

    let cityString = "\(location.city), \(location.country)" as NSString
    let citySize = cityString.size(withAttributes: infoAttributes)

    // Calcular el ancho máximo y altura total
    let maxWidth = max(neighborhoodSize.width, dateSize.width, citySize.width)
    let vStackSpacing: CGFloat = 6 * scale
    let totalHeight =
      neighborhoodSize.height + vStackSpacing + dateSize.height + vStackSpacing + citySize.height

    // Posición inicial (esquina inferior derecha, alineado a la izquierda)
    let baseX = imageSize.width - maxWidth - padding - (16 * scale)  // 16 es el padding interno
    let baseY = imageSize.height - totalHeight - padding - (16 * scale)

    // Dibujar barrio
    let neighborhoodRect = CGRect(
      x: baseX,
      y: baseY,
      width: neighborhoodSize.width,
      height: neighborhoodSize.height
    )
    context.saveGState()
    context.setShadow(
      offset: CGSize(width: 0, height: 4 * scale), blur: 8 * scale,
      color: UIColor.black.withAlphaComponent(0.5).cgColor)
    neighborhoodString.draw(in: neighborhoodRect, withAttributes: neighborhoodAttributes)
    context.restoreGState()

    // Dibujar fecha
    let dateRect = CGRect(
      x: baseX,
      y: baseY + neighborhoodSize.height + vStackSpacing,
      width: dateSize.width,
      height: dateSize.height
    )
    context.saveGState()
    context.setShadow(
      offset: CGSize(width: 0, height: 4 * scale), blur: 8 * scale,
      color: UIColor.black.withAlphaComponent(0.5).cgColor)
    dateString.draw(in: dateRect, withAttributes: infoAttributes)
    context.restoreGState()

    // Dibujar ciudad y país
    let cityRect = CGRect(
      x: baseX,
      y: baseY + neighborhoodSize.height + vStackSpacing + dateSize.height + vStackSpacing,
      width: citySize.width,
      height: citySize.height
    )
    context.saveGState()
    context.setShadow(
      offset: CGSize(width: 0, height: 4 * scale), blur: 8 * scale,
      color: UIColor.black.withAlphaComponent(0.5).cgColor)
    cityString.draw(in: cityRect, withAttributes: infoAttributes)
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

  func loadLocationData() {
    // Pedir ubicación actual
    locationManager.requestLocation()

    // Esperar un momento para que se obtenga la ubicación
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      self.locationManager.getLocationDetails { result in
        switch result {
        case .success(let locationInfo):
          // Obtener la fecha actual formateada
          let dateFormatter = DateFormatter()
          dateFormatter.locale = Locale(identifier: "es_ES")
          dateFormatter.dateFormat = "dd, MMMM, yyyy"
          let currentDate = dateFormatter.string(from: Date())

          // Crear overlay con información real
          let realLocation = LocationOverlay(
            neighborhood: locationInfo.neighborhood,
            date: currentDate,
            city: locationInfo.city,
            country: locationInfo.country
          )

          DispatchQueue.main.async {
            self.locationOverlay = realLocation
            self.showingTemplatePicker = false
            self.isLoadingTemplate = false
          }

        case .failure(let error):
          print("❌ Error obteniendo detalles de ubicación: \(error.localizedDescription)")

          // Fallback a datos de ejemplo
          let dateFormatter = DateFormatter()
          dateFormatter.locale = Locale(identifier: "es_ES")
          dateFormatter.dateFormat = "dd, MMMM, yyyy"
          let currentDate = dateFormatter.string(from: Date())

          let fallbackLocation = LocationOverlay(
            neighborhood: "Ubicación Actual",
            date: currentDate,
            city: "Santiago",
            country: "Chile"
          )

          DispatchQueue.main.async {
            self.locationOverlay = fallbackLocation
            self.showingTemplatePicker = false
            self.isLoadingTemplate = false
          }
        }
      }
    }
  }
}

// MARK: - Sticker Views
extension PhotoEditorView {
  struct StickerPickerSheetView: View {
    let availableStickers: [StickerInfo]
    @Binding var isLoadingStickers: Bool
    let onStickerSelected: (StickerInfo) -> Void
    let onLoadStickers: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
      NavigationView {
        VStack(spacing: 20) {
          // Header
          HStack {
            Text("Seleccionar Sticker")
              .font(.title2)
              .fontWeight(.bold)
            
            Spacer()
            
            Button("Cancelar") {
              dismiss()
            }
            .foregroundColor(.blue)
          }
          .padding(.horizontal)
          .padding(.top)
          
          // Contenido principal
          if isLoadingStickers {
            // Loading state
            VStack(spacing: 20) {
              Spacer()
              
              ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
              
              Text("Cargando stickers...")
                .font(.body)
                .foregroundColor(.secondary)
              
              Spacer()
            }
          } else if availableStickers.isEmpty {
            // Empty state
            VStack(spacing: 20) {
              Spacer()
              
              Image(systemName: "photo")
                .font(.system(size: 60))
                .foregroundColor(.gray)
              
              Text("No hay stickers disponibles")
                .font(.body)
                .foregroundColor(.secondary)
              
              Button("Recargar") {
                onLoadStickers()
              }
              .buttonStyle(.borderedProminent)
              
              Spacer()
            }
          } else {
            // Grid de stickers
            ScrollView {
              LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 4), spacing: 16) {
                ForEach(Array(availableStickers.enumerated()), id: \.offset) { index, stickerInfo in
                  Button(action: {
                    onStickerSelected(stickerInfo)
                  }) {
                    VStack(spacing: 8) {
                      // Cargar imagen desde URL
                      AsyncImage(url: URL(string: stickerInfo.thumbnail ?? stickerInfo.url)) { image in
                        image
                          .resizable()
                          .aspectRatio(contentMode: .fit)
                          .frame(width: 60, height: 60)
                          .background(Color.gray.opacity(0.1))
                          .cornerRadius(12)
                          .overlay(
                            RoundedRectangle(cornerRadius: 12)
                              .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                          )
                      } placeholder: {
                        // Placeholder mientras carga
                        RoundedRectangle(cornerRadius: 12)
                          .fill(Color.gray.opacity(0.1))
                          .frame(width: 60, height: 60)
                          .overlay(
                            ProgressView()
                              .scaleEffect(0.8)
                          )
                      }
                      
                      Text(stickerInfo.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    }
                  }
                  .buttonStyle(PlainButtonStyle())
                }
              }
              .padding(.horizontal)
            }
          }
          
          Spacer()
        }
        .navigationBarHidden(true)
        .onAppear {
          // Cargar stickers cuando aparece el modal
          if availableStickers.isEmpty && !isLoadingStickers {
            onLoadStickers()
          }
        }
      }
    }
  }
  
struct StickerElementView: View {
  let stickerElement: StickerElement
  let onDrag: (CGSize) -> Void
  let onScale: (CGFloat) -> Void
  let onRotation: (Double) -> Void
  let onDelete: () -> Void
  
  // Professional transform state management
  @State private var dragOffset: CGSize = .zero
  @State private var scaleOffset: CGFloat = 1.0
  @State private var rotationOffset: Double = 0.0
  
  // Gesture tracking
  @State private var lastDragValue: CGSize = .zero
  @State private var lastScaleValue: CGFloat = 1.0
  @State private var lastRotationValue: Double = 0.0
  
  // Drag detection
  @State private var isActuallyDragging: Bool = false
  @State private var dragStartTime: Date = Date()
  
  // Gesture state tracking
  @State private var isScaling: Bool = false
  @State private var isRotating: Bool = false
    
    var body: some View {
      ZStack {
        Group {
          if let imageURL = stickerElement.imageURL, !imageURL.isEmpty {
            // Cargar imagen desde URL
            AsyncImage(url: URL(string: imageURL)) { image in
              image
                .resizable()
                .aspectRatio(contentMode: .fit)
            } placeholder: {
              // Placeholder mientras carga
              RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .overlay(
                  ProgressView()
                    .scaleEffect(0.8)
                )
            }
          } else {
            // Usar imagen local
            Image(stickerElement.imageName)
              .resizable()
              .aspectRatio(contentMode: .fit)
          }
        }
        .frame(width: 80, height: 80)
        .padding(20) // Área táctil invisible más grande
        .contentShape(Rectangle())
        .scaleEffect(stickerElement.scale * scaleOffset)
        .rotationEffect(.degrees(stickerElement.rotation + rotationOffset))
        .position(
          x: stickerElement.position.x + dragOffset.width,
          y: stickerElement.position.y + dragOffset.height
        )
        .highPriorityGesture(
          TapGesture(count: 2)
            .onEnded { _ in
              // Double tap to delete
              print("🔥 Double tap detected - deleting sticker")
              onDelete()
            }
        )
        .gesture(
          // Professional gesture system - Industry Standard Approach
          DragGesture(minimumDistance: 0)
            .onChanged { value in
              dragOffset = value.translation
            }
            .onEnded { _ in
              onDrag(dragOffset)
              dragOffset = .zero
            }
        )
        .simultaneousGesture(
          MagnificationGesture()
            .onChanged { value in
              isScaling = true
              // More robust scaling calculation with strict limits
              if lastScaleValue == 1.0 {
                lastScaleValue = value
              }
              let delta = value / lastScaleValue
              lastScaleValue = value
              
              // Calculate new scale with limits
              let currentScale = stickerElement.scale * scaleOffset
              let newScale = currentScale * delta
              
              // Apply strict limits: 0.8x to 2.5x (20% smaller max)
              if newScale >= 0.8 && newScale <= 2.5 {
                scaleOffset *= delta
                onScale(delta)
              }
            }
            .onEnded { _ in
              isScaling = false
              // Don't reset - keep the final state
              lastScaleValue = 1.0
              // scaleOffset stays at final value
            }
        )
        .simultaneousGesture(
          RotationGesture()
            .onChanged { value in
              isRotating = true
              // More robust rotation calculation
              if lastRotationValue == 0.0 {
                lastRotationValue = value.degrees
              }
              let delta = value.degrees - lastRotationValue
              lastRotationValue = value.degrees
              
              // Only apply rotation if delta is significant
              if abs(delta) > 0.5 {
                rotationOffset += delta
                onRotation(delta)
              }
            }
            .onEnded { _ in
              isRotating = false
              // Don't reset - keep the final state
              lastRotationValue = 0.0
              // rotationOffset stays at final value
            }
        )
            }
        }
    }
}

#Preview {
    PhotoEditorView()
}
