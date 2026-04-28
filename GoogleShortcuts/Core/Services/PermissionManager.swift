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
        
        // Solicitar ubicación (para mantener app en background)
        requestLocationPermission()
        
        // Solicitar notificaciones en background (sin esperar)
        Task {
            await requestNotificationPermission()
        }
        
        // Solicitar contactos en background (sin esperar)
        Task {
            await requestContactsPermission()
        }
    }
    
    /// Verifica si ya se solicitaron permisos
    func hasRequestedPermissions() -> Bool {
        userDefaults.bool(forKey: permissionsKey)
    }
    
    /// Método público para solicitar permiso de ubicación manualmente
    func requestLocationPermissionManually() {
        print("📍 Usuario solicitando permiso de ubicación desde Ajustes...")
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
        
        // Asegurar que se ejecuta en main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Solo solicitar si aún no se ha decidido
            if status == .notDetermined {
                print("📍 Solicitando permiso de ubicación (paso 1: When in Use)...")
                print("📍 CLLocationManager delegate: \(self.locationManager.delegate != nil ? "✅ Configurado" : "❌ NO configurado")")
                // Primero solicitamos "When in Use"
                self.locationManager.requestWhenInUseAuthorization()
                print("📍 ✅ Llamada a requestWhenInUseAuthorization() ejecutada")
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
    
    /// Solicita el upgrade del permiso de ubicación de "When in Use" a "Always"
    private func requestLocationUpgrade() {
        // Evitar solicitar upgrade múltiples veces
        if userDefaults.bool(forKey: locationUpgradeKey) {
            print("⚠️ Ya se solicitó upgrade anteriormente")
            return
        }
        
        print("📍 Marcando upgrade como solicitado y llamando a requestAlwaysAuthorization()...")
        userDefaults.set(true, forKey: locationUpgradeKey)
        DispatchQueue.main.async {
            self.locationManager.requestAlwaysAuthorization()
            print("📍 ✅ Llamada a requestAlwaysAuthorization() ejecutada")
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
