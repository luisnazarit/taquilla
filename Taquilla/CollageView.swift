import Photos
import PhotosUI
import SwiftUI

struct CollageView: View {
  @EnvironmentObject var photoManager: PhotoManager
  @State private var selectedPhotoCount = 1
  @State private var selectedTemplate: CollageTemplate?
  @State private var selectedImages: [UIImage?] = []
  @State private var showingImagePicker = false
  @State private var currentImageIndex = 0
  @State private var showingSaveSuccess = false
  @State private var showingPhotoEditor = true  // Iniciar con editor de 1 foto
  @State private var selectedSingleImage: UIImage?
  @State private var collageImageForEditing: UIImage?

  private let photoCountOptions = [1, 2, 3, 4, 5, 6]

  var body: some View {
    NavigationView {
      Group {
        // Si estamos editando una foto, mostrar PhotoEditorView directamente
        if let collageImage = collageImageForEditing {
          PhotoEditorView(initialImage: collageImage)
            .environmentObject(photoManager)
        } else if showingPhotoEditor && selectedPhotoCount == 1
          && selectedSingleImage != nil
        {
          PhotoEditorView(initialImage: selectedSingleImage!)
            .environmentObject(photoManager)
        } else {
          // Vista normal con ZStack y fondo
          ZStack {
            // Fondo de la aplicación
            Image("Background")
              .resizable()
              .aspectRatio(contentMode: .fill)
              .ignoresSafeArea()

            VStack(spacing: 0) {
              // Selector de número de fotos (no mostrar cuando se está editando 1 foto con imagen seleccionada)
              if selectedTemplate == nil
                && !(showingPhotoEditor && selectedPhotoCount == 1
                  && selectedSingleImage != nil)
              {
                photoCountSelector
              }

              // Vista principal
              if showingPhotoEditor && selectedPhotoCount == 1 {
                // Mostrar pantalla de selección de foto (como PhotoEditorView)
                singlePhotoSelectionView
              } else if selectedTemplate == nil {
                // Mostrar plantillas disponibles (para 2-6 fotos)
                templateSelectionView
              } else {
                // Mostrar editor de collage
                collageEditorView
              }
            }
          }
        }
      }
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        // Botón para volver
        if collageImageForEditing != nil || selectedTemplate != nil
          || (showingPhotoEditor && selectedSingleImage != nil)
        {
          ToolbarItem(placement: .navigationBarLeading) {
            Button(action: {
              if collageImageForEditing != nil {
                // Volver desde editor de collage
                collageImageForEditing = nil
                selectedTemplate = nil
                selectedImages = []
              } else if showingPhotoEditor && selectedSingleImage != nil {
                // Volver desde editor de 1 foto (con imagen) - mantener en modo 1 foto
                selectedSingleImage = nil
                // No cambiar showingPhotoEditor para mantener la pantalla de selección
              } else {
                selectedTemplate = nil
                selectedImages = []
              }
            }) {
              HStack(spacing: 4) {
                Image(systemName: "arrow.left")
                Text(collageImageForEditing != nil ? "Volver" : "Volver")
              }
              .foregroundColor(.blue)
            }
          }
        }
      }
    }
    .sheet(isPresented: $showingImagePicker) {
      if selectedPhotoCount == 1 {
        // Selector para foto única (va al editor completo)
        ImagePicker(
          selectedImage: Binding(
            get: { selectedSingleImage },
            set: { newImage in
              selectedSingleImage = newImage
            }
          ))
      } else {
        // Selector para collage
        ImagePicker(
          selectedImage: Binding(
            get: { selectedImages[safe: currentImageIndex] ?? nil },
            set: { newImage in
              if let image = newImage {
                selectedImages[currentImageIndex] = image
              }
            }
          ))
      }
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
              Text("Collage guardado exitosamente")
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

  // MARK: - Photo Count Selector
  private var photoCountSelector: some View {
    HStack(spacing: 8) {
      ForEach(photoCountOptions, id: \.self) { count in
        Button(action: {
          selectedPhotoCount = count
          selectedTemplate = nil
          selectedImages = []
          selectedSingleImage = nil

          // Si selecciona 1 foto, mostrar pantalla de selección
          if count == 1 {
            showingPhotoEditor = true
            // No abrir selector automáticamente
          } else {
            showingPhotoEditor = false
          }
        }) {
          VStack(spacing: 2) {
            Text("\(count)")
              .font(.title3)
              .fontWeight(.bold)
            Text(count == 1 ? "foto" : "fotos")
              .font(.caption2)
          }
          .frame(width: 50, height: 45)
          .background(selectedPhotoCount == count ? Color.blue : Color.gray.opacity(0.2))
          .foregroundColor(selectedPhotoCount == count ? .white : .primary)
          .cornerRadius(8)
        }
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .background(Color.clear)
  }

  // MARK: - Single Photo Selection View
  private var singlePhotoSelectionView: some View {
    VStack(spacing: 30) {
      Spacer()

      VStack(spacing: 20) {
        // Logo más pequeño y centrado
        Image("Logo")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: 120, height: 120)

        // Texto principal
        Text("Elige tu foto más taquillera")
          .font(.title2)
          .fontWeight(.semibold)
          .foregroundColor(.primary)
          .multilineTextAlignment(.center)

        // Botón de selección de foto
        Button(action: {
          showingImagePicker = true
        }) {
          HStack(spacing: 12) {
            Image(systemName: "plus.circle.fill")
              .font(.title2)
              .foregroundColor(.pink)

            Text("Seleccionar foto")
              .font(.headline)
              .fontWeight(.medium)
          }
          .foregroundColor(.primary)
          .padding(.horizontal, 30)
          .padding(.vertical, 15)
          .background(
            RoundedRectangle(cornerRadius: 25)
              .stroke(Color.gray.opacity(0.3), lineWidth: 2)
          )
        }
      }

      Spacer()

      // Texto de descripción
      Text(
        "Taquilla es una app que periódicamente actualiza sus diseños, totalmente gratuita, diseñada en Chile con ❤️"
      )
      .font(.caption)
      .foregroundColor(.secondary)
      .multilineTextAlignment(.center)
      .padding(.horizontal, 40)
      .padding(.bottom, 30)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.clear)
    .onTapGesture {
      // Toda el área es clickeable
      showingImagePicker = true
    }
  }

  // MARK: - Empty State View
  private var emptyStateView: some View {
    VStack(spacing: 20) {
      Spacer()

      ProgressView()
        .scaleEffect(1.5)

      Text("Selecciona una foto...")
        .font(.headline)
        .foregroundColor(.secondary)

      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.clear)
  }

  // MARK: - Template Selection View
  private var templateSelectionView: some View {
    ScrollView {
      LazyVGrid(
        columns: [
          GridItem(.flexible(), spacing: 16),
          GridItem(.flexible(), spacing: 16),
        ], spacing: 16
      ) {
        ForEach(CollageTemplates.templates(for: selectedPhotoCount)) { template in
          TemplatePreviewView(template: template)
            .aspectRatio(1, contentMode: .fit)
            .onTapGesture {
              selectTemplate(template)
            }
        }
      }
      .padding(.horizontal, 60)
      .padding(.vertical, 20)
    }
    .padding(.horizontal, 0)  // Asegurar que el ScrollView no tenga padding adicional
  }

  // MARK: - Collage Editor View
  private var collageEditorView: some View {
    VStack(spacing: 16) {
      // Preview del collage
      ScrollView {
        VStack(spacing: 16) {
          if let template = selectedTemplate {
            CollagePreviewView(
              template: template,
              images: selectedImages,
              onTapFrame: { index in
                currentImageIndex = index
                showingImagePicker = true
              }
            )
            .aspectRatio(3.0 / 4.0, contentMode: .fit)
            .padding()
          }

          // Botón para continuar editando
          if selectedImages.compactMap({ $0 }).count == selectedPhotoCount {
            Button(action: continueToEditor) {
              HStack {
                Image(systemName: "arrow.right.circle.fill")
                Text("Continuar editando")
              }
              .font(.headline)
              .foregroundColor(.white)
              .frame(maxWidth: .infinity)
              .padding()
              .background(Color.blue)
              .cornerRadius(12)
            }
            .padding(.horizontal)
          }
        }
      }
    }
  }

  // MARK: - Helper Functions
  private func selectTemplate(_ template: CollageTemplate) {
    selectedTemplate = template
    selectedImages = Array(repeating: nil, count: template.photoCount)
  }

  private func continueToEditor() {
    guard let template = selectedTemplate else { return }

    // Crear la imagen del collage
    let collageImage = createCollageImage(template: template)

    // Pasar al editor con la imagen del collage
    collageImageForEditing = collageImage
  }

  private func createCollageImage(template: CollageTemplate) -> UIImage {
    // Crear imagen del collage en formato 3:4 (1080x1440)
    let size = CGSize(width: 1080, height: 1440)
    let renderer = UIGraphicsImageRenderer(size: size)

    return renderer.image { context in
      // Fondo gris oscuro (en lugar de gradiente claro)
      let backgroundColor = UIColor(red: 0.20, green: 0.20, blue: 0.22, alpha: 1.0)  // Gris oscuro
      backgroundColor.setFill()
      context.cgContext.fill(CGRect(origin: .zero, size: size))

      // Área de contenido (centrada con padding)
      let contentPadding: CGFloat = 80
      let contentRect = CGRect(
        x: contentPadding,
        y: contentPadding,
        width: size.width - (contentPadding * 2),
        height: size.height - (contentPadding * 2)
      )

      // Dibujar cada foto con sombra estilo "Returns" INDIVIDUAL
      for (index, frame) in template.frames.enumerated() {
        if let image = selectedImages[safe: index] ?? nil {
          context.cgContext.saveGState()

          // Calcular rect del frame dentro del área de contenido CON OFFSET ALEATORIO
          let baseRect = CGRect(
            x: contentRect.origin.x + (frame.x * contentRect.width),
            y: contentRect.origin.y + (frame.y * contentRect.height),
            width: frame.width * contentRect.width,
            height: frame.height * contentRect.height
          )

          // Aplicar offset aleatorio
          let offsetRect = baseRect.offsetBy(
            dx: frame.offsetX * contentRect.width,
            dy: frame.offsetY * contentRect.height
          )

          // Aplicar escala para sobreposición (centrada en el rect)
          let scaledWidth = offsetRect.width * frame.scale
          let scaledHeight = offsetRect.height * frame.scale
          let rect = CGRect(
            x: offsetRect.midX - scaledWidth / 2,
            y: offsetRect.midY - scaledHeight / 2,
            width: scaledWidth,
            height: scaledHeight
          )

          // Sombras estilo "Returns" PARA ESTA FOTO
          // Orden: Negro (más lejos) → Cyan → Magenta → Negro (más cerca, para contraste)
          // 4 capas de sombra para máximo contraste y visibilidad
          let shadows: [(color: UIColor, offset: CGSize)] = [
            (UIColor.black, CGSize(width: 18, height: 18)),  // Negro exterior
            (UIColor.cyan, CGSize(width: 12, height: 12)),  // Cyan
            (
              UIColor(red: 1.0, green: 0.0, blue: 1.0, alpha: 1.0),
              CGSize(width: 6, height: 6)
            ),  // Magenta
            (UIColor.black, CGSize(width: 2, height: 2)),  // Negro interior (contraste)
          ]

          // Dibujar las 3 sombras para esta foto específica
          for shadow in shadows {
            let shadowRect = rect.offsetBy(
              dx: shadow.offset.width, dy: shadow.offset.height)
            shadow.color.setFill()
            context.cgContext.fill(shadowRect)
          }

          // Clip al área de la foto (sin las sombras)
          context.cgContext.saveGState()
          context.cgContext.addRect(rect)
          context.cgContext.clip()

          // Calcular el tamaño para aspect fill
          let imageAspect = image.size.width / image.size.height
          let frameAspect = rect.width / rect.height

          var drawRect = rect

          if imageAspect > frameAspect {
            // Imagen más ancha que el frame → ajustar por altura
            let scaledWidth = rect.height * imageAspect
            drawRect.size.width = scaledWidth
            drawRect.size.height = rect.height
            drawRect.origin.x = rect.origin.x - (scaledWidth - rect.width) / 2
            drawRect.origin.y = rect.origin.y
          } else {
            // Imagen más alta que el frame → ajustar por ancho
            let scaledHeight = rect.width / imageAspect
            drawRect.size.width = rect.width
            drawRect.size.height = scaledHeight
            drawRect.origin.x = rect.origin.x
            drawRect.origin.y = rect.origin.y - (scaledHeight - rect.height) / 2
          }

          // Dibujar la imagen
          image.draw(in: drawRect)

          context.cgContext.restoreGState()  // Restaurar clip
          context.cgContext.restoreGState()  // Restaurar estado general
        }
      }
    }
  }
}

// MARK: - Template Preview View
struct TemplatePreviewView: View {
  let template: CollageTemplate

  var body: some View {
    ZStack {
      Color.gray.opacity(0.2)

      GeometryReader { geometry in
        ForEach(Array(template.frames.enumerated()), id: \.offset) { index, frame in
          Rectangle()
            .fill(Color.blue.opacity(0.3))
            .overlay(
              Text("\(index + 1)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            )
            .frame(
              width: frame.width * geometry.size.width - 2,
              height: frame.height * geometry.size.height - 2
            )
            .position(
              x: frame.x * geometry.size.width + (frame.width * geometry.size.width)
                / 2,
              y: frame.y * geometry.size.height
                + (frame.height * geometry.size.height) / 2
            )
        }
      }
    }
    .cornerRadius(12)
    .overlay(
      RoundedRectangle(cornerRadius: 12)
        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
    )
  }
}

// MARK: - Collage Preview View
struct CollagePreviewView: View {
  let template: CollageTemplate
  let images: [UIImage?]
  let onTapFrame: (Int) -> Void

  var body: some View {
    ZStack {
      // Fondo gris oscuro
      Color(red: 0.20, green: 0.20, blue: 0.22)

      GeometryReader { geometry in
        // Área de contenido (con padding proporcional)
        let contentPadding = geometry.size.width * 0.075
        let contentRect = CGRect(
          x: contentPadding,
          y: contentPadding,
          width: geometry.size.width - (contentPadding * 2),
          height: geometry.size.height - (contentPadding * 2)
        )

        ForEach(Array(template.frames.enumerated()), id: \.offset) { index, frame in
          let baseFrameRect = CGRect(
            x: contentRect.origin.x + (frame.x * contentRect.width),
            y: contentRect.origin.y + (frame.y * contentRect.height),
            width: frame.width * contentRect.width,
            height: frame.height * contentRect.height
          )

          // Aplicar offset aleatorio
          let offsetRect = CGRect(
            x: baseFrameRect.origin.x + (frame.offsetX * contentRect.width),
            y: baseFrameRect.origin.y + (frame.offsetY * contentRect.height),
            width: baseFrameRect.width,
            height: baseFrameRect.height
          )

          // Aplicar escala para sobreposición
          let scaledWidth = offsetRect.width * frame.scale
          let scaledHeight = offsetRect.height * frame.scale
          let frameRect = CGRect(
            x: offsetRect.midX - scaledWidth / 2,
            y: offsetRect.midY - scaledHeight / 2,
            width: scaledWidth,
            height: scaledHeight
          )

          ZStack {
            // Sombras estilo "Returns" INDIVIDUALES para cada foto
            // 4 capas: Negro exterior → Cyan → Magenta → Negro interior
            Rectangle()
              .fill(Color.black)
              .frame(width: frameRect.width, height: frameRect.height)
              .offset(x: 9, y: 9)

            Rectangle()
              .fill(Color.cyan)
              .frame(width: frameRect.width, height: frameRect.height)
              .offset(x: 6, y: 6)

            Rectangle()
              .fill(Color(red: 1.0, green: 0.0, blue: 1.0))
              .frame(width: frameRect.width, height: frameRect.height)
              .offset(x: 3, y: 3)

            Rectangle()
              .fill(Color.black)
              .frame(width: frameRect.width, height: frameRect.height)
              .offset(x: 1, y: 1)

            // Contenido de la foto
            if let image = images[safe: index] ?? nil {
              Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: frameRect.width, height: frameRect.height)
                .clipped()
            } else {
              Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: frameRect.width, height: frameRect.height)
                .overlay(
                  VStack(spacing: 8) {
                    Image(systemName: "photo.badge.plus")
                      .font(
                        .system(
                          size: min(frameRect.width, frameRect.height)
                            * 0.15)
                      )
                      .foregroundColor(.gray)
                    Text("Toca para\nagregar")
                      .font(
                        .system(
                          size: min(frameRect.width, frameRect.height)
                            * 0.08)
                      )
                      .foregroundColor(.gray)
                      .multilineTextAlignment(.center)
                  }
                )
            }
          }
          .position(x: frameRect.midX, y: frameRect.midY)
          .onTapGesture {
            onTapFrame(index)
          }
        }
      }
    }
    .cornerRadius(12)
    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
  }
}

// MARK: - Collection Extension
extension Collection {
  subscript(safe index: Index) -> Element? {
    return indices.contains(index) ? self[index] : nil
  }
}

#Preview {
  CollageView()
}
