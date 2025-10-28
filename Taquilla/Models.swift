import CoreImage
import SwiftUI
import UIKit
import Vision

// MARK: - Text Element Model
struct TextElement: Identifiable {
  let id = UUID()
  var text: String
  var position: CGPoint
  var fontSize: CGFloat
  var fontWeight: Font.Weight
  var color: Color
  var scale: CGFloat = 1.0
  var customFontName: String? = nil
  var shadows: [TextShadow] = []
  var backgroundOpacity: CGFloat = 0.3
  var cornerRadius: CGFloat = 8
}

struct TextShadow {
  let color: Color
  let radius: CGFloat
  let x: CGFloat
  let y: CGFloat
}

// MARK: - Curved Text Element Model
struct CurvedTextElement: Identifiable {
  let id = UUID()
  var text: String
  var path: [CGPoint]  // Los puntos que forman la línea curva
  var fontSize: CGFloat
  var fontWeight: Font.Weight
  var color: Color
  var scale: CGFloat = 1.0
  var offset: CGSize = .zero
  var customFontName: String? = nil  // Nombre de la fuente personalizada

  // Hacer mutable el struct completo
  mutating func updateText(_ newText: String) {
    self.text = newText
  }
}

// MARK: - Drawing State
enum DrawingMode {
  case none
  case drawing
  case finished
}

// MARK: - Path Utilities
struct PathUtilities {

  // Simplifica un path con muchos puntos para hacerlo más suave
  static func simplifyPath(_ points: [CGPoint], tolerance: CGFloat = 5.0) -> [CGPoint] {
    guard points.count > 2 else { return points }

    var simplified: [CGPoint] = [points[0]]
    var lastPoint = points[0]

    for i in 1..<points.count {
      let point = points[i]
      let distance = sqrt(pow(point.x - lastPoint.x, 2) + pow(point.y - lastPoint.y, 2))

      if distance > tolerance {
        simplified.append(point)
        lastPoint = point
      }
    }

    // Asegurar que el último punto esté incluido
    if simplified.last != points.last {
      simplified.append(points.last!)
    }

    return simplified
  }

  // Calcula la longitud total de un path
  static func pathLength(_ points: [CGPoint]) -> CGFloat {
    guard points.count > 1 else { return 0 }

    var length: CGFloat = 0
    for i in 0..<points.count - 1 {
      let dx = points[i + 1].x - points[i].x
      let dy = points[i + 1].y - points[i].y
      length += sqrt(dx * dx + dy * dy)
    }

    return length
  }

  // Obtiene un punto en el path a una distancia específica desde el inicio
  static func pointAtDistance(_ points: [CGPoint], distance: CGFloat) -> (
    point: CGPoint, angle: CGFloat
  )? {
    guard points.count > 1 else { return nil }

    var currentDistance: CGFloat = 0

    for i in 0..<points.count - 1 {
      let p1 = points[i]
      let p2 = points[i + 1]
      let dx = p2.x - p1.x
      let dy = p2.y - p1.y
      let segmentLength = sqrt(dx * dx + dy * dy)

      if currentDistance + segmentLength >= distance {
        let remainingDistance = distance - currentDistance
        let ratio = remainingDistance / segmentLength

        let point = CGPoint(
          x: p1.x + dx * ratio,
          y: p1.y + dy * ratio
        )

        let angle = atan2(dy, dx)

        return (point, angle)
      }

      currentDistance += segmentLength
    }

    // Si llegamos aquí, devolver el último punto
    if let last = points.last, points.count >= 2 {
      let secondLast = points[points.count - 2]
      let dx = last.x - secondLast.x
      let dy = last.y - secondLast.y
      let angle = atan2(dy, dx)
      return (last, angle)
    }

    return nil
  }

