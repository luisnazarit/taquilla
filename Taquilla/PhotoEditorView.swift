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
    
    // Curved text states
    @State private var curvedTextElements: [CurvedTextElement] = []
    @State private var isDrawingMode = false
    @State private var currentDrawingPath: [CGPoint] = []
    @State private var drawingMode: DrawingMode = .none
    @State private var showingCurvedTextEditor = false
    @State private var editingCurvedText = ""
    @State private var currentDrawnPath: [CGPoint] = []
    
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
                                                showingTextEditor = true
                                            }
                                        )
                                    }
                                    
                                    // Textos curvos
                                    ForEach(curvedTextElements) { curvedText in
                                        CurvedTextView(curvedText: curvedText) {
                                            // TODO: Editar texto curvo
                                        }
                                    }
                                    
                                    // Canvas para dibujar cuando está en modo dibujo
                                    if isDrawingMode {
                                        DrawingCanvasView(
                                            currentPath: $currentDrawingPath,
                                            drawingMode: $drawingMode,
                                            onFinish: { path in
                                                currentDrawnPath = path
                                                isDrawingMode = false
                                                showingCurvedTextEditor = true
                                            }
                                        )
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
            .sheet(isPresented: $showingCurvedTextEditor) {
                CurvedTextInputView(
                    text: $editingCurvedText,
                    path: currentDrawnPath,
                    onDone: {
                        if !editingCurvedText.isEmpty && !currentDrawnPath.isEmpty {
                            let newCurvedText = CurvedTextElement(
                                text: editingCurvedText,
                                path: currentDrawnPath,
                                fontSize: 24,
                                fontWeight: .semibold,
                                color: .white
                            )
                            curvedTextElements.append(newCurvedText)
                        }
                        editingCurvedText = ""
                        currentDrawnPath = []
                        currentDrawingPath = []
                        drawingMode = .none
                        showingCurvedTextEditor = false
                    },
                    onCancel: {
                        editingCurvedText = ""
                        currentDrawnPath = []
                        currentDrawingPath = []
                        drawingMode = .none
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
        let font = UIFont.systemFont(ofSize: curvedText.fontSize, weight: uiFontWeight)
        let characterWidth = curvedText.fontSize * 0.6
        let totalTextWidth = characterWidth * CGFloat(curvedText.text.count)
        let startOffset = (pathLength - totalTextWidth) / 2
        
        context.saveGState()
        
        for (index, character) in curvedText.text.enumerated() {
            let distance = startOffset + (characterWidth * CGFloat(index))
            
            if let positionInfo = PathUtilities.pointAtDistance(curvedText.path, distance: distance) {
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: UIColor(curvedText.color)
                ]
                
                let charString = String(character) as NSString
                let charSize = charString.size(withAttributes: attributes)
                
                context.saveGState()
                context.translateBy(x: positionInfo.point.x, y: positionInfo.point.y)
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

// MARK: - Curved Text Views

struct CurvedTextView: View {
    let curvedText: CurvedTextElement
    let onTap: () -> Void
    
    var body: some View {
        ZStack {
            // Renderizar cada letra siguiendo el path
            ForEach(Array(curvedText.text.enumerated()), id: \.offset) { index, character in
                if let position = calculateLetterPosition(for: index) {
                    Text(String(character))
                        .font(.system(size: curvedText.fontSize, weight: curvedText.fontWeight))
                        .foregroundColor(curvedText.color)
                        .position(position.point)
                        .rotationEffect(Angle(radians: Double(position.angle)))
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
    
    private func calculateLetterPosition(for index: Int) -> (point: CGPoint, angle: CGFloat)? {
        let pathLength = PathUtilities.pathLength(curvedText.path)
        guard pathLength > 0 else { return nil }
        
        // Estimar el ancho de cada carácter
        let characterWidth = curvedText.fontSize * 0.6
        
        // Calcular el offset para centrar el texto en el path
        let totalTextWidth = characterWidth * CGFloat(curvedText.text.count)
        let startOffset = (pathLength - totalTextWidth) / 2
        
        // Posición de esta letra en el path
        let distance = startOffset + (characterWidth * CGFloat(index))
        
        return PathUtilities.pointAtDistance(curvedText.path, distance: distance)
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
