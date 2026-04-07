import Foundation
import CoreMotion
import CoreLocation
import UIKit

/// Servicio para acceder a datos de movimiento y sensores del dispositivo
actor MotionService {
    static let shared = MotionService()
    
    private let motionManager = CMMotionActivityManager()
    private let motionActivityManager = CMMotionActivityManager()
    private let pedometer = CMPedometer()
    private let locationManager = CLLocationManager()
    
    private init() {}
    
    /// Obtiene datos de movimiento del dispositivo
    nonisolated func getMotionData() -> DeviceMotionData {
        return DeviceMotionData(
            orientation: getCurrentOrientation(),
            motionActivity: getMotionActivity(),
            compassHeading: getCompassHeading(),
            elevation: nil,  // Requiere permisos de ubicación
            isDeviceMoving: false  // Placeholder
        )
    }
    
    /// Obtiene la orientación actual del dispositivo
    nonisolated private func getCurrentOrientation() -> UIInterfaceOrientation {
        let orientation = UIDevice.current.orientation
        return switch orientation {
        case .portrait, .portraitUpsideDown:
            .portrait
        case .landscapeLeft, .landscapeRight:
            .landscapeRight
        default:
            .portrait
        }
    }
    
    /// Obtiene la actividad de movimiento actual
    nonisolated private func getMotionActivity() -> DeviceMotionData.MotionActivity {
        // Requiere NSMotionUsageDescription en Info.plist
        // Por ahora, devolvemos unknown como placeholder
        return .unknown
    }
    
    /// Obtiene el heading de la brújula (0-360°)
    nonisolated private func getCompassHeading() -> Double? {
        // Requiere NSLocationWhenInUseUsageDescription
        // Por ahora, devolvemos nil
        return nil
    }
}
