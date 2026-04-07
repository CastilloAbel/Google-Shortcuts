import Foundation
import UIKit

/// Servicio para acceder al estado actual del dispositivo
@MainActor
final class DeviceStateService {
    static let shared = DeviceStateService()
    
    private init() {}
    
    /// Obtiene el estado actual del dispositivo
    func getState() -> DeviceState {
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?
            .windows
            .first
        
        let safeAreaInsets = window?.safeAreaInsets ?? .zero
        
        return DeviceState(
            isDeviceLocked: UIDevice.current.isProtectedDataAvailable == false,
            isScreenOn: UIScreen.main.brightness > 0,
            hasNotchOrDynamicIsland: hasNotchOrIsland(),
            safeAreaInsets: DeviceState.SafeAreaInfo(
                top: Float(safeAreaInsets.top),
                bottom: Float(safeAreaInsets.bottom),
                left: Float(safeAreaInsets.left),
                right: Float(safeAreaInsets.right)
            )
        )
    }
    
    /// Verifica si el dispositivo tiene notch o Dynamic Island
    private func hasNotchOrIsland() -> Bool {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?
            .windows
            .first else {
            return false
        }
        
        // Si el safeAreaInsets.top es > 0, hay notch/Dynamic Island
        return window.safeAreaInsets.top > 20
    }
}
