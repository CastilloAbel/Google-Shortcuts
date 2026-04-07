import Foundation
import CoreLocation
import Network
import NetworkExtension
import UIKit

/// Framework para exponer capabilidades del dispositivo via App Intents
/// Compil complemento a Gmail, similar a "Actions" de Sindre Sorhus
///
/// Categorías soportadas:
/// - Battery & Power
/// - Connectivity (Bluetooth, WiFi, VPN, Cellular)
/// - Device Motion & Sensors
/// - Device State & Info
/// - Audio & Media
/// - Network Reachability
/// - User Preferences

// MARK: - Battery & Power Info

public struct BatteryInfo {
    public let level: Int                    // 0-100
    public let state: BatteryState          // charging, discharging, full, unknown
    public let isLowPowerModeEnabled: Bool
    public let estimatedTimeRemaining: Double?  // segundos, nil si desconocido
    
    public enum BatteryState: String, Codable {
        case unknown
        case unplugged      // Battery discharging
        case charging       // Plugged in, charging
        case full           // Plugged in, not charging
    }
}

// MARK: - Connectivity Status

public struct ConnectivityStatus {
    public let isBluetoothOn: Bool
    public let isWiFiOn: Bool
    public let isVPNConnected: Bool
    public let isCellularDataOn: Bool
    public let isLowDataModeOn: Bool
    public let activeCellularTechnology: CellularTechnology?
    
    public enum CellularTechnology: String, Codable {
        case gprs, edge, wwan, cdma1x          // Legacy
        case hsdpa, hsupa, hspa                 // 3G
        case cdma_evdo_0, cdma_evdo_revA        // 3G
        case cdma_evdo_revB, ehrpd              // 3G
        case lte                                // 4G
        case nrSA = "5g_sa"                     // 5G Standalone
        case nrNSA = "5g_nsa"                   // 5G Non-Standalone
        case unknown
    }
}

// MARK: - Device Motion & Sensors

public struct DeviceMotionData {
    public let orientation: UIInterfaceOrientation
    public let motionActivity: MotionActivity
    public let compassHeading: Double?         // 0-360 degrees (nil si brújula no disponible)
    public let elevation: Double?              // meters (nil si GPS/altimeter no disponible)
    public let isDeviceMoving: Bool
    
    public enum MotionActivity: String, Codable {
        case walking
        case running
        case cycling
        case automotive        // In car
        case stationary        // Parado
        case unknown
    }
}

// MARK: - Device Information

public struct DeviceInfo {
    public let deviceModel: String              // "iPhone 15 Pro"
    public let osVersion: String                // "17.4.1"
    public let deviceName: String               // Nombre del dispositivo del usuario
    public let systemUptime: TimeInterval        // segundos desde último boot
    public let totalStorage: UInt64             // bytes
    public let availableStorage: UInt64          // bytes
    public let screenBrightness: Float          // 0.0-1.0
    public let isDarkModeEnabled: Bool
    public let timeZone: String                 // e.g. "America/New_York"
    public let locale: String                   // e.g. "es_ES"
}

// MARK: - Audio & Media Status

public struct AudioMediaStatus {
    public let isAudioPlaying: Bool
    public let playbackDestination: AudioDestination
    public let isSilentModeOn: Bool
    public let systemVolume: Float              // 0.0-1.0
    
    public enum AudioDestination: String, Codable {
        case speaker
        case headphones
        case bluetoothA2DP    // Bluetooth speakers/headphones
        case bluetoothHFP     // Bluetooth car audio
        case builtInSpeaker
        case airplay
        case hdmi
        case unknown
    }
}

// MARK: - Network Status

public struct NetworkStatus {
    public let isOnline: Bool                                    // Has internet connection
    public let connectionType: NetworkConnectionType
    public let canReachHost: [(host: String, reachable: Bool)]  // Custom hosts to check
    
    public enum NetworkConnectionType: String, Codable {
        case wifi
        case cellular
        case unknown
        case unavailable
    }
}

// MARK: - Device State

public struct DeviceState {
    public let isDeviceLocked: Bool
    public let isScreenOn: Bool
    public let hasNotchOrDynamicIsland: Bool
    public let safeAreaInsets: SafeAreaInfo
    
    public struct SafeAreaInfo {
        public let top: Float
        public let bottom: Float
        public let left: Float
        public let right: Float
    }
}

// MARK: - Services Factory

/// Acceso centralizado a todos los servicios de capabilidades del dispositivo
public enum DeviceCapabilities {
    
    // MARK: Battery
    static func getBatteryInfo() -> BatteryInfo {
        BatteryService.shared.getBatteryStatus()
    }
    
    static func isBatteryLow(threshold: Int = 20) -> Bool {
        BatteryService.shared.isLow(percentage: threshold)
    }
    
    // MARK: Connectivity
    static func getConnectivityStatus() -> ConnectivityStatus {
        ConnectivityService.shared.getStatus()
    }
    
    static func isBluetoothEnabled() -> Bool {
        ConnectivityService.shared.isBluetoothEnabled()
    }
    
    static func isWiFiEnabled() -> Bool {
        ConnectivityService.shared.isWiFiEnabled()
    }
    
    static func isVPNConnected() -> Bool {
        ConnectivityService.shared.isVPNConnected()
    }
    
    // MARK: Device Motion
    static func getDeviceMotionData() -> DeviceMotionData {
        MotionService.shared.getMotionData()
    }
    
    static func getCurrentOrientation() -> UIInterfaceOrientation {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?
            .interfaceOrientation ?? .portrait
    }
    
    // MARK: Device Info
    static func getDeviceInfo() -> DeviceInfo {
        DeviceInfoService.shared.getInfo()
    }
    
    static func getDeviceStorage() -> (total: UInt64, available: UInt64) {
        DeviceInfoService.shared.getStorage()
    }
    
    // MARK: Audio & Media
    static func getAudioMediaStatus() -> AudioMediaStatus {
        AudioMediaService.shared.getStatus()
    }
    
    // MARK: Network
    static func getNetworkStatus() -> NetworkStatus {
        NetworkService.shared.getStatus()
    }
    
    static func isOnline() -> Bool {
        NetworkService.shared.isOnline()
    }
    
    // MARK: Device State
    static func getDeviceState() -> DeviceState {
        DeviceStateService.shared.getState()
    }
}
