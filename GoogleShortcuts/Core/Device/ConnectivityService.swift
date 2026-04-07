import Foundation
import CoreBluetooth
import NetworkExtension
import CoreTelephony
import Network

/// Wrapper thread-safe para resultados de conectividad
private class ConnectivityCheckBox {
    private let lockQueue = DispatchQueue(label: "connectivity.lock")
    private var _wiFiConnected: Bool = false
    
    var wiFiConnected: Bool {
        lockQueue.sync { _wiFiConnected }
    }
    
    func setWiFiConnected(_ value: Bool) {
        lockQueue.async { [weak self] in
            self?._wiFiConnected = value
        }
    }
}

/// Servicio para acceder a información de conectividad
@MainActor
final class ConnectivityService {
    static let shared = ConnectivityService()
    
    private var bluetoothManager: CBCentralManager?
    private var bluetoothState: CBManagerState = .unknown
    
    private init() {
        // Inicializar Bluetooth manager
        bluetoothManager = CBCentralManager()
    }
    
    /// Obtiene el estado actual de conectividad
    func getStatus() -> ConnectivityStatus {
        return ConnectivityStatus(
            isBluetoothOn: getBluetoothStatus(),
            isWiFiOn: getWiFiStatus(),
            isVPNConnected: getVPNStatus(),
            isCellularDataOn: getCellularDataStatus(),
            isLowDataModeOn: isLowDataModeEnabled(),
            activeCellularTechnology: getActiveCellularTechnology()
        )
    }
    
    // MARK: - Bluetooth
    
    func isBluetoothEnabled() -> Bool {
        // Nota: En iOS real, necesitarías NSBluetoothPeripheralUsageDescription
        // Por ahora, devolvemos una aproximación básica
        return true  // Placeholder - requiere CBCentralManager delegate
    }
    
    private func getBluetoothStatus() -> Bool {
        // Requiere permisos y CBCentralManager setup completo
        // Por ahora, devolvemos estado desconocido
        return false  // Placeholder
    }
    
    // MARK: - WiFi
    
    func isWiFiEnabled() -> Bool {
        let monitor = NWPathMonitor()
        let semaphore = DispatchSemaphore(value: 0)
        let box = ConnectivityCheckBox()
        
        let queue = DispatchQueue(label: "wifi.check")
        monitor.pathUpdateHandler = { [box] path in
            box.setWiFiConnected(path.usesInterfaceType(.wifi))
            semaphore.signal()
        }
        
        monitor.start(queue: queue)
        let _ = semaphore.wait(timeout: .now() + 1.0)
        monitor.cancel()
        
        return box.wiFiConnected
    }
    
    private func getWiFiStatus() -> Bool {
        isWiFiEnabled()
    }
    
    // MARK: - VPN
    
    func isVPNConnected() -> Bool {
        NEVPNManager.shared().loadFromPreferences { _ in }
        return NEVPNManager.shared().connection.status == .connected
    }
    
    private func getVPNStatus() -> Bool {
        NEVPNManager.shared().connection.status == .connected
    }
    
    // MARK: - Cellular Data
    
    private func getCellularDataStatus() -> Bool {
        // CTCellularData solo permite saber restric state, NO si está activo
        let cellularData = CTCellularData()
        // En iOS, si CellularDataRestrictionDidChangeNotification no está activo,
        // asumimos que los datos celulares están disponibles
        return true  // Simplificar: asumir disponible si no está explícitamente restringido
    }
    
    private func isLowDataModeEnabled() -> Bool {
        // Disponible en iOS 13+
        return URLSessionConfiguration.default.waitsForConnectivity
    }
    
    // MARK: - Cellular Technology
    
    private func getActiveCellularTechnology() -> ConnectivityStatus.CellularTechnology? {
        let networkInfo = CTTelephonyNetworkInfo()
        guard let currentRadio = networkInfo.serviceCurrentRadioAccessTechnology?.values.first else {
            return nil
        }
        
        // Mapear CTRadioAccessTechnologyXXX a nuestro enum
        // Disponibles en iOS: 2G, 3G, 4G (LTE), 5G
        if #available(iOS 14.1, *) {
            if currentRadio == CTRadioAccessTechnologyNR || currentRadio == CTRadioAccessTechnologyNRNSA {
                return .nrNSA  // Placeholder para lo disponible
            }
        }
        
        if currentRadio == CTRadioAccessTechnologyLTE {
            return .lte
        }
        
        if #available(iOS 14.1, *) {
            if currentRadio == CTRadioAccessTechnologyHSDPA ||
               currentRadio == CTRadioAccessTechnologyHSUPA ||
               currentRadio == CTRadioAccessTechnologyWCDMA {
                return .hsdpa
            }
        }
        
        return .unknown
    }
}
