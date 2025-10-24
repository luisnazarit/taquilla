import SwiftUI

struct TextEditorView: View {
    @State private var textElement: TextElement
    @Environment(\.dismiss) private var dismiss
    let onSave: (TextElement) -> Void
    
    @State private var selectedColor: Color = .white
    @State private var selectedFontSize: CGFloat = 24
    @State private var selectedFontWeight: Font.Weight = .medium
    
    private let colors: [Color] = [
        .white, .black, .red, .blue, .green, .yellow, .orange, .purple, .pink, .cyan
    ]
    
    private let fontSizes: [CGFloat] = [16, 20, 24, 28, 32, 36, 40, 48]
    
    private let fontWeights: [Font.Weight] = [.light, .regular, .medium, .semibold, .bold, .heavy]
    
    init(textElement: TextElement, onSave: @escaping (TextElement) -> Void) {
        self._textElement = State(initialValue: textElement)
        self.onSave = onSave
        self._selectedColor = State(initialValue: textElement.color)
        self._selectedFontSize = State(initialValue: textElement.fontSize)
        self._selectedFontWeight = State(initialValue: textElement.fontWeight)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Vista previa del texto
                VStack {
                    Text("Vista previa:")
                        .font(.headline)
                        .padding(.top)
                    
                    Text(textElement.text)
                        .font(.system(size: selectedFontSize, weight: selectedFontWeight))
                        .foregroundColor(selectedColor)
                        .padding()
                        .background(Color.black.opacity(0.1))
                        .cornerRadius(8)
                }
                
                // Editor de texto
                VStack(alignment: .leading, spacing: 12) {
                    Text("Texto:")
                        .font(.headline)
                    
                    TextField("Ingresa tu texto", text: $textElement.text)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // Selector de color
                VStack(alignment: .leading, spacing: 12) {
                    Text("Color:")
                        .font(.headline)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 10) {
                        ForEach(colors, id: \.self) { color in
                            Circle()
                                .fill(color)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle()
                                        .stroke(selectedColor == color ? Color.blue : Color.clear, lineWidth: 3)
                                )
                                .onTapGesture {
                                    selectedColor = color
                                    textElement.color = color
                                }
                        }
                    }
                }
                
                // Selector de tamaño
                VStack(alignment: .leading, spacing: 12) {
                    Text("Tamaño:")
                        .font(.headline)
                    
                    HStack {
                        Text("16")
                        Slider(value: $selectedFontSize, in: 16...60, step: 2)
                        Text("60")
                    }
                    .onChange(of: selectedFontSize) { newValue in
                        textElement.fontSize = newValue
                    }
                }
                
                // Selector de peso de fuente
                VStack(alignment: .leading, spacing: 12) {
                    Text("Estilo:")
                        .font(.headline)
                    
                    Picker("Peso de fuente", selection: $selectedFontWeight) {
                        Text("Ligero").tag(Font.Weight.light)
                        Text("Normal").tag(Font.Weight.regular)
                        Text("Medio").tag(Font.Weight.medium)
                        Text("Semi-bold").tag(Font.Weight.semibold)
                        Text("Bold").tag(Font.Weight.bold)
                        Text("Heavy").tag(Font.Weight.heavy)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: selectedFontWeight) { newValue in
                        textElement.fontWeight = newValue
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Editar Texto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Guardar") {
                        onSave(textElement)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    TextEditorView(
        textElement: TextElement(
            text: "Texto de ejemplo",
            position: CGPoint(x: 100, y: 100),
            fontSize: 24,
            fontWeight: .medium,
            color: .white
        ),
        onSave: { _ in }
    )
}
