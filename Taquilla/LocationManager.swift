import Foundation
import CoreLocation
import MapKit

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var lastLocation: CLLocation?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = manager.authorizationStatus
    }
    
    func requestLocation() {
        // Pedir permiso si aún no se ha pedido
        if authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
        
        // Obtener ubicación
        manager.requestLocation()
    }
    
    // CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastLocation = locations.first
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Error obteniendo ubicación: \(error.localizedDescription)")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }
    
    // Obtener información detallada de la ubicación
    func getLocationDetails(completion: @escaping (Result<(neighborhood: String, city: String, country: String), Error>) -> Void) {
        guard let location = lastLocation else {
            completion(.failure(NSError(domain: "LocationManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No hay ubicación disponible"])))
            return
        }
        
        // Reverse geocoding para obtener la dirección
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let placemark = placemarks?.first else {
                completion(.failure(NSError(domain: "LocationManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "No se encontró información del lugar"])))
                return
            }
            
            // Buscar lugares de interés cercanos (POI) para obtener el barrio
            self.searchNearbyPlaces(at: location) { neighborhood in
                // Prioridad para mostrar el título:
                // 1. Barrio encontrado por búsqueda
                // 2. SubLocality (ej: "Lastarria", "Providencia")
                // 3. Calle + número (ej: "Av. Libertador Bernardo O'Higgins 651")
                // 4. Solo calle (ej: "Av. Libertador Bernardo O'Higgins")
                // 5. Locality como último recurso
                
                var finalNeighborhood: String
                
                if let foundNeighborhood = neighborhood {
                    finalNeighborhood = foundNeighborhood
                } else if let subLocality = placemark.subLocality {
                    finalNeighborhood = subLocality
                } else if let thoroughfare = placemark.thoroughfare {
                    // thoroughfare = nombre de la calle
                    if let subThoroughfare = placemark.subThoroughfare {
                        // subThoroughfare = número de la calle
                        finalNeighborhood = "\(thoroughfare) \(subThoroughfare)"
                    } else {
                        finalNeighborhood = thoroughfare
                    }
                } else if let locality = placemark.locality {
                    finalNeighborhood = locality
                } else {
                    finalNeighborhood = "Ubicación Actual"
                }
                
                let city = placemark.locality ?? placemark.administrativeArea ?? "Ciudad"
                let country = placemark.country ?? "País"
                
                print("📍 Ubicación detectada:")
                print("   Título: \(finalNeighborhood)")
                print("   Ciudad: \(city)")
                print("   País: \(country)")
                print("   ---")
                print("   🔍 Detalles del placemark:")
                print("   - Barrio (subLocality): \(placemark.subLocality ?? "N/A")")
                print("   - Calle (thoroughfare): \(placemark.thoroughfare ?? "N/A")")
                print("   - Número (subThoroughfare): \(placemark.subThoroughfare ?? "N/A")")
                print("   - Ciudad (locality): \(placemark.locality ?? "N/A")")
                print("   - Comuna/Área (administrativeArea): \(placemark.administrativeArea ?? "N/A")")
                print("   - País (country): \(placemark.country ?? "N/A")")
                print("   - Nombre del lugar (name): \(placemark.name ?? "N/A")")
                
                completion(.success((neighborhood: finalNeighborhood, city: city, country: country)))
            }
        }
    }
    
    // Buscar lugares cercanos para identificar el barrio o zona
    private func searchNearbyPlaces(at location: CLLocation, completion: @escaping (String?) -> Void) {
        let request = MKLocalSearch.Request()
        // Buscar puntos de interés, barrios o áreas conocidas
        request.naturalLanguageQuery = "punto de interés"
        
        let span = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005) // Radio más pequeño para mayor precisión
        request.region = MKCoordinateRegion(center: location.coordinate, span: span)
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            if let error = error {
                print("⚠️ Error buscando lugares cercanos: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            // Filtrar resultados: buscar lugares que NO sean calles
            if let items = response?.mapItems {
                print("🔍 Lugares encontrados: \(items.count)")
                
                for (index, item) in items.prefix(5).enumerated() {
                    let name = item.name ?? "Sin nombre"
                    let category = item.pointOfInterestCategory?.rawValue ?? "N/A"
                    print("   [\(index + 1)] \(name) - Categoría: \(category)")
                }
                
                // Buscar primer lugar que sea un barrio, zona o punto de interés relevante
                let relevantPlace = items.first { item in
                    guard let name = item.name else { return false }
                    let nameLower = name.lowercased()
                    
                    // Excluir calles genéricas
                    let excludedTerms = ["calle", "avenida", "av.", "pasaje", "camino"]
                    let hasExcludedTerm = excludedTerms.contains { nameLower.contains($0) }
                    
                    // Incluir barrios, plazas, parques, edificios conocidos
                    let includedTerms = ["barrio", "plaza", "parque", "mall", "centro", "museo", "estadio", "universidad"]
                    let hasIncludedTerm = includedTerms.contains { nameLower.contains($0) }
                    
                    return !hasExcludedTerm || hasIncludedTerm
                }
                
                if let place = relevantPlace {
                    let name = place.name ?? place.placemark.name
                    print("✅ Lugar seleccionado: \(name ?? "desconocido")")
                    completion(name)
                } else {
                    print("ℹ️ No se encontró barrio específico, usando datos del placemark")
                    completion(nil)
                }
            } else {
                completion(nil)
            }
        }
    }
}