  // Convierte un array de puntos en un Path de SwiftUI
  static func createPath(from points: [CGPoint]) -> Path {
    var path = Path()
    guard points.count > 0 else { return path }

    path.move(to: points[0])

    if points.count == 2 {
      path.addLine(to: points[1])
    } else if points.count > 2 {
      // Usar curvas suaves (quadratic curves)
      for i in 1..<points.count {
        let current = points[i]

        if i < points.count - 1 {
          let next = points[i + 1]
          let mid = CGPoint(
            x: (current.x + next.x) / 2,
            y: (current.y + next.y) / 2
          )
          path.addQuadCurve(to: mid, control: current)
        } else {
          path.addLine(to: current)
        }
      }
    }

    return path
  }
}

// MARK: - Photo Filter Enum
enum PhotoFilter: CaseIterable {
  case none
  case sepia
  case vivid
  case gritty  // LUT Canon Gritty
  case kodak
  case lut2  // LUT personalizado 2
  case procedural80s  // Filtro procedural de los 80s

  var name: String {
    switch self {
    case .none: return "Original"
    case .sepia: return "Sepia"
    case .vivid: return "Vivid"
    case .gritty: return "Gritty"
    case .kodak: return "Kodak"
    case .lut2: return "LUT2"
    case .procedural80s: return "80s"
    }
  }

  var previewColor: Color {
    switch self {
    case .none: return .clear
    case .sepia: return .orange.opacity(0.3)
    case .vivid: return .blue.opacity(0.3)
    case .gritty: return .green.opacity(0.3)
    case .kodak: return .yellow.opacity(0.3)
    case .lut2: return .purple.opacity(0.3)
    case .procedural80s: return .pink.opacity(0.3)
    }
  }

  func apply(to image: UIImage) -> UIImage {
    guard self != .none else { return image }

    // Para filtros LUT, usar la función especializada
    switch self {
    case .gritty:
      return LUTFilter.applyLUT(to: image, lutFileName: "02_Canon LUTs_Gritty") ?? image
    case .kodak:
      return LUTFilter.applyLUT(to: image, lutFileName: "kodak") ?? image
    case .lut2:
      return LUTFilter.applyLUT(to: image, lutFileName: "lut2") ?? image
    case .procedural80s:
      print("🎬 PhotoFilter: Aplicando filtro procedural80s")
      return Procedural80sFilter().apply(to: image) ?? image
    default:
      break
    }

    // Para filtros Core Image normales
    guard let ciImage = CIImage(image: image) else { return image }
    let context = CIContext()

    var outputImage = ciImage

    switch self {
    case .none:
      break
    case .sepia:
      if let filter = CIFilter(name: "CISepiaTone") {
        filter.setValue(outputImage, forKey: kCIInputImageKey)
        filter.setValue(0.8, forKey: kCIInputIntensityKey)
        if let output = filter.outputImage {
          outputImage = output
        }
      }
    case .vivid:
      if let filter = CIFilter(name: "CIColorControls") {
        filter.setValue(outputImage, forKey: kCIInputImageKey)
        filter.setValue(1.5, forKey: kCIInputSaturationKey)
        filter.setValue(1.1, forKey: kCIInputContrastKey)
        if let output = filter.outputImage {
          outputImage = output
        }
      }
    case .gritty, .kodak, .lut2, .procedural80s:
      // Ya manejados arriba
      break
    }

    guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
      return image
    }

    // Preservar la orientación original de la imagen
    return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
  }
}

// MARK: - Sticker Models
struct StickerElement: Identifiable {
  let id = UUID()
  let imageName: String
  let imageURL: String?  // URL de la imagen (opcional)
  var position: CGPoint
  var scale: CGFloat
  var rotation: Double
  var zIndex: Int

  init(
    imageName: String, imageURL: String? = nil, position: CGPoint = CGPoint(x: 0.5, y: 0.5),
    scale: CGFloat = 1.0, rotation: Double = 0.0, zIndex: Int = 0
  ) {
    self.imageName = imageName
    self.imageURL = imageURL
    self.position = position
    self.scale = scale
    self.rotation = rotation
    self.zIndex = zIndex
  }
}

// MARK: - Sticker Manager
class StickerManager {
  static let shared = StickerManager()

