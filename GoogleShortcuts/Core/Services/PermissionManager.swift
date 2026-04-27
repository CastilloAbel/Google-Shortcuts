import Foundation
import UIKit
import UserNotifications
import Contacts

/// Gestor centralizado de permisos.
/// Solicita permisos una sola vez en la instalación.
final class PermissionManager: NSObject, ObservableObject {
    static let shared = PermissionManager()
    
    private let userDefaults = UserDefaults.standard
    private let permissionsKey = "permissions_requested"
    
    override private init() {
        super.init()
    }
    
    // MARK: - Métodos Públicos
    
    /// Solicita todos los permisos necesarios una sola vez
    func requestAllPermissions() {
        // Solo solicitar si no se han solicitado antes
        if hasRequestedPermissions() {
            print("✅ Permisos ya fueron solicitados anteriormente")
            return
        }
        
        print("📋 Solicitando permisos por primera vez...")
        
        Task {
            // Notificaciones
            await requestNotificationPermission()
            
            // Contactos (opcional)
            await requestContactsPermission()
            
            // Marcar como solicitados
            await MainActor.run {
                self.markPermissionsRequested()
                print("✅ Permisos solicitados")
            }
        }
    }
    
    /// Verifica si ya se solicitaron permisos
    func hasRequestedPermissions() -> Bool {
        UserDefaults.standard.bool(forKey: permissionsKey)
    }
    
    // MARK: - Solicitud de Notificaciones
    
    /// Solicita permisos para notificaciones (local only, no remotas)
    private func requestNotificationPermission() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            print(granted ? "✅ Notificaciones permitidas" : "❌ Notificaciones denegadas")
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
            print(granted ? "✅ Contactos permitidos" : "❌ Contactos denegados")
        } catch {
            print("❌ Error solicitando permisos de contactos: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Marcado de Permisos
    
    /// Marca que los permisos ya fueron solicitados
    private func markPermissionsRequested() {
        UserDefaults.standard.set(true, forKey: permissionsKey)
    }
}
