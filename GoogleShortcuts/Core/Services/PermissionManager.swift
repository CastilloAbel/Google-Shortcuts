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
        print("✅ PermissionManager inicializado con CLLocationManager")
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
        
        // Solicitar ubicación PRIMEIRO con delay para evitar race condition
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            print("📍 [requestAllPermissions] Solicitando ubicación...")
            self?.requestLocationPermission()
        }
        
        // Solicitar notificaciones con delay mayor
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            Task {
                await self?.requestNotificationPermission()
            }
        }
        
        // Solicitar contactos con delay mayor
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            Task {
                await self?.requestContactsPermission()
            }
        }
    }
    
    /// Verifica si ya se solicitaron permisos
    func hasRequestedPermissions() -> Bool {
        userDefaults.bool(forKey: permissionsKey)
    }
    
    /// Método público para solicitar permiso de ubicación manualmente
    func requestLocationPermissionManually() {
        print("📍 Usuario solicitando permiso de ubicación desde Ajustes...")
        print("📍 Estado actual: \(getLocationPermissionStatus())")
        DispatchQueue.main.async {
            self.requestLocationPermission()
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
    
    /// Solicita permisos de ubicación mediante proceso stepwise:
    /// 1. Primero pide "When in Use" (esto muestra el primer dialog)
    /// 2. Luego, si es aceptado, pide el upgrade a "Always"
    private func requestLocationPermission() {
        let status = locationManager.authorizationStatus
        print("📍 Estado actual de ubicación: \(status.rawValue)")
        
        // Resetear el flag de upgrade si el usuario vuelve a intentar desde Ajustes
        if status == .authorizedWhenInUse {
            userDefaults.set(false, forKey: locationUpgradeKey)
            print("📍 Reseteando flag de upgrade para permitir nuevo intento")
        }
        
        // Asegurar que se ejecuta en main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Obtener el UIViewController visible de la window scene
            let topViewController = self.getTopViewController()
            
            // Solo solicitar si aún no se ha decidido
            if status == .notDetermined {
                print("📍 Solicitando permiso de ubicación (paso 1: When in Use)...")
                print("📍 Top ViewController: \(topViewController != nil ? "✅ Encontrado" : "❌ No encontrado")")
                print("📍 CLLocationManager delegate: \(self.locationManager.delegate != nil ? "✅ Configurado" : "❌ NO configurado")")
                
                // Configurar el location manager
                self.locationManager.desiredAccuracy = kCLLocationAccuracyReduced
                self.locationManager.distanceFilter = kCLDistanceFilterNone
                
                // Primero solicitamos "When in Use"
                self.locationManager.requestWhenInUseAuthorization()
                print("📍 ✅ Llamada a requestWhenInUseAuthorization() ejecutada")
                
                // Iniciar actualización de ubicación para activar el servicio
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.locationManager.startUpdatingLocation()
                    print("📍 ✅ startUpdatingLocation() iniciado")
                }
            } else if status == .denied || status == .restricted {
                print("⚠️ Permiso de ubicación denegado. El monitoreo automático puede ser limitado.")
            } else if status == .authorizedAlways {
                print("✅ Ubicación permitida (Always) - Background monitoring activo")
            } else if status == .authorizedWhenInUse {
                print("⏳ Ubicación permitida (When in Use) - Solicitando upgrade a Always...")
                // Si ya tiene "When in Use", solicitar upgrade a "Always"
                self.requestLocationUpgrade()
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
        print("📍 Llamando a requestAlwaysAuthorization()...")
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Configurar el location manager para empezar a detectar ubicación
            self.locationManager.desiredAccuracy = kCLLocationAccuracyReduced
            self.locationManager.distanceFilter = kCLDistanceFilterNone
            self.locationManager.requestWhenInUseAuthorization()

            self.locationManager.requestAlwaysAuthorization()
            print("📍 ✅ Llamada a requestAlwaysAuthorization() ejecutada")
            
            // Iniciar actualización de ubicación para activar el servicio
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.locationManager.startUpdatingLocation()
                print("📍 ✅ startUpdatingLocation() iniciado")
            }
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
            case .authorizedWhenInUse:
                print("⏳ [DELEGATE] Permiso de ubicación: When in Use (Solicitando upgrade...)")
                self.requestLocationUpgrade()
            case .denied, .restricted:
                print("❌ [DELEGATE] Permiso de ubicación denegado")
            case .notDetermined:
                print("⏳ [DELEGATE] Permiso de ubicación: Pendiente")
            @unknown default:
                break
            }
        }
    }
    
    // MARK: - Marcado de Permisos
    
    /// Marca que los permisos ya fueron solicitados (sincrónico y seguro)
    private func markPermissionsRequested() {
        userDefaults.set(true, forKey: permissionsKey)
    }
}
