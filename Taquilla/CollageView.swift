import SwiftUI
import Photos
import PhotosUI

struct CollageView: View {
    @State private var selectedPhotoCount = 2
    @State private var selectedTemplate: CollageTemplate?
    @State private var selectedImages: [UIImage?] = []
    @State private var showingImagePicker = false
    @State private var currentImageIndex = 0
    
    private let photoCountOptions = [2, 3, 4, 5, 6]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Selector de número de fotos
                photoCountSelector
                
                // Vista principal
                if selectedTemplate == nil {
                    // Mostrar plantillas disponibles
                    templateSelectionView
                } else {
                    // Mostrar editor de collage
                    collageEditorView
                }
            }
            .navigationTitle("Crear Collage")
            .navigationBarTitleDisplayMode(.inline)
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
            // Botón de volver
            HStack {
                Button(action: {
                    selectedTemplate = nil
                    selectedImages = []
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Cambiar plantilla")
                    }
                    .foregroundColor(.blue)
                }
                Spacer()
            }
            .padding(.horizontal)
            
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
                        .aspectRatio(1, contentMode: .fit)
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
        
        // Crear imagen del collage
        let size = CGSize(width: 1080, height: 1080)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let collageImage = renderer.image { context in
            // Fondo blanco
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Dibujar cada foto en su frame
            for (index, frame) in template.frames.enumerated() {
                if let image = selectedImages[safe: index] ?? nil {
                    let rect = CGRect(
                        x: frame.x * size.width,
                        y: frame.y * size.height,
                        width: frame.width * size.width,
                        height: frame.height * size.height
                    )
                    
                    // Dibujar imagen con aspect fill centrado
                    context.cgContext.saveGState()
                    
                    // Clip al área del frame
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
                    
                    context.cgContext.restoreGState()
                }
            }
        }
        
        // Guardar en librería
        UIImageWriteToSavedPhotosAlbum(collageImage, nil, nil, nil)
        
        // Reset
        selectedTemplate = nil
        selectedImages = []
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
            Color.white
            
            GeometryReader { geometry in
                ForEach(Array(template.frames.enumerated()), id: \.offset) { index, frame in
                    ZStack {
                        if let image = images[safe: index] ?? nil {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(
                                    width: frame.width * geometry.size.width - 4,
                                    height: frame.height * geometry.size.height - 4
                                )
                                .clipped()
                        } else {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .overlay(
                                    VStack {
                                        Image(systemName: "photo.badge.plus")
                                            .font(.system(size: 40))
                                            .foregroundColor(.gray)
                                        Text("Toca para agregar")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                )
                        }
                    }
                    .frame(
                        width: frame.width * geometry.size.width - 4,
                        height: frame.height * geometry.size.height - 4
                    )
                    .cornerRadius(4)
                    .position(
                        x: frame.x * geometry.size.width + (frame.width * geometry.size.width) / 2,
                        y: frame.y * geometry.size.height + (frame.height * geometry.size.height) / 2
                    )
                    .onTapGesture {
                        onTapFrame(index)
                    }
                }
            }
        }
        .cornerRadius(12)
        .shadow(radius: 8)
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

