import SwiftUI

// MARK: - Location Overlay Model
struct LocationOverlay {
  let neighborhood: String
  let date: String
  let city: String
  let country: String
}

enum WeatherType {
  case sunny
  case cold
  case normal
  
  var imageName: String {
    switch self {
    case .sunny: return "3"      // sunny → 3.svg
    case .cold: return "2"       // cold → 2.svg
    case .normal: return "1"     // normal → 1.svg
    }
  }
}

struct WeatherOverlay {
  let temperature: String
  let location: String
  let weatherType: WeatherType
  
  // Determinar el tipo de clima basado en la temperatura
  init(temperature: String, location: String) {
    self.temperature = temperature
    self.location = location
    
    // Extraer el número de la temperatura
    let numericTemp = temperature.replacingOccurrences(of: "°C", with: "")
      .replacingOccurrences(of: "°F", with: "")
      .trimmingCharacters(in: .whitespaces)
    
    if let temp = Int(numericTemp) {
      if temp >= 25 {
        self.weatherType = .sunny
      } else if temp <= 10 {
        self.weatherType = .cold
      } else {
        self.weatherType = .normal
      }
    } else {
      self.weatherType = .normal
    }
  }
}

struct WeatherOverlayView: View {
  let weather: WeatherOverlay
  let onRemove: () -> Void
  
  var body: some View {
    VStack(alignment: .trailing, spacing: 8) {
      // Botón para remover
      Button(action: onRemove) {
        Image(systemName: "xmark.circle.fill")
          .font(.title3)
          .foregroundColor(.white.opacity(0.8))
      }
      
      // Diseño del clima sin fondo
      VStack(spacing: 8) {
        HStack(spacing: 12) {
          // Imagen SVG según el clima
          Image(weather.weatherType.imageName)
            .resizable()
            .scaledToFit()
            .frame(width: 48, height: 48)
          
          Text(weather.temperature)
            .font(.custom("Ari-W9500Display", size: 40))
            .foregroundColor(.white)
        }
        
        Text(weather.location.uppercased())
          .font(.custom("Ari-W9500Display", size: 12))
          .foregroundColor(.white)
      }
      .padding(16)
      .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 4)
    }
  }
}

// MARK: - Location Overlay View
struct LocationOverlayView: View {
  let location: LocationOverlay
  let onRemove: () -> Void
  
  var body: some View {
    VStack(alignment: .trailing, spacing: 4) {
      // Botón para remover
      Button(action: onRemove) {
        Image(systemName: "xmark.circle.fill")
          .font(.system(size: 20))
          .foregroundColor(.white.opacity(0.8))
      }
      .padding(.bottom, 8)
      
      // Contenido de la ubicación
      VStack(alignment: .leading, spacing: 6) {
        // Barrio
        Text(location.neighborhood.uppercased())
          .font(.custom("Ari-W9500Bold", size: 22))
          .foregroundColor(.white)
        
        // Fecha
        Text(location.date)
          .font(.custom("Ari-W9500Display", size: 14))
          .foregroundColor(.white.opacity(0.9))
        
        // Ciudad y país
        Text("\(location.city), \(location.country)")
          .font(.custom("Ari-W9500Display", size: 14))
          .foregroundColor(.white.opacity(0.9))
      }
      .padding(16)
      .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 4)
    }
  }
}

