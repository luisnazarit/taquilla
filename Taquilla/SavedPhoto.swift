import Foundation
import SwiftUI
import Photos

// MARK: - Saved Photo Model
struct SavedPhoto: Identifiable, Codable {
    let id: UUID
    let assetIdentifier: String  // PHAsset localIdentifier
    let timestamp: Date
    
    init(id: UUID = UUID(), assetIdentifier: String, timestamp: Date = Date()) {
        self.id = id
        self.assetIdentifier = assetIdentifier
        self.timestamp = timestamp
    }
}

// MARK: - Photo Manager
class PhotoManager: ObservableObject {
    @Published var savedPhotos: [SavedPhoto] = []
    
    private let userDefaults = UserDefaults.standard
    private let photosKey = "TaquillaSavedPhotos"
    
    init() {
        loadPhotos()
    }
    
    // Guardar foto y registrarla
    func savePhoto(_ image: UIImage, completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            
            var localIdentifier: String?
            
            PHPhotoLibrary.shared().performChanges({
                let request = PHAssetCreationRequest.creationRequestForAsset(from: image)
                localIdentifier = request.placeholderForCreatedAsset?.localIdentifier
            }) { success, error in
                if success, let identifier = localIdentifier {
                    let photo = SavedPhoto(assetIdentifier: identifier)
                    DispatchQueue.main.async {
                        self.savedPhotos.insert(photo, at: 0) // Agregar al inicio
                        self.savePhotos()
                        completion(true)
                    }
                } else {
                    print("❌ Error guardando foto: \(error?.localizedDescription ?? "unknown")")
                    DispatchQueue.main.async {
                        completion(false)
                    }
                }
            }
        }
    }
    
    // Cargar fotos guardadas
    private func loadPhotos() {
        if let data = userDefaults.data(forKey: photosKey),
           let photos = try? JSONDecoder().decode([SavedPhoto].self, from: data) {
            savedPhotos = photos
            print("✅ Cargadas \(photos.count) fotos guardadas")
        }
    }
    
    // Persistir fotos
    private func savePhotos() {
        if let data = try? JSONEncoder().encode(savedPhotos) {
            userDefaults.set(data, forKey: photosKey)
            print("💾 Guardadas \(savedPhotos.count) referencias de fotos")
        }
    }
    
    // Eliminar foto
    func deletePhoto(_ photo: SavedPhoto) {
        // Eliminar del array
        savedPhotos.removeAll { $0.id == photo.id }
        savePhotos()
        
        // Opcional: eliminar de la librería de fotos
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [photo.assetIdentifier], options: nil)
        if let asset = fetchResult.firstObject {
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.deleteAssets([asset] as NSArray)
            }) { success, error in
                if success {
                    print("✅ Foto eliminada de la librería")
                } else {
                    print("❌ Error eliminando foto: \(error?.localizedDescription ?? "unknown")")
                }
            }
        }
    }
    
    // Cargar UIImage desde PHAsset
    func loadImage(for photo: SavedPhoto, targetSize: CGSize = PHImageManagerMaximumSize, completion: @escaping (UIImage?) -> Void) {
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [photo.assetIdentifier], options: nil)
        
        guard let asset = fetchResult.firstObject else {
            completion(nil)
            return
        }
        
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false
        
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: options
        ) { image, _ in
            DispatchQueue.main.async {
                completion(image)
            }
        }
    }
}