  // 🔧 CONFIGURACIÓN: Cambia esta URL para apuntar a tu endpoint
  private let stickersEndpoint = "https://caffari.cl/api/taquilla"

  private init() {}

  func loadAvailableStickers() async -> [StickerInfo] {
    print("🌐 Cargando stickers desde: \(stickersEndpoint)")

    guard let url = URL(string: stickersEndpoint) else {
      print("❌ URL inválida: \(stickersEndpoint)")
      return []
    }

    do {
      let (data, response) = try await URLSession.shared.data(from: url)

      guard let httpResponse = response as? HTTPURLResponse,
        httpResponse.statusCode == 200
      else {
        print("❌ Error HTTP: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
        return []
      }

      // Parsear la respuesta JSON
      let stickersResponse = try JSONDecoder().decode(StickersResponse.self, from: data)
      print("✅ Stickers cargados exitosamente: \(stickersResponse.stickers.count)")

      return stickersResponse.stickers

    } catch {
      print("❌ Error cargando stickers: \(error.localizedDescription)")
      return []
    }
  }
}

// MARK: - Sticker Response Models
struct StickersResponse: Codable {
  let stickers: [StickerInfo]
}

struct StickerInfo: Codable {
  let name: String
  let url: String
  let thumbnail: String?
}

// MARK: - LUT Filter Helper
class LUTFilter {
  static func applyLUT(to image: UIImage, lutFileName: String) -> UIImage? {
    // Intentar encontrar el archivo LUT en diferentes ubicaciones
    var lutURL: URL?

    // Opción 1: Buscar en el bundle directamente con extensión .cube
    lutURL = Bundle.main.url(forResource: lutFileName, withExtension: "cube")

    // Opción 2: Buscar en el bundle directamente con extensión .CUBE
    if lutURL == nil {
      lutURL = Bundle.main.url(forResource: lutFileName, withExtension: "CUBE")
    }

    // Opción 3: Buscar en subdirectorio con extensión .cube
    if lutURL == nil {
      lutURL = Bundle.main.url(
        forResource: lutFileName, withExtension: "cube",
        subdirectory: "Resources/02_Canon LUTs_Gritty")
    }

    // Opción 4: Buscar recursivamente en el bundle
    if lutURL == nil {
      if let bundlePath = Bundle.main.resourcePath {
        let fileManager = FileManager.default
        if let enumerator = fileManager.enumerator(atPath: bundlePath) {
          for case let file as String in enumerator {
            if file.contains(lutFileName) && (file.hasSuffix(".cube") || file.hasSuffix(".CUBE")) {
              lutURL = URL(fileURLWithPath: bundlePath).appendingPathComponent(file)
              break
            }
          }
        }
      }
    }

    guard let url = lutURL,
      let lutData = try? String(contentsOf: url)
    else {
      print("❌ No se pudo cargar el archivo LUT: \(lutFileName)")
      print("📁 Bundle path: \(Bundle.main.resourcePath ?? "unknown")")
      return nil
    }

    print("✅ LUT encontrado en: \(url.path)")

    guard let cubeData = parseCubeLUT(lutData) else {
      print("❌ No se pudo parsear el archivo LUT")
      return nil
    }

    print("✅ LUT parseado: dimensión \(cubeData.dimension), \(cubeData.data.count) bytes de datos")

    guard let ciImage = CIImage(image: image) else { return image }

    // Crear el filtro ColorCube con los datos del LUT
    guard let filter = CIFilter(name: "CIColorCube") else { return image }

    filter.setValue(ciImage, forKey: kCIInputImageKey)
    filter.setValue(cubeData.dimension, forKey: "inputCubeDimension")
    filter.setValue(cubeData.data, forKey: "inputCubeData")

    guard let outputImage = filter.outputImage else { return image }

    let context = CIContext()
    guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
      return image
    }

    return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
  }

