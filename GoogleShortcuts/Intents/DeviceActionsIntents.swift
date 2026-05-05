import AppIntents
import Foundation

// MARK: - Battery Intents

struct GetBatteryLevelIntent: AppIntent {
    static var title: LocalizedStringResource = "Obtener nivel de batería"
    static var description: IntentDescription = "Devuelve el porcentaje actual de batería"
    
    func perform() async throws -> some IntentResult & ReturnsValue<Int> {
        let battery = await DeviceCapabilities.getBatteryInfo()
        return .result(value: battery.level)
    }
}

struct IsBatteryLowIntent: AppIntent {
    static var title: LocalizedStringResource = "¿Batería baja?"
    static var description: IntentDescription = "Verifica si la batería está baja (por defecto < 20%)"
    
    // Removido @Parameter temporalmente debido a ExtractAppIntentsMetadata error
    // Los parámetros con defaults pueden causar problemas en AppIntents
    
    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        let isLow = await DeviceCapabilities.isBatteryLow(threshold: 20)
        return .result(value: isLow)
    }
}

// TEMPORARILY DISABLED: GetBatteryStateIntent causes ExtractAppIntentsMetadata error

struct GetBatteryStateIntent: AppIntent {
    static var title: LocalizedStringResource = "Estado de batería"
    static var description: IntentDescription = "Devuelve si está cargando, cargada, o descargando"
    
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let battery = await DeviceCapabilities.getBatteryInfo()
        let state = battery.state.rawValue
        return .result(value: state)
    }
}


struct IsLowPowerModeOnIntent: AppIntent {
    static var title: LocalizedStringResource = "¿Modo bajo consumo?"
    static var description: IntentDescription = "Verifica si el modo de bajo consumo está activado"
    
    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        let battery = await DeviceCapabilities.getBatteryInfo()
        return .result(value: battery.isLowPowerModeEnabled)
    }
}

// MARK: - Connectivity Intents

struct IsBluetoothOnIntent: AppIntent {
    static var title: LocalizedStringResource = "¿Bluetooth encendido?"
    static var description: IntentDescription = "Verifica si Bluetooth está activo"
    
    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        let status = await DeviceCapabilities.getConnectivityStatus()
        return .result(value: status.isBluetoothOn)
    }
}

struct IsWiFiOnIntent: AppIntent {
    static var title: LocalizedStringResource = "¿WiFi encendido?"
    static var description: IntentDescription = "Verifica si WiFi está conectado"
    
    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        let status = await DeviceCapabilities.getConnectivityStatus()
        return .result(value: status.isWiFiOn)
    }
}
// MARK: - Connectivity Intents (TEMPORARILY DISABLED - Testing which causes ExtractAppIntentsMetadata error)

struct IsVPNConnectedIntent: AppIntent {
    static var title: LocalizedStringResource = "¿VPN conectado?"
    static var description: IntentDescription = "Verifica si hay una VPN activa"
    
    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        let status = await DeviceCapabilities.getConnectivityStatus()
        return .result(value: status.isVPNConnected)
    }
}

struct IsCellularDataOnIntent: AppIntent {
    static var title: LocalizedStringResource = "¿Datos móviles?"
    static var description: IntentDescription = "Verifica si los datos móviles están activados"
    
    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        let status = await DeviceCapabilities.getConnectivityStatus()
        return .result(value: status.isCellularDataOn)
    }
}


// MARK: - Device Info Intents (TEMPORARILY DISABLED - Testing which causes ExtractAppIntentsMetadata error)


struct GetDeviceModelIntent: AppIntent {
    static var title: LocalizedStringResource = "Modelo de dispositivo"
    static var description: IntentDescription = "Devuelve el modelo del iPhone (ej: iPhone 15 Pro)"
    
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let info = await DeviceCapabilities.getDeviceInfo()
        return .result(value: info.deviceModel)
    }
}

struct GetDeviceNameIntent: AppIntent {
    static var title: LocalizedStringResource = "Nombre del dispositivo"
    static var description: IntentDescription = "Devuelve el nombre que le diste a tu iPhone"
    
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let info = await DeviceCapabilities.getDeviceInfo()
        return .result(value: info.deviceName)
    }
}

struct GetiOSVersionIntent: AppIntent {
    static var title: LocalizedStringResource = "Versión de iOS"
    static var description: IntentDescription = "Devuelve la versión actual de iOS"
    
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let info = await DeviceCapabilities.getDeviceInfo()
        return .result(value: info.osVersion)
    }
}

// MARK: - Storage Intents

struct GetAvailableStorageIntent: AppIntent {
    static var title: LocalizedStringResource = "Espacio disponible"
    static var description: IntentDescription = "Devuelve el espacio libre en el dispositivo (en GB)"
    
    func perform() async throws -> some IntentResult & ReturnsValue<Double> {
        let storage = await DeviceCapabilities.getDeviceStorage()
        let availableGB = Double(storage.available) / 1_000_000_000
        return .result(value: availableGB)
    }
}

struct GetTotalStorageIntent: AppIntent {
    static var title: LocalizedStringResource = "Almacenamiento total"
    static var description: IntentDescription = "Devuelve el almacenamiento total del dispositivo (en GB)"
    
    func perform() async throws -> some IntentResult & ReturnsValue<Double> {
        let storage = await DeviceCapabilities.getDeviceStorage()
        let totalGB = Double(storage.total) / 1_000_000_000
        return .result(value: totalGB)
    }
}


// MARK: - Network Intents (TEMPORARILY DISABLED - Testing which causes ExtractAppIntentsMetadata error)

/*
struct IsOnlineIntent: AppIntent {
    static var title: LocalizedStringResource = "¿Conectado a internet?"
    static var description: IntentDescription = "Verifica si hay conexión a internet"
    
    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        let isOnline = await DeviceCapabilities.isOnline()
        return .result(value: isOnline)
    }
}

struct GetConnectionTypeIntent: AppIntent {
    static var title: LocalizedStringResource = "Tipo de conexión"
    static var description: IntentDescription = "Devuelve si está en WiFi, datos móviles, o desconectado"
    
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let network = await DeviceCapabilities.getNetworkStatus()
        return .result(value: network.connectionType.rawValue)
    }
}
*/

// MARK: - Device State Intents (TEMPORARILY DISABLED - Testing which causes ExtractAppIntentsMetadata error)

/*
struct GetScreenBrightnessIntent: AppIntent {
    static var title: LocalizedStringResource = "Brillo de pantalla"
    static var description: IntentDescription = "Devuelve el nivel de brillo actual (0-100%)"
    
    func perform() async throws -> some IntentResult & ReturnsValue<Int> {
        let info = await DeviceCapabilities.getDeviceInfo()
        let brightness = Int(info.screenBrightness * 100)
        return .result(value: brightness)
    }
}

struct IsDarkModeOnIntent: AppIntent {
    static var title: LocalizedStringResource = "¿Modo oscuro?"
    static var description: IntentDescription = "Verifica si el modo oscuro está activado"
    
    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        let info = await DeviceCapabilities.getDeviceInfo()
        return .result(value: info.isDarkModeEnabled)
    }
}

struct HasNotchOrIslandIntent: AppIntent {
    static var title: LocalizedStringResource = "¿Tiene notch o isla dinámica?"
    static var description: IntentDescription = "Verifica si el dispositivo tiene notch o Dynamic Island"
    
    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        let state = await DeviceCapabilities.getDeviceState()
        return .result(value: state.hasNotchOrDynamicIsland)
    }
}
*/
