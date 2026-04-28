import Foundation
import UIKit
import UserNotifications
import Contacts
import CoreLocation

/// Gestor centralizado de permisos.
/// Solicita permisos una sola vez en la instalación.
final class PermissionManager: NSObject, ObservableObject {
    static let shared = PermissionManager()
    
    private let userDefaults = UserDefaults.standard
    private let permissionsKey = "permissions_requested"
    private lazy var locationManager = CLLocationManager()
    
    override private init() {
        super.init()
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
    
    /// Solicita permisos de ubicación para mantener la app en background
    /// Esto permite que el monitoreo del portapapeles continúe en segundo plano
    private func requestLocationPermission() {
        let status = CLLocationManager.authorizationStatus()
        
        // Solo solicitar si aún no se ha decidido
        if status == .notDetermined {
            // Solicitar "Always" para máxima compatibilidad con background monitoring
            locationManager.requestAlwaysAuthorization()
            print("📍 Solicitando permiso de ubicación (para background monitoring)")
        } else if status == .denied || status == .restricted {
            print("⚠️ Permiso de ubicación denegado. El monitoreo automático puede ser limitado.")
        } else if status == .authorizedAlways || status == .authorizedWhenInUse {
            print("✅ Ubicación permitida - Background monitoring activo")
        }
    }
    
    // MARK: - Marcado de Permisos
    
    /// Marca que los permisos ya fueron solicitados (sincrónico y seguro)
    private func markPermissionsRequested() {
        userDefaults.set(true, forKey: permissionsKey)
    }
}
