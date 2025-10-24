import SwiftUI

struct WeatherOverlay {
  let temperature: String
  let location: String
  let weatherIcon: String
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
      
      // Diseño del clima
      VStack(spacing: 8) {
        HStack(spacing: 12) {
          Image(systemName: weather.weatherIcon)
            .font(.system(size: 40))
            .foregroundColor(.white)
          
          Text(weather.temperature)
            .font(.system(size: 36, weight: .bold))
            .foregroundColor(.white)
        }
        
        Text(weather.location)
          .font(.system(size: 16, weight: .medium))
          .foregroundColor(.white)
      }
      .padding(16)
      .background(
        LinearGradient(
          colors: [Color.orange.opacity(0.8), Color.pink.opacity(0.8)],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
      )
      .cornerRadius(16)
      .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
  }
}