  private static func parseCubeLUT(_ lutString: String) -> (data: Data, dimension: Int)? {
    let lines = lutString.components(separatedBy: .newlines)
    var dimension = 0
    var lutData: [Float] = []

    for line in lines {
      let trimmed = line.trimmingCharacters(in: .whitespaces)

      // Ignorar comentarios y líneas vacías
      if trimmed.isEmpty || trimmed.hasPrefix("#") {
        continue
      }

      // Buscar el tamaño de la tabla LUT
      if trimmed.hasPrefix("LUT_3D_SIZE") {
        let components = trimmed.components(separatedBy: .whitespaces)
        if components.count >= 2, let size = Int(components[1]) {
          dimension = size
        }
        continue
      }

      // Parsear los valores RGB
      let values = trimmed.components(separatedBy: .whitespaces)
      if values.count >= 3 {
        if let r = Float(values[0]),
          let g = Float(values[1]),
          let b = Float(values[2])
        {
          // CIColorCube espera valores RGBA
          lutData.append(r)
          lutData.append(g)
          lutData.append(b)
          lutData.append(1.0)  // Alpha
        }
      }
    }

    guard dimension > 0 && !lutData.isEmpty else {
      print("❌ LUT vacío o inválido")
      return nil
    }

    // Verificar que tengamos el número correcto de valores
    let expectedCount = dimension * dimension * dimension * 4  // RGBA
    if lutData.count != expectedCount {
      print("⚠️ LUT tiene \(lutData.count) valores, se esperaban \(expectedCount)")
    }

    let data = Data(bytes: lutData, count: lutData.count * MemoryLayout<Float>.size)
    return (data, dimension)
  }
}

// MARK: - Procedural 80s Filter
class Procedural80sFilter {
  private let context = CIContext()

  func apply(to image: UIImage) -> UIImage? {
    print("🎬 Procedural80sFilter: Iniciando aplicación del filtro")
    guard let input = CIImage(image: image) else { 
      print("❌ Procedural80sFilter: No se pudo crear CIImage")
      return nil 
    }
    print("✅ Procedural80sFilter: CIImage creado exitosamente")

    // Preservar la orientación original de la imagen
    let originalOrientation = image.imageOrientation
    print("📐 Procedural80sFilter: Orientación original: \(originalOrientation.rawValue)")

    // 🎯 Parámetros fijos para efecto consistente de los 80s
    let bloomRadius: CGFloat = 5.0        // Glow suave y consistente
    let bloomIntensity: CGFloat = 0.5      // Intensidad moderada
    let saturation: CGFloat = 1.6          // Colores vibrantes pero naturales
    let contrast: CGFloat = 1.3            // Contraste mejorado
    let hueShift: CGFloat = 0.3            // Tono magenta sutil

    print("🎯 Procedural80sFilter: Parámetros fijos aplicados")
    print("   - Bloom Radius: \(bloomRadius)")
    print("   - Bloom Intensity: \(bloomIntensity)")
    print("   - Saturation: \(saturation)")
    print("   - Contrast: \(contrast)")
    print("   - Hue Shift: \(hueShift)")

    var outputImage = input

    // 🌟 1) Bloom neon
    if let bloom = CIFilter(name: "CIBloom") {
      bloom.setValue(outputImage, forKey: kCIInputImageKey)
      bloom.setValue(bloomRadius, forKey: kCIInputRadiusKey)
      bloom.setValue(bloomIntensity, forKey: kCIInputIntensityKey)
      if let bloomOutput = bloom.outputImage {
        outputImage = bloomOutput
        print("✅ Procedural80sFilter: Bloom aplicado")
      }
    } else {
      print("❌ Procedural80sFilter: CIFilter CIBloom no disponible")
    }

    // 🌈 2) Saturación y contraste vitaminados
    if let color = CIFilter(name: "CIColorControls") {
      color.setValue(outputImage, forKey: kCIInputImageKey)
      color.setValue(saturation, forKey: kCIInputSaturationKey)
      color.setValue(contrast, forKey: kCIInputContrastKey)
      if let colorOutput = color.outputImage {
        outputImage = colorOutput
        print("✅ Procedural80sFilter: Color controls aplicado")
      }
    } else {
      print("❌ Procedural80sFilter: CIFilter CIColorControls no disponible")
    }

    // 🎨 3) Tono magenta/cyan procedural
    if let hue = CIFilter(name: "CIHueAdjust") {
      hue.setValue(outputImage, forKey: kCIInputImageKey)
      hue.setValue(hueShift, forKey: kCIInputAngleKey)
      if let hueOutput = hue.outputImage {
        outputImage = hueOutput
        print("✅ Procedural80sFilter: Hue adjust aplicado")
      }
    } else {
      print("❌ Procedural80sFilter: CIFilter CIHueAdjust no disponible")
    }

    // Viñeta removida para efecto más sutil

    guard let cgImg = context.createCGImage(outputImage, from: outputImage.extent) else { 
      print("❌ Procedural80sFilter: No se pudo crear CGImage")
      return nil 
    }
    print("✅ Procedural80sFilter: CGImage creado exitosamente")

    // Crear UIImage preservando la orientación original
    let resultImage = UIImage(cgImage: cgImg, scale: image.scale, orientation: originalOrientation)
    print("🎉 Procedural80sFilter: Filtro aplicado exitosamente con orientación preservada")
    return resultImage
  }
}

