import Foundation
import UIKit
import UserNotifications
import Contacts
import CoreLocation

/// Gestor centralizado de permisos.
/// Solicita permisos una sola vez en la instalación.
final class PermissionManager: NSObject, ObservableObject, CLLocationManagerDelegate, Sendable {
    static let shared = PermissionManager()
    
    nonisolated private let userDefaults = UserDefaults.standard
    nonisolated private let permissionsKey = "permissions_requested"
    nonisolated private let locationUpgradeKey = "location_upgrade_requested"
    
    /// Strong reference al locationManager (inicializado inline)
    private let locationManager: CLLocationManager
    
    override private init() {
        // Inicializar locationManager ANTES de super.init()
        self.locationManager = CLLocationManager()
        super.init()
        // Configurar el location manager con este objeto como delegate
        self.locationManager.delegate = self
        
        // Configurar para máxima eficiencia de batería
        self.locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        self.locationManager.distanceFilter = 1000  // 1km de cambio
        self.locationManager.pausesLocationUpdatesAutomatically = false
        
        print("✅ PermissionManager inicializado con CLLocationManager (Battery efficient)")
    }
    
    // MARK: - Métodos Públicos
    
    /// Solicita todos los permisos necesarios una sola vez (seguro para Swift 6)
    func requestAllPermissions() {
        // Solo solicitar si no se han solicitado antes
        if hasRequestedPermissions() {
            print("✅ Permisos ya fueron solicitados anteriormente")
            return
        }
        
        print("📋 Solicitando permisos por primera vez...")
        
        // Marcar como solicitados INMEDIATAMENTE para evitar duplicados
        markPermissionsRequested()
        
        // Solicitar SOLO ubicación (sin notificaciones ni contactos por ahora)
        // Esto evita conflictos entre múltiples popups
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            print("📍 [requestAllPermissions] Solicitando ubicación...")
            self?.requestLocationPermission()
        }
    }
    
    /// Verifica si ya se solicitaron permisos
    func hasRequestedPermissions() -> Bool {
        userDefaults.bool(forKey: permissionsKey)
    }
    
    /// Método público para solicitar permiso de ubicación manualmente
    /// Esta versión es más agresiva: intenta obtener ubicación inmediatamente
    func requestLocationPermissionManually() {
        print("📍 Usuario solicitando permiso de ubicación desde Ajustes...")
        print("📍 Estado actual: \(getLocationPermissionStatus())")
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let status = self.locationManager.authorizationStatus
            
            // Si aún no se ha decidido, solicitar inmediatamente
            if status == .notDetermined {
                print("📍 [Manual] Estado .notDetermined - Solicitando When in Use...")
                
                // Iniciar actualizaciones ANTES de solicitar (esto fuerza el popup)
                self.locationManager.startUpdatingLocation()
                print("📍 [Manual] ✅ startUpdatingLocation() iniciado")
                
                // Luego solicitar el permiso
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.locationManager.requestWhenInUseAuthorization()
                    print("📍 [Manual] ✅ requestWhenInUseAuthorization() ejecutado")
                }
            }
            // Si ya tiene "When in Use", solicitar upgrade a Always
            else if status == .authorizedWhenInUse {
                print("📍 [Manual] Estado .authorizedWhenInUse - Solicitando Always...")
                self.locationManager.requestAlwaysAuthorization()
                print("📍 [Manual] ✅ requestAlwaysAuthorization() ejecutado")
            }
            // Si ya tiene Always, no hacer nada
            else if status == .authorizedAlways {
                print("✅ [Manual] Ya tiene permiso Always")
            }
            // Si fue denegado, no se puede hacer nada desde aquí
            else if status == .denied || status == .restricted {
                print("⚠️ [Manual] Permiso denegado o restringido")
            }
        }
    }
    
    /// Verifica el estado actual del permiso de ubicación
    func getLocationPermissionStatus() -> String {
        let status = locationManager.authorizationStatus
        switch status {
        case .authorizedAlways:
            return "✅ Siempre"
        case .authorizedWhenInUse:
            return "⏳ Cuando se usa"
        case .denied:
            return "❌ Denegado"
        case .restricted:
            return "🔒 Restringido"
        case .notDetermined:
            return "⏸️ No determinado"
        @unknown default:
            return "❓ Desconocido"
        }
    }
    
    // MARK: - Solicitud de Notificaciones
    
    /// Solicita permisos para notificaciones (local only, no remotas)
    private func requestNotificationPermission() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            if granted {
                print("✅ Notificaciones permitidas")
            } else {
                print("❌ Notificaciones denegadas por el usuario")
            }
        } catch {
            print("❌ Error solicitando permisos de notificaciones: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Solicitud de Contactos
    
    /// Solicita permisos para acceder a contactos
    private func requestContactsPermission() async {
        let contactStore = CNContactStore()
        do {
            let granted = try await contactStore.requestAccess(for: .contacts)
            if granted {
                print("✅ Contactos permitidos")
            } else {
                print("❌ Contactos denegados por el usuario")
            }
        } catch {
            print("❌ Error solicitando permisos de contactos: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Solicitud de Ubicación
    
    /// Solicita permisos de ubicación mediante proceso simple y directo
    /// Intenta obtener ubicación inmediatamente para forzar el popup de iOS
    private func requestLocationPermission() {
        let status = locationManager.authorizationStatus
        print("📍 Estado actual de ubicación: \(status.rawValue)")
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            print("📍 Intentando solicitar ubicación...")
            
            // Solo solicitar si aún no se ha decidido
            if status == .notDetermined {
                print("📍 Estado .notDetermined - Solicitando When in Use...")
                print("📍 Iniciando startUpdatingLocation para forzar popup...")
                
                // Iniciar actualizaciones PRIMERO (esto fuerza el popup)
                self.locationManager.startUpdatingLocation()
                print("📍 ✅ startUpdatingLocation() iniciado")
                
                // Luego solicitar permiso
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.locationManager.requestWhenInUseAuthorization()
                    print("📍 ✅ requestWhenInUseAuthorization() ejecutado")
                }
                
            } else if status == .authorizedWhenInUse {
                print("📍 Estado .authorizedWhenInUse - Iniciando ubicación...")
                self.locationManager.startUpdatingLocation()
                print("📍 ✅ startUpdatingLocation() para when in use")
                
                // Solicitar upgrade a Always
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.locationManager.requestAlwaysAuthorization()
                    print("📍 Solicitando upgrade a Always...")
                }
                
            } else if status == .authorizedAlways {
                print("✅ Estado .authorizedAlways - Iniciando ubicación para background...")
                self.locationManager.startUpdatingLocation()
                print("📍 ✅ startUpdatingLocation() para background")
                
            } else if status == .denied || status == .restricted {
                print("⚠️ Estado .denied/.restricted - El usuario debe habilitar en Settings")
            }
        }
    }
    
    /// Obtiene el UIViewController visible de la ventana actual
    private func getTopViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            print("❌ No se encontró window scene")
            return nil
        }
        
        var topController = window.rootViewController
        
        while let presentedViewController = topController?.presentedViewController {
            topController = presentedViewController
        }
        
        print("📍 Top ViewController encontrado: \(topController.debugDescription)")
        return topController
    }
    
    /// Solicita el upgrade del permiso de ubicación de "When in Use" a "Always"
    private func requestLocationUpgrade() {
        print("📍 Solicitando upgrade a Always...")
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.locationManager.requestAlwaysAuthorization()
            print("📍 ✅ requestAlwaysAuthorization() ejecutado")
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    /// Se llama cuando el usuario responde a la solicitud de permiso de ubicación
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        print("📍 [DELEGATE] locationManagerDidChangeAuthorization llamado")
        print("📍 [DELEGATE] Estado: \(status.rawValue)")
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            switch status {
            case .authorizedAlways:
                print("✅ [DELEGATE] Permiso de ubicación: Always (Background monitoring totalmente activo)")
                // Iniciar actualizaciones para background monitoring
                self.locationManager.startUpdatingLocation()
                print("📍 [DELEGATE] startUpdatingLocation() iniciado para background")
                
            case .authorizedWhenInUse:
                print("⏳ [DELEGATE] Permiso de ubicación: When in Use")
                // Iniciar actualizaciones para Current Usage
                self.locationManager.startUpdatingLocation()
                print("📍 [DELEGATE] startUpdatingLocation() iniciado para when in use")
                
                // Solicitar upgrade a Always después de un pequeño delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    print("⏳ [DELEGATE] Solicitando upgrade a Always...")
                    self.requestLocationUpgrade()
                }
                
            case .denied, .restricted:
                print("❌ [DELEGATE] Permiso de ubicación denegado")
                // Detener actualizaciones
                self.locationManager.stopUpdatingLocation()
                
            case .notDetermined:
                print("⏳ [DELEGATE] Permiso de ubicación: Pendiente")
                
            @unknown default:
                break
            }
        }
    }
    
    /// Se llama cuando Location Manager obtiene ubicaciones
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("📍 [DELEGATE] didUpdateLocations: \(locations.count) ubicación(es) recibida(s)")
        if let lastLocation = locations.last {
            print("📍 [DELEGATE] Lat: \(lastLocation.coordinate.latitude), Lon: \(lastLocation.coordinate.longitude)")
        }
    }
    
    /// Se llama cuando Location Manager falla
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ [DELEGATE] didFailWithError: \(error.localizedDescription)")
    }
    
    /// Marca que los permisos ya fueron solicitados (sincrónico y seguro)
    private func markPermissionsRequested() {
        userDefaults.set(true, forKey: permissionsKey)
    }
}
