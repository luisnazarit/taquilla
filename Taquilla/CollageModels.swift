import Foundation
import SwiftUI

// MARK: - Collage Template
struct CollageTemplate: Identifiable {
    let id = UUID()
    let name: String
    let photoCount: Int
    let layout: CollageLayout
    let frames: [CollageFrame]
}

// MARK: - Collage Frame
struct CollageFrame: Identifiable {
    let id = UUID()
    let x: CGFloat  // Porcentaje (0-1)
    let y: CGFloat  // Porcentaje (0-1)
    let width: CGFloat  // Porcentaje (0-1)
    let height: CGFloat  // Porcentaje (0-1)
}

// MARK: - Collage Layout Type
enum CollageLayout {
    case twoPhotos
    case threePhotos
    case fourPhotos
    case fivePhotos
    case sixPhotos
}

// MARK: - Collage Templates Provider
struct CollageTemplates {
    
    // MARK: - 2 Photos Templates
    static let twoPhotosTemplates: [CollageTemplate] = [
        // Horizontal Split (50/50)
        CollageTemplate(
            name: "2 Horizontal",
            photoCount: 2,
            layout: .twoPhotos,
            frames: [
                CollageFrame(x: 0, y: 0, width: 0.5, height: 1.0),
                CollageFrame(x: 0.5, y: 0, width: 0.5, height: 1.0)
            ]
        ),
        // Vertical Split (50/50)
        CollageTemplate(
            name: "2 Vertical",
            photoCount: 2,
            layout: .twoPhotos,
            frames: [
                CollageFrame(x: 0, y: 0, width: 1.0, height: 0.5),
                CollageFrame(x: 0, y: 0.5, width: 1.0, height: 0.5)
            ]
        ),
        // 70/30 Vertical
        CollageTemplate(
            name: "2 Asimétrico V",
            photoCount: 2,
            layout: .twoPhotos,
            frames: [
                CollageFrame(x: 0, y: 0, width: 1.0, height: 0.7),
                CollageFrame(x: 0, y: 0.7, width: 1.0, height: 0.3)
            ]
        ),
        // 70/30 Horizontal
        CollageTemplate(
            name: "2 Asimétrico H",
            photoCount: 2,
            layout: .twoPhotos,
            frames: [
                CollageFrame(x: 0, y: 0, width: 0.7, height: 1.0),
                CollageFrame(x: 0.7, y: 0, width: 0.3, height: 1.0)
            ]
        )
    ]
    
    // MARK: - 3 Photos Templates
    static let threePhotosTemplates: [CollageTemplate] = [
        // Top Large, Bottom 2 Small
        CollageTemplate(
            name: "3 Top Grande",
            photoCount: 3,
            layout: .threePhotos,
            frames: [
                CollageFrame(x: 0, y: 0, width: 1.0, height: 0.6),
                CollageFrame(x: 0, y: 0.6, width: 0.5, height: 0.4),
                CollageFrame(x: 0.5, y: 0.6, width: 0.5, height: 0.4)
            ]
        ),
        // Left Large, Right 2 Small
        CollageTemplate(
            name: "3 Izquierda Grande",
            photoCount: 3,
            layout: .threePhotos,
            frames: [
                CollageFrame(x: 0, y: 0, width: 0.6, height: 1.0),
                CollageFrame(x: 0.6, y: 0, width: 0.4, height: 0.5),
                CollageFrame(x: 0.6, y: 0.5, width: 0.4, height: 0.5)
            ]
        ),
        // 3 Horizontal
        CollageTemplate(
            name: "3 Horizontal",
            photoCount: 3,
            layout: .threePhotos,
            frames: [
                CollageFrame(x: 0, y: 0, width: 0.333, height: 1.0),
                CollageFrame(x: 0.333, y: 0, width: 0.334, height: 1.0),
                CollageFrame(x: 0.667, y: 0, width: 0.333, height: 1.0)
            ]
        ),
        // 3 Vertical
        CollageTemplate(
            name: "3 Vertical",
            photoCount: 3,
            layout: .threePhotos,
            frames: [
                CollageFrame(x: 0, y: 0, width: 1.0, height: 0.333),
                CollageFrame(x: 0, y: 0.333, width: 1.0, height: 0.334),
                CollageFrame(x: 0, y: 0.667, width: 1.0, height: 0.333)
            ]
        )
    ]
    
