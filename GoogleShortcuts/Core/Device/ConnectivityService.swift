import Foundation
import CoreBluetooth
import NetworkExtension
import CoreTelephony
import Network

/// Servicio para acceder a información de conectividad
actor ConnectivityService {
    static let shared = ConnectivityService()
    
    private var bluetoothManager: CBCentralManager?
    private var bluetoothState: CBManagerState = .unknown
    
    private init() {
        // Inicializar Bluetooth manager
        bluetoothManager = CBCentralManager()
    }
    
    /// Obtiene el estado actual de conectividad
    nonisolated func getStatus() -> ConnectivityStatus {
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
    
    nonisolated func isBluetoothEnabled() -> Bool {
        // Nota: En iOS real, necesitarías NSBluetoothPeripheralUsageDescription
        // Por ahora, devolvemos una aproximación básica
        return true  // Placeholder - requiere CBCentralManager delegate
    }
    
    private nonisolated func getBluetoothStatus() -> Bool {
        // Requiere permisos y CBCentralManager setup completo
        // Por ahora, devolvemos estado desconocido
        return false  // Placeholder
    }
    
    // MARK: - WiFi
    
    nonisolated func isWiFiEnabled() -> Bool {
        let monitor = NWPathMonitor()
        defer { monitor.cancel() }
        
        let semaphore = DispatchSemaphore(value: 0)
        var result = false
        
        monitor.pathUpdateHandler = { path in
            result = path.usesInterfaceType(.wifi)
            semaphore.signal()
        }
        
        let queue = DispatchQueue(label: "wifi.check")
        monitor.start(queue: queue)
        let _ = semaphore.wait(timeout: .now() + 1.0)
        
        return result
    }
    
    private nonisolated func getWiFiStatus() -> Bool {
        isWiFiEnabled()
    }
    
    // MARK: - VPN
    
    func isVPNConnected() -> Bool {
        let vpnConfiguration = NEVPNManager.shared().loadFromPreferences { [weak self] error in
            if error != nil {
                return
            }
        }
        
        return NEVPNManager.shared().connection.status == .connected
    }
    
    private nonisolated func getVPNStatus() -> Bool {
        NEVPNManager.shared().connection.status == .connected
    }
    
    // MARK: - Cellular Data
    
    private nonisolated func getCellularDataStatus() -> Bool {
        // CTCellularData solo permite saber restric state, NO si está activo
        let cellularData = CTCellularData()
        let restrictedState = cellularData.restrictedStateForCellularData
        
        // Si está restringido, está desactivo
        return restrictedState != .restricted
    }
    
    private nonisolated func isLowDataModeEnabled() -> Bool {
        // Disponible en iOS 13+
        return URLSessionConfiguration.default.waitsForConnectivity
    }
    
    // MARK: - Cellular Technology
    
    private nonisolated func getActiveCellularTechnology() -> ConnectivityStatus.CellularTechnology? {
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
