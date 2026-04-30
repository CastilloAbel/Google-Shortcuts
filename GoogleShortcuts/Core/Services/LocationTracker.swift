import Foundation
import CoreLocation
import SwiftUI

/// Gestor observable de ubicación para mostrar en tiempo real
@MainActor
final class LocationTracker: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var location: CLLocationCoordinate2D?
    @Published var accuracy: Double = 0
    @Published var isUpdating = false
    @Published var statusMessage = "Sin ubicación"
    
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        self.locationManager.distanceFilter = 1000
    }
    
    func startTracking() {
        print("🗺️ LocationTracker: Iniciando rastreo...")
        isUpdating = true
        statusMessage = "Solicitando ubicación..."
        
        let status = locationManager.authorizationStatus
        
        if status == .notDetermined {
            print("🗺️ Estado .notDetermined - Solicitando When in Use...")
            locationManager.requestWhenInUseAuthorization()
        }
        
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            print("🗺️ Permiso ya concedido - Iniciando actualizaciones...")
            locationManager.startUpdatingLocation()
        }
    }
    
    func stopTracking() {
        print("🗺️ LocationTracker: Deteniendo rastreo...")
        isUpdating = false
        locationManager.stopUpdatingLocation()
    }
    
    // MARK: - CLLocationManagerDelegate
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        DispatchQueue.main.async {
            self.location = location.coordinate
            self.accuracy = location.horizontalAccuracy
            self.statusMessage = "✅ Ubicación recibida"
            print("🗺️ Ubicación actualizada: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.statusMessage = "❌ Error: \(error.localizedDescription)"
            print("🗺️ Error de ubicación: \(error)")
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("🗺️ Autorización cambió: \(status.rawValue)")
        
        DispatchQueue.main.async {
            switch status {
            case .authorizedAlways, .authorizedWhenInUse:
                print("🗺️ Permiso concedido - Iniciando ubicación...")
                self.locationManager.startUpdatingLocation()
                self.statusMessage = "⏳ Buscando ubicación..."
                
            case .denied, .restricted:
                self.statusMessage = "❌ Permiso denegado"
                
            case .notDetermined:
                self.statusMessage = "⏳ Esperando permiso..."
                
            @unknown default:
                break
            }
        }
    }
}
