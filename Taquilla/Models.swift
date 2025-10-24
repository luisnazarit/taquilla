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
