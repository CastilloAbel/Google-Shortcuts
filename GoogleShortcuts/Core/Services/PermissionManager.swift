import Foundation
import UIKit
import UserNotifications

/// Gestor centralizado de permisos (simplificado para Background App Refresh).
/// Ya no se necesita Core Location - el portapapeles se monitorea via Background App Refresh.
final class PermissionManager: NSObject, ObservableObject {
    static let shared = PermissionManager()
    
    nonisolated private override init() {
        super.init()
        print("✅ PermissionManager inicializado")
    }
}
