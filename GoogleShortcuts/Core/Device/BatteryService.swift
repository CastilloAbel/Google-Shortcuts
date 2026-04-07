import Foundation
import UIKit

/// Servicio para acceder a información de batería del dispositivo
@MainActor
final class BatteryService {
    static let shared = BatteryService()
    
    private init() {
        UIDevice.current.isBatteryMonitoringEnabled = true
    }
    
    /// Obtiene el estado actual de la batería
    func getBatteryStatus() -> BatteryInfo {
        let device = UIDevice.current
        let level = Int(device.batteryLevel * 100)
        
        let state: BatteryInfo.BatteryState = switch device.batteryState {
        case .charging:
            .charging
        case .full:
            .full
        case .unplugged:
            .unplugged
        default:
            .unknown
        }
        
        let isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
        
        // iOS no expone tiempo estimado de batería
        let estimatedTime: Double? = nil
        
        return BatteryInfo(
            level: max(0, min(100, level)),
            state: state,
            isLowPowerModeEnabled: isLowPowerMode,
            estimatedTimeRemaining: estimatedTime
        )
    }
    
    /// Verifica si la batería está baja
    func isLow(percentage: Int) -> Bool {
        Int(UIDevice.current.batteryLevel * 100) <= percentage
    }
}
