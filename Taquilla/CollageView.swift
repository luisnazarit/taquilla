import SwiftUI
import Photos
import PhotosUI

struct CollageView: View {
    @EnvironmentObject var photoManager: PhotoManager
    @State private var selectedPhotoCount = 2
    @State private var selectedTemplate: CollageTemplate?
    @State private var selectedImages: [UIImage?] = []
    @State private var showingImagePicker = false
    @State private var currentImageIndex = 0
    @State private var showingSaveSuccess = false
    
    private let photoCountOptions = [2, 3, 4, 5, 6]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Selector de número de fotos (solo si no hay plantilla seleccionada)
                if selectedTemplate == nil {
                    photoCountSelector
                }
                
                // Vista principal
                if selectedTemplate == nil {
                    // Mostrar plantillas disponibles
                    templateSelectionView
                } else {
                    // Mostrar editor de collage
                    collageEditorView
                }
            }
            .navigationTitle(selectedTemplate == nil ? "Crear Collage" : "")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Botón para cambiar plantilla (solo cuando hay una seleccionada)
                if selectedTemplate != nil {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            selectedTemplate = nil
                            selectedImages = []
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.left")
                                Text("Cambiar plantilla")
                            }
                            .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: Binding(
                get: { selectedImages[safe: currentImageIndex] ?? nil },
                set: { newImage in
                    if let image = newImage {
                        selectedImages[currentImageIndex] = image
                    }
                }
            ))
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
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(photoCountOptions, id: \.self) { count in
                    Button(action: {
                        selectedPhotoCount = count
                        selectedTemplate = nil
                        selectedImages = []
                    }) {
                        VStack(spacing: 4) {
                            Text("\(count)")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("fotos")
                                .font(.caption2)
                        }
                        .frame(width: 70, height: 60)
                        .background(selectedPhotoCount == count ? Color.blue : Color.gray.opacity(0.2))
                        .foregroundColor(selectedPhotoCount == count ? .white : .primary)
                        .cornerRadius(12)
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - Template Selection View
    private var templateSelectionView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                ForEach(CollageTemplates.templates(for: selectedPhotoCount)) { template in
                    TemplatePreviewView(template: template)
                        .aspectRatio(1, contentMode: .fit)
                        .onTapGesture {
                            selectTemplate(template)
                        }
                }
            }
            .padding()
        }
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
                        .aspectRatio(3.0/4.0, contentMode: .fit)
                        .padding()
                    }
                    
                    // Botón de guardar
                    if selectedImages.compactMap({ $0 }).count == selectedPhotoCount {
                        Button(action: saveCollage) {
                            HStack {
                                Image(systemName: "square.and.arrow.down")
                                Text("Guardar Collage")
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
    
    private func saveCollage() {
        guard let template = selectedTemplate else { return }
        
        // Crear imagen del collage en formato 3:4 (1080x1440)
        // Más grande que cuadrado, menos vertical que Stories
        let size = CGSize(width: 1080, height: 1440)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let collageImage = renderer.image { context in
            // Fondo gris oscuro (en lugar de gradiente claro)
            let backgroundColor = UIColor(red: 0.20, green: 0.20, blue: 0.22, alpha: 1.0) // Gris oscuro
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
                        (UIColor.black, CGSize(width: 18, height: 18)),       // Negro exterior
                        (UIColor.cyan, CGSize(width: 12, height: 12)),        // Cyan
                        (UIColor(red: 1.0, green: 0.0, blue: 1.0, alpha: 1.0), 
                         CGSize(width: 6, height: 6)),                        // Magenta
                        (UIColor.black, CGSize(width: 2, height: 2))          // Negro interior (contraste)
                    ]
                    
                    // Dibujar las 3 sombras para esta foto específica
                    for shadow in shadows {
                        let shadowRect = rect.offsetBy(dx: shadow.offset.width, dy: shadow.offset.height)
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
                    
                    context.cgContext.restoreGState() // Restaurar clip
                    context.cgContext.restoreGState() // Restaurar estado general
                }
            }
        }
        
        // Guardar usando PhotoManager
        photoManager.savePhoto(collageImage) { success in
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
                
                // Reset después del mensaje
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    selectedTemplate = nil
                    selectedImages = []
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
                            x: frame.x * geometry.size.width + (frame.width * geometry.size.width) / 2,
                            y: frame.y * geometry.size.height + (frame.height * geometry.size.height) / 2
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
                                            .font(.system(size: min(frameRect.width, frameRect.height) * 0.15))
                                            .foregroundColor(.gray)
                                        Text("Toca para\nagregar")
                                            .font(.system(size: min(frameRect.width, frameRect.height) * 0.08))
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