    // MARK: - 4 Photos Templates
    static let fourPhotosTemplates: [CollageTemplate] = [
        // Grid 2x2
        CollageTemplate(
            name: "4 Cuadrado",
            photoCount: 4,
            layout: .fourPhotos,
            frames: [
                CollageFrame(x: 0, y: 0, width: 0.5, height: 0.5),
                CollageFrame(x: 0.5, y: 0, width: 0.5, height: 0.5),
                CollageFrame(x: 0, y: 0.5, width: 0.5, height: 0.5),
                CollageFrame(x: 0.5, y: 0.5, width: 0.5, height: 0.5)
            ]
        ),
        // Top Large, Bottom 3 Small
        CollageTemplate(
            name: "4 Top Grande",
            photoCount: 4,
            layout: .fourPhotos,
            frames: [
                CollageFrame(x: 0, y: 0, width: 1.0, height: 0.5),
                CollageFrame(x: 0, y: 0.5, width: 0.333, height: 0.5),
                CollageFrame(x: 0.333, y: 0.5, width: 0.334, height: 0.5),
                CollageFrame(x: 0.667, y: 0.5, width: 0.333, height: 0.5)
            ]
        ),
        // Left Large, Right 3 Small
        CollageTemplate(
            name: "4 Izquierda Grande",
            photoCount: 4,
            layout: .fourPhotos,
            frames: [
                CollageFrame(x: 0, y: 0, width: 0.5, height: 1.0),
                CollageFrame(x: 0.5, y: 0, width: 0.5, height: 0.333),
                CollageFrame(x: 0.5, y: 0.333, width: 0.5, height: 0.334),
                CollageFrame(x: 0.5, y: 0.667, width: 0.5, height: 0.333)
            ]
        ),
        // 4 Horizontal
        CollageTemplate(
            name: "4 Horizontal",
            photoCount: 4,
            layout: .fourPhotos,
            frames: [
                CollageFrame(x: 0, y: 0, width: 0.25, height: 1.0),
                CollageFrame(x: 0.25, y: 0, width: 0.25, height: 1.0),
                CollageFrame(x: 0.5, y: 0, width: 0.25, height: 1.0),
                CollageFrame(x: 0.75, y: 0, width: 0.25, height: 1.0)
            ]
        )
    ]
    
    // MARK: - 5 Photos Templates
    static let fivePhotosTemplates: [CollageTemplate] = [
        // Top 2, Middle 1 Large, Bottom 2
        CollageTemplate(
            name: "5 Centro Grande",
            photoCount: 5,
            layout: .fivePhotos,
            frames: [
                CollageFrame(x: 0, y: 0, width: 0.5, height: 0.3),
                CollageFrame(x: 0.5, y: 0, width: 0.5, height: 0.3),
                CollageFrame(x: 0, y: 0.3, width: 1.0, height: 0.4),
                CollageFrame(x: 0, y: 0.7, width: 0.5, height: 0.3),
                CollageFrame(x: 0.5, y: 0.7, width: 0.5, height: 0.3)
            ]
        ),
        // Left 1 Large, Right 4 Small
        CollageTemplate(
            name: "5 Izquierda Grande",
            photoCount: 5,
            layout: .fivePhotos,
            frames: [
                CollageFrame(x: 0, y: 0, width: 0.6, height: 1.0),
                CollageFrame(x: 0.6, y: 0, width: 0.4, height: 0.25),
                CollageFrame(x: 0.6, y: 0.25, width: 0.4, height: 0.25),
                CollageFrame(x: 0.6, y: 0.5, width: 0.4, height: 0.25),
                CollageFrame(x: 0.6, y: 0.75, width: 0.4, height: 0.25)
            ]
        ),
        // Top 3, Bottom 2
        CollageTemplate(
            name: "5 Mix",
            photoCount: 5,
            layout: .fivePhotos,
            frames: [
                CollageFrame(x: 0, y: 0, width: 0.333, height: 0.5),
                CollageFrame(x: 0.333, y: 0, width: 0.334, height: 0.5),
                CollageFrame(x: 0.667, y: 0, width: 0.333, height: 0.5),
                CollageFrame(x: 0, y: 0.5, width: 0.5, height: 0.5),
                CollageFrame(x: 0.5, y: 0.5, width: 0.5, height: 0.5)
            ]
        )
    ]
    