// MARK: - Photo Effects
enum PhotoEffect: String, CaseIterable {
    case skinSmoothing = "skin_smoothing"
    
    var displayName: String {
        switch self {
        case .skinSmoothing:
            return "Maquillaje"
        }
    }
    
    var iconName: String {
        switch self {
        case .skinSmoothing:
            return "face.smiling.fill"
        }
    }
}

// MARK: - Advanced Skin Smoothing Effect
import CoreImage
import Vision
import UIKit
import Accelerate

func smoothSkin(image: UIImage, radius: Float = 8.0) -> UIImage? {
    // Preservar la orientación original
    let originalOrientation = image.imageOrientation
    
    guard let ciImage = CIImage(image: image) else {
        print("❌ smoothSkin: Error creando CIImage")
        return nil
    }
    
    let context = CIContext()
    
    // Paso 1: Detectar rostros usando Vision
    let faceDetectionRequest = VNDetectFaceLandmarksRequest { request, error in
        if let error = error {
            print("❌ smoothSkin: Error en detección facial: \(error)")
        }
    }
    
    let requestHandler = VNImageRequestHandler(ciImage: ciImage, options: [:])
    
    do {
        try requestHandler.perform([faceDetectionRequest])
    } catch {
        print("❌ smoothSkin: Error ejecutando detección facial: \(error)")
        // Fallback: aplicar suavizado avanzado si falla la detección
        return applyAdvancedSmoothing(to: ciImage, radius: radius, context: context, originalOrientation: originalOrientation)
    }
    
    guard let faceObservations = faceDetectionRequest.results as? [VNFaceObservation],
          !faceObservations.isEmpty else {
        print("⚠️ smoothSkin: No se detectaron rostros, aplicando suavizado avanzado")
        return applyAdvancedSmoothing(to: ciImage, radius: radius, context: context, originalOrientation: originalOrientation)
    }
    
    print("✅ smoothSkin: Detectados \(faceObservations.count) rostro(s)")
    
    // Paso 2: Crear máscara de piel avanzada con gradientes suaves
    guard let skinMask = createAdvancedSkinMask(from: faceObservations, imageSize: ciImage.extent.size) else {
        print("❌ smoothSkin: Error creando máscara avanzada de piel")
        return applyAdvancedSmoothing(to: ciImage, radius: radius, context: context, originalOrientation: originalOrientation)
    }
    
    // Paso 3: Aplicar suavizado profesional con múltiples técnicas
    guard let smoothedImage = applyProfessionalSkinSmoothing(to: ciImage, mask: skinMask, radius: radius, context: context, originalOrientation: originalOrientation) else {
        print("❌ smoothSkin: Error aplicando suavizado profesional")
        return applyAdvancedSmoothing(to: ciImage, radius: radius, context: context, originalOrientation: originalOrientation)
    }
    
    print("✅ smoothSkin: Efecto profesional avanzado aplicado exitosamente")
    return smoothedImage
}

