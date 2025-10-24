import SwiftUI
import PhotosUI

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
                                            showingTextEditor = true
                                        }
                                    )
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
                                    Text("Agregar Texto")
                                        .font(.caption)
                                }
                                .foregroundColor(.purple)
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
                    showingFontMenu = false
                    editingText = "Toca para editar"
                    showingTextEditor = true
                }
            }
            .sheet(isPresented: $showingTextEditor) {
                TextInputView(
                    text: $editingText,
                    fontStyle: currentFontStyle ?? FontStyle(name: "Clásico", size: 24, weight: .regular, color: .white),
                    onDone: {
                        if !editingText.isEmpty {
                            if let selectedElement = selectedTextElement,
                               let index = textElements.firstIndex(where: { $0.id == selectedElement.id }) {
                                textElements[index].text = editingText
                            } else if let fontStyle = currentFontStyle {
                                let newElement = TextElement(
                                    text: editingText,
                                    position: CGPoint(x: UIScreen.main.bounds.width / 2, y: 200),
                                    fontSize: fontStyle.size,
                                    fontWeight: fontStyle.weight,
                                    color: fontStyle.color
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
            
            for textElement in textElements {
                let uiFontWeight = convertToUIFontWeight(textElement.fontWeight)
                let scaledFontSize = textElement.fontSize * textElement.scale
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: scaledFontSize, weight: uiFontWeight),
                    .foregroundColor: UIColor(textElement.color)
                ]
                
                let attributedString = NSAttributedString(string: textElement.text, attributes: attributes)
                let textSize = attributedString.size()
                let textRect = CGRect(
                    x: textElement.position.x - textSize.width / 2,
                    y: textElement.position.y - textSize.height / 2,
                    width: textSize.width,
                    height: textSize.height
                )
                attributedString.draw(in: textRect)
            }
        }
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
            return 100 // Área grande para facilitar el agarre
        } else {
            return max(40, 30 * textElement.scale)
        }
    }
    
    var body: some View {
        Text(textElement.text)
            .font(.system(size: textElement.fontSize, weight: textElement.fontWeight))
            .foregroundColor(textElement.color)
            .lineLimit(1)
            .fixedSize()
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.3))
            .cornerRadius(8)
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

struct FontStyle {
    let name: String
    let size: CGFloat
    let weight: Font.Weight
    let color: Color
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
            VStack(spacing: 16) {
                Spacer()
                
                TextField("Escribe tu texto aquí", text: $text)
                    .font(.system(size: fontStyle.size, weight: fontStyle.weight))
                    .foregroundColor(fontStyle.color)
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
                    .foregroundColor(remainingCharacters < 20 ? .red : .white.opacity(0.7))
                    .padding(.bottom, 8)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.8))
            .navigationTitle("Agregar Texto")
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
                isFocused = true
            }
        }
    }
}

struct FontMenuView: View {
    let onFontSelected: (FontStyle) -> Void
    @Environment(\.dismiss) private var dismiss
    
    private let fontStyles: [FontStyle] = [
        FontStyle(name: "Clásico", size: 32, weight: .regular, color: .white),
        FontStyle(name: "Bold", size: 36, weight: .bold, color: .white),
        FontStyle(name: "Elegante", size: 28, weight: .light, color: .white),
        FontStyle(name: "Moderno", size: 34, weight: .medium, color: .white),
        FontStyle(name: "Amarillo", size: 32, weight: .semibold, color: .yellow),
        FontStyle(name: "Rojo", size: 32, weight: .semibold, color: .red),
        FontStyle(name: "Azul", size: 32, weight: .semibold, color: .blue),
        FontStyle(name: "Verde", size: 32, weight: .semibold, color: .green),
        FontStyle(name: "Rosa", size: 32, weight: .semibold, color: .pink),
        FontStyle(name: "Naranja", size: 32, weight: .semibold, color: .orange),
        FontStyle(name: "Morado", size: 32, weight: .semibold, color: .purple),
        FontStyle(name: "Cian", size: 32, weight: .semibold, color: .cyan)
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
                                    .font(.system(size: 32, weight: fontStyle.weight))
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

#Preview {
    PhotoEditorView()
}
