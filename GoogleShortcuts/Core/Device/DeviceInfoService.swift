import Foundation
import UIKit

/// Servicio para acceder a información del dispositivo
actor DeviceInfoService {
    static let shared = DeviceInfoService()
    
    private init() {}
    
    /// Obtiene información completa del dispositivo
    nonisolated func getInfo() -> DeviceInfo {
        let device = UIDevice.current
        
        return DeviceInfo(
            deviceModel: getDeviceModel(),
            osVersion: device.systemVersion,
            deviceName: device.name,
            systemUptime: ProcessInfo.processInfo.systemUptime,
            totalStorage: getTotalStorage(),
            availableStorage: getAvailableStorage(),
            screenBrightness: Float(UIScreen.main.brightness),
            isDarkModeEnabled: isDarkModeEnabled(),
            timeZone: TimeZone.current.abbreviation() ?? "UTC",
            locale: Locale.current.identifier
        )
    }
    
    /// Obtiene el modelo del dispositivo (e.g., "iPhone 15 Pro")
    nonisolated func getDeviceModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let modelCode = withUnsafeBytes(of: &systemInfo.machine) { pointer in
            String(cString: pointer.baseAddress!.assumingMemoryBound(to: CChar.self))
        }
        
        // Mapear códigos de modelo a nombres humanizados
        let modelNames: [String: String] = [
            // iPhone 15 series
            "iPhone17,1": "iPhone 16",
            "iPhone17,2": "iPhone 16 Plus",
            "iPhone17,3": "iPhone 16 Pro",
            "iPhone17,4": "iPhone 16 Pro Max",
            
            // iPhone 14 series
            "iPhone15,1": "iPhone 15",
            "iPhone15,2": "iPhone 15 Plus",
            "iPhone15,3": "iPhone 15 Pro",
            "iPhone15,4": "iPhone 15 Pro Max",
            
            // iPhone 13 series
            "iPhone14,5": "iPhone 13",
            "iPhone14,6": "iPhone 13 mini",
            "iPhone14,3": "iPhone 13 Pro",
            "iPhone14,2": "iPhone 13 Pro Max",
        ]
        
        return modelNames[modelCode] ?? modelCode
    }
    
    /// Obtiene el almacenamiento total del dispositivo
    nonisolated private func getTotalStorage() -> UInt64 {
        guard let space = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())[.systemSize] as? NSNumber else {
            return 0
        }
        return space.uint64Value
    }
    
    /// Obtiene el almacenamiento disponible en el dispositivo
    nonisolated private func getAvailableStorage() -> UInt64 {
        guard let space = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())[.systemFreeSize] as? NSNumber else {
            return 0
        }
        return space.uint64Value
    }
    
    /// Verifica si Dark Mode está habilitado
    nonisolated private func isDarkModeEnabled() -> Bool {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return false
        }
        return scene.windows.first?.traitCollection.userInterfaceStyle == .dark
    }
    
    /// Obtiene información de almacenamiento (total y disponible)
    nonisolated func getStorage() -> (total: UInt64, available: UInt64) {
        return (
            total: getTotalStorage(),
            available: getAvailableStorage()
        )
    }
}