// Función auxiliar para suavizado avanzado (fallback)
private func applyAdvancedSmoothing(to ciImage: CIImage, radius: Float, context: CIContext, originalOrientation: UIImage.Orientation) -> UIImage? {
    // Usar bilateral filtering para mejor calidad
    guard let bilateralFilter = CIFilter(name: "CIGaussianBlur") else { return nil }
    
    // Aplicar múltiples pasadas con diferentes radios para mejor resultado
    let radii: [Float] = [radius * 0.3, radius * 0.6, radius]
    var currentImage = ciImage
    
    for currentRadius in radii {
        bilateralFilter.setValue(currentImage, forKey: kCIInputImageKey)
        bilateralFilter.setValue(currentRadius, forKey: kCIInputRadiusKey)
        
        guard let outputImage = bilateralFilter.outputImage else { continue }
        currentImage = outputImage
    }
    
    guard let cgImage = context.createCGImage(currentImage, from: ciImage.extent) else { return nil }
    return UIImage(cgImage: cgImage, scale: 1.0, orientation: originalOrientation)
}

// Crear máscara de piel avanzada con gradientes suaves
private func createAdvancedSkinMask(from faceObservations: [VNFaceObservation], imageSize: CGSize) -> CIImage? {
    let maskSize = imageSize
    let colorSpace = CGColorSpaceCreateDeviceGray()
    
    guard let context = CGContext(data: nil,
                                width: Int(maskSize.width),
                                height: Int(maskSize.height),
                                bitsPerComponent: 8,
                                bytesPerRow: Int(maskSize.width),
                                space: colorSpace,
                                bitmapInfo: CGImageAlphaInfo.none.rawValue) else {
        return nil
    }
    
    // Rellenar con blanco (áreas a suavizar)
    context.setFillColor(CGColor(gray: 1.0, alpha: 1.0))
    context.fill(CGRect(origin: .zero, size: maskSize))
    
    // Crear gradientes suaves alrededor de las características faciales
    context.setFillColor(CGColor(gray: 0.0, alpha: 1.0))
    
    for faceObservation in faceObservations {
        let faceRect = VNImageRectForNormalizedRect(faceObservation.boundingBox, 
                                                  Int(maskSize.width), 
                                                  Int(maskSize.height))
        
        // Excluir ojos con gradiente suave
        if let leftEye = faceObservation.landmarks?.leftEye {
            drawGradientLandmarkRegion(leftEye, in: context, imageSize: maskSize, faceRect: faceRect, gradientRadius: 15)
        }
        if let rightEye = faceObservation.landmarks?.rightEye {
            drawGradientLandmarkRegion(rightEye, in: context, imageSize: maskSize, faceRect: faceRect, gradientRadius: 15)
        }
        
        // Excluir cejas con gradiente suave
        if let leftEyebrow = faceObservation.landmarks?.leftEyebrow {
            drawGradientLandmarkRegion(leftEyebrow, in: context, imageSize: maskSize, faceRect: faceRect, gradientRadius: 10)
        }
        if let rightEyebrow = faceObservation.landmarks?.rightEyebrow {
            drawGradientLandmarkRegion(rightEyebrow, in: context, imageSize: maskSize, faceRect: faceRect, gradientRadius: 10)
        }
        
        // Excluir labios con gradiente suave
        if let outerLips = faceObservation.landmarks?.outerLips {
            drawGradientLandmarkRegion(outerLips, in: context, imageSize: maskSize, faceRect: faceRect, gradientRadius: 12)
        }
        if let innerLips = faceObservation.landmarks?.innerLips {
            drawGradientLandmarkRegion(innerLips, in: context, imageSize: maskSize, faceRect: faceRect, gradientRadius: 8)
        }
        
        // Excluir nariz con gradiente suave
        if let nose = faceObservation.landmarks?.nose {
            drawGradientLandmarkRegion(nose, in: context, imageSize: maskSize, faceRect: faceRect, gradientRadius: 8)
        }
    }
    
    guard let cgImage = context.makeImage() else { return nil }
    return CIImage(cgImage: cgImage)
}