    // MARK: - 6 Photos Templates
    static let sixPhotosTemplates: [CollageTemplate] = [
        // Grid 3x2
        CollageTemplate(
            name: "6 Cuadrícula 3x2",
            photoCount: 6,
            layout: .sixPhotos,
            frames: [
                CollageFrame(x: 0, y: 0, width: 0.333, height: 0.5),
                CollageFrame(x: 0.333, y: 0, width: 0.334, height: 0.5),
                CollageFrame(x: 0.667, y: 0, width: 0.333, height: 0.5),
                CollageFrame(x: 0, y: 0.5, width: 0.333, height: 0.5),
                CollageFrame(x: 0.333, y: 0.5, width: 0.334, height: 0.5),
                CollageFrame(x: 0.667, y: 0.5, width: 0.333, height: 0.5)
            ]
        ),
        // Grid 2x3
        CollageTemplate(
            name: "6 Cuadrícula 2x3",
            photoCount: 6,
            layout: .sixPhotos,
            frames: [
                CollageFrame(x: 0, y: 0, width: 0.5, height: 0.333),
                CollageFrame(x: 0.5, y: 0, width: 0.5, height: 0.333),
                CollageFrame(x: 0, y: 0.333, width: 0.5, height: 0.334),
                CollageFrame(x: 0.5, y: 0.333, width: 0.5, height: 0.334),
                CollageFrame(x: 0, y: 0.667, width: 0.5, height: 0.333),
                CollageFrame(x: 0.5, y: 0.667, width: 0.5, height: 0.333)
            ]
        ),
        // Top 1 Large, Bottom 5 Small
        CollageTemplate(
            name: "6 Top Grande",
            photoCount: 6,
            layout: .sixPhotos,
            frames: [
                CollageFrame(x: 0, y: 0, width: 1.0, height: 0.5),
                CollageFrame(x: 0, y: 0.5, width: 0.2, height: 0.5),
                CollageFrame(x: 0.2, y: 0.5, width: 0.2, height: 0.5),
                CollageFrame(x: 0.4, y: 0.5, width: 0.2, height: 0.5),
                CollageFrame(x: 0.6, y: 0.5, width: 0.2, height: 0.5),
                CollageFrame(x: 0.8, y: 0.5, width: 0.2, height: 0.5)
            ]
        )
    ]
    
    // MARK: - All Templates
    static func allTemplates() -> [[CollageTemplate]] {
        return [
            twoPhotosTemplates,
            threePhotosTemplates,
            fourPhotosTemplates,
            fivePhotosTemplates,
            sixPhotosTemplates
        ]
    }
    
    static func templates(for photoCount: Int) -> [CollageTemplate] {
        switch photoCount {
        case 2: return twoPhotosTemplates
        case 3: return threePhotosTemplates
        case 4: return fourPhotosTemplates
        case 5: return fivePhotosTemplates
        case 6: return sixPhotosTemplates
        default: return []
        }
    }
}

