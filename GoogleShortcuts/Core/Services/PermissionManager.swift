import Foundation
import UIKit
import UserNotifications
import Contacts

/// Gestor centralizado de permisos.
/// Solicita permisos una sola vez en la instalación.
actor PermissionManager {
    static let shared = PermissionManager()
    
    private let userDefaults = UserDefaults.standard
    private let permissionsKey = "permissions_requested"
    
    // MARK: - Métodos Públicos
    
    /// Solicita todos los permisos necesarios una sola vez
    nonisolated func requestAllPermissions() {
        Task {
            await requestNotificationPermission()
            await requestContactsPermission()
            await markPermissionsRequested()
        }
    }
    
    /// Verifica si ya se solicitaron permisos
    nonisolated func hasRequestedPermissions() -> Bool {
        UserDefaults.standard.bool(forKey: permissionsKey)
    }
    
    // MARK: - Solicitud de Notificaciones
    
    /// Solicita permisos para notificaciones (clipboard cambios en background)
    private func requestNotificationPermission() async {
        do {
            _ = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
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
            _ = try await contactStore.requestAccess(for: .contacts)
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