// Dibujar región de landmark con gradiente suave
private func drawGradientLandmarkRegion(_ landmark: VNFaceLandmarkRegion2D, 
                                     in context: CGContext, 
                                     imageSize: CGSize, 
                                     faceRect: CGRect,
                                     gradientRadius: CGFloat) {
    let points = landmark.normalizedPoints.map { point in
        CGPoint(
            x: faceRect.origin.x + point.x * faceRect.width,
            y: faceRect.origin.y + point.y * faceRect.height
        )
    }
    
    guard !points.isEmpty else { return }
    
    // Crear gradiente radial alrededor de cada punto
    for point in points {
        let gradientRect = CGRect(
            x: point.x - gradientRadius,
            y: point.y - gradientRadius,
            width: gradientRadius * 2,
            height: gradientRadius * 2
        )
        
        // Crear gradiente circular
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceGray(),
                                colors: [CGColor(gray: 0.0, alpha: 1.0), CGColor(gray: 0.0, alpha: 0.0)] as CFArray,
                                locations: [0.0, 1.0])
        
        if let gradient = gradient {
            context.saveGState()
            context.addEllipse(in: gradientRect)
            context.clip()
            context.drawRadialGradient(gradient,
                                     startCenter: point,
                                     startRadius: 0,
                                     endCenter: point,
                                     endRadius: gradientRadius,
                                     options: [])
            context.restoreGState()
        }
    }
}

// Aplicar suavizado profesional usando múltiples técnicas
private func applyProfessionalSkinSmoothing(to ciImage: CIImage, 
                                           mask: CIImage, 
                                           radius: Float, 
                                           context: CIContext,
                                           originalOrientation: UIImage.Orientation) -> UIImage? {
    
    // Paso 1: Aplicar bilateral filtering (edge-preserving)
    guard let bilateralFilter = CIFilter(name: "CIGaussianBlur") else { return nil }
    bilateralFilter.setValue(ciImage, forKey: kCIInputImageKey)
    bilateralFilter.setValue(radius * 0.7, forKey: kCIInputRadiusKey)
    
    guard let bilateralImage = bilateralFilter.outputImage else { return nil }
    
    // Paso 2: Aplicar suavizado adicional con radio más pequeño
    guard let detailFilter = CIFilter(name: "CIGaussianBlur") else { return nil }
    detailFilter.setValue(bilateralImage, forKey: kCIInputImageKey)
    detailFilter.setValue(radius * 0.3, forKey: kCIInputRadiusKey)
    
    guard let detailImage = detailFilter.outputImage else { return nil }
    
    // Paso 3: Mezclar con máscara suavizada
    guard let maskBlurFilter = CIFilter(name: "CIGaussianBlur") else { return nil }
    maskBlurFilter.setValue(mask, forKey: kCIInputImageKey)
    maskBlurFilter.setValue(5.0, forKey: kCIInputRadiusKey)
    
    guard let smoothMask = maskBlurFilter.outputImage else { return nil }
    
    // Paso 4: Mezclar imagen original con suavizada usando la máscara suavizada
    guard let blendFilter = CIFilter(name: "CIBlendWithMask") else { return nil }
    blendFilter.setValue(ciImage, forKey: kCIInputImageKey)           // Imagen original
    blendFilter.setValue(detailImage, forKey: kCIInputBackgroundImageKey) // Imagen suavizada
    blendFilter.setValue(smoothMask, forKey: kCIInputMaskImageKey)     // Máscara suavizada
    
    guard let outputImage = blendFilter.outputImage,
          let cgImage = context.createCGImage(outputImage, from: ciImage.extent) else { return nil }
    
    return UIImage(cgImage: cgImage, scale: 1.0, orientation: originalOrientation)
}
