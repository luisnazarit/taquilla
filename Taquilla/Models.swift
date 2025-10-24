import SwiftUI
import CoreImage

// MARK: - Text Element Model
struct TextElement: Identifiable {
    let id = UUID()
    var text: String
    var position: CGPoint
    var fontSize: CGFloat
    var fontWeight: Font.Weight
    var color: Color
    var scale: CGFloat = 1.0
}

// MARK: - Curved Text Element Model
struct CurvedTextElement: Identifiable {
    let id = UUID()
    var text: String
    var path: [CGPoint] // Los puntos que forman la línea curva
    var fontSize: CGFloat
    var fontWeight: Font.Weight
    var color: Color
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
    static func pointAtDistance(_ points: [CGPoint], distance: CGFloat) -> (point: CGPoint, angle: CGFloat)? {
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
    case vintage
    case blackAndWhite
    case sepia
    case vivid
    case cool
    case warm
    case dramatic
    
    var name: String {
        switch self {
        case .none: return "Original"
        case .vintage: return "Vintage"
        case .blackAndWhite: return "B&W"
        case .sepia: return "Sepia"
        case .vivid: return "Vivid"
        case .cool: return "Cool"
        case .warm: return "Warm"
        case .dramatic: return "Dramatic"
        }
    }
    
    var previewColor: Color {
        switch self {
        case .none: return .clear
        case .vintage: return .brown.opacity(0.3)
        case .blackAndWhite: return .gray.opacity(0.5)
        case .sepia: return .orange.opacity(0.3)
        case .vivid: return .blue.opacity(0.3)
        case .cool: return .cyan.opacity(0.3)
        case .warm: return .red.opacity(0.3)
        case .dramatic: return .purple.opacity(0.3)
        }
    }
    
    func apply(to image: UIImage) -> UIImage {
        guard self != .none else { return image }
        
        guard let ciImage = CIImage(image: image) else { return image }
        let context = CIContext()
        
        var outputImage = ciImage
        
        switch self {
        case .none:
            break
        case .vintage:
            // Filtro vintage con saturación reducida y contraste aumentado
            if let filter = CIFilter(name: "CIColorControls") {
                filter.setValue(outputImage, forKey: kCIInputImageKey)
                filter.setValue(0.7, forKey: kCIInputSaturationKey)
                filter.setValue(1.2, forKey: kCIInputContrastKey)
                filter.setValue(0.9, forKey: kCIInputBrightnessKey)
                if let output = filter.outputImage {
                    outputImage = output
                }
            }
        case .blackAndWhite:
            if let filter = CIFilter(name: "CIColorMonochrome") {
                filter.setValue(outputImage, forKey: kCIInputImageKey)
                filter.setValue(CIColor.white, forKey: kCIInputColorKey)
                filter.setValue(1.0, forKey: kCIInputIntensityKey)
                if let output = filter.outputImage {
                    outputImage = output
                }
            }
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
        case .cool:
            if let filter = CIFilter(name: "CITemperatureAndTint") {
                filter.setValue(outputImage, forKey: kCIInputImageKey)
                filter.setValue(CIVector(x: 6500, y: 0), forKey: "inputNeutral")
                filter.setValue(CIVector(x: 6000, y: -100), forKey: "inputTargetNeutral")
                if let output = filter.outputImage {
                    outputImage = output
                }
            }
        case .warm:
            if let filter = CIFilter(name: "CITemperatureAndTint") {
                filter.setValue(outputImage, forKey: kCIInputImageKey)
                filter.setValue(CIVector(x: 6500, y: 0), forKey: "inputNeutral")
                filter.setValue(CIVector(x: 7000, y: 100), forKey: "inputTargetNeutral")
                if let output = filter.outputImage {
                    outputImage = output
                }
            }
        case .dramatic:
            if let filter = CIFilter(name: "CIColorControls") {
                filter.setValue(outputImage, forKey: kCIInputImageKey)
                filter.setValue(1.3, forKey: kCIInputSaturationKey)
                filter.setValue(1.4, forKey: kCIInputContrastKey)
                filter.setValue(0.8, forKey: kCIInputBrightnessKey)
                if let output = filter.outputImage {
                    outputImage = output
                }
            }
        }
        
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return image
        }
        
        // Preservar la orientación original de la imagen
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
}
