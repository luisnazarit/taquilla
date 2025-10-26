import Photos
import SwiftUI

struct GalleryView: View {
    @EnvironmentObject var photoManager: PhotoManager
    @State private var selectedPhoto: SavedPhoto?

    var body: some View {
        NavigationView {
            ZStack {
                // Fondo de la aplicación
                Image("Background")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
                
                if photoManager.savedPhotos.isEmpty {
                    emptyStateView
                } else {
                    galleryGridView
                        .padding(.top, 20)
                }
            }
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                // Validar y limpiar fotos borradas al abrir la galería
                photoManager.validateAndCleanupPhotos()
            }
        }
        .fullScreenCover(item: $selectedPhoto) { photo in
            FullScreenPhotoView(photo: photo, selectedPhoto: $selectedPhoto)
                .environmentObject(photoManager)
        }
    }

    // Vista cuando no hay fotos
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 80))
                .foregroundColor(.gray.opacity(0.5))

            Text("Sin fotos guardadas")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Las fotos que guardes desde el editor\naparecerán aquí")
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }

    // Vista de cuadrícula de fotos
    private var galleryGridView: some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 2),
                    GridItem(.flexible(), spacing: 2),
                    GridItem(.flexible(), spacing: 2),
                ], spacing: 2
            ) {
                ForEach(photoManager.savedPhotos) { photo in
                    GalleryThumbnailView(photo: photo)
                        .aspectRatio(1, contentMode: .fill)
                        .onTapGesture {
                            selectedPhoto = photo
                        }
                }
            }
            .padding(.horizontal, 60)
            .padding(.vertical, 10)
        }
        .padding(.horizontal, 0) // Asegurar que el ScrollView no tenga padding adicional
    }
}

// MARK: - Thumbnail View
struct GalleryThumbnailView: View {
    let photo: SavedPhoto
    @EnvironmentObject var photoManager: PhotoManager
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipped()
            } else {
                Color.gray.opacity(0.2)
                ProgressView()
            }
        }
        .onAppear {
            loadThumbnail()
        }
    }

    private func loadThumbnail() {
        let size = CGSize(width: 300, height: 300)
        photoManager.loadImage(for: photo, targetSize: size) { loadedImage in
            image = loadedImage
        }
    }
}

// MARK: - Full Screen Photo View
struct FullScreenPhotoView: View {
    let photo: SavedPhoto
    @Binding var selectedPhoto: SavedPhoto?
    @EnvironmentObject var photoManager: PhotoManager
    @State private var image: UIImage?
    @State private var showingShareSheet = false
    @State private var showingDeleteAlert = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let image = image {
                VStack {
                    // Header
                    HStack {
                        Button(action: { selectedPhoto = nil }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                        }

                        Spacer()

                        HStack(spacing: 20) {
                            Button(action: { showingShareSheet = true }) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }

                            Button(action: { showingDeleteAlert = true }) {
                                Image(systemName: "trash")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding()

                    Spacer()

                    // Imagen
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)

                    Spacer()

                    // Info de fecha
                    Text(formatDate(photo.timestamp))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.bottom)
                }
            } else {
                ProgressView()
                    .tint(.white)
            }
        }
        .onAppear {
            loadFullImage()
        }
        .sheet(isPresented: $showingShareSheet) {
            if let image = image {
                ShareSheet(items: [image])
            }
        }
        .alert("Eliminar foto", isPresented: $showingDeleteAlert) {
            Button("Cancelar", role: .cancel) {}
            Button("Eliminar", role: .destructive) {
                photoManager.deletePhoto(photo)
                selectedPhoto = nil
            }
        } message: {
            Text(
                "¿Estás seguro de que quieres eliminar esta foto? Esta acción no se puede deshacer."
            )
        }
    }

    private func loadFullImage() {
        photoManager.loadImage(for: photo) { loadedImage in
            image = loadedImage
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    GalleryView()
        .environmentObject(PhotoManager())
}
