import Foundation
import Network

/// Wrapper thread-safe para resultados de red
private class NetworkCheckBox {
    private let lockQueue = DispatchQueue(label: "network.lock")
    private var _isOnline: Bool = false
    private var _connectionType: NetworkStatus.NetworkConnectionType = .unknown
    
    var isOnline: Bool {
        lockQueue.sync { _isOnline }
    }
    
    var connectionType: NetworkStatus.NetworkConnectionType {
        lockQueue.sync { _connectionType }
    }
    
    func setIsOnline(_ value: Bool) {
        lockQueue.async { [weak self] in
            self?._isOnline = value
        }
    }
    
    func setConnectionType(_ value: NetworkStatus.NetworkConnectionType) {
        lockQueue.async { [weak self] in
            self?._connectionType = value
        }
    }
}

/// Servicio para acceder a información de red
actor NetworkService {
    static let shared = NetworkService()
    
    private let monitor = NWPathMonitor()
    
    private init() {
        let queue = DispatchQueue(label: "network.monitor")
        monitor.start(queue: queue)
    }
    
    deinit {
        monitor.cancel()
    }
    
    /// Obtiene el estado actual de la red
    nonisolated func getStatus() -> NetworkStatus {
        return NetworkStatus(
            isOnline: isOnline(),
            connectionType: getConnectionType(),
            canReachHost: []  // Placeholder
        )
    }
    
    /// Verifica si hay conexión a internet (thread-safe para Swift 6)
    nonisolated func isOnline() -> Bool {
        let monitor = NWPathMonitor()
        let semaphore = DispatchSemaphore(value: 0)
        let box = NetworkCheckBox()
        
        let queue = DispatchQueue(label: "network.check")
        monitor.pathUpdateHandler = { [box] path in
            box.setIsOnline(path.status == .satisfied)
            semaphore.signal()
        }
        
        monitor.start(queue: queue)
        let _ = semaphore.wait(timeout: .now() + 1.0)
        monitor.cancel()
        
        return box.isOnline
    }
    
    /// Obtiene el tipo de conexión de red (thread-safe para Swift 6)
    nonisolated private func getConnectionType() -> NetworkStatus.NetworkConnectionType {
        let monitor = NWPathMonitor()
        let semaphore = DispatchSemaphore(value: 0)
        let box = NetworkCheckBox()
        
        let queue = DispatchQueue(label: "network.type")
        monitor.pathUpdateHandler = { [box] path in
            let type: NetworkStatus.NetworkConnectionType
            
            if path.usesInterfaceType(.wifi) {
                type = .wifi
            } else if path.usesInterfaceType(.cellular) {
                type = .cellular
            } else if path.status == .satisfied {
                type = .unknown
            } else {
                type = .unavailable
            }
            
            box.setConnectionType(type)
            semaphore.signal()
        }
        
        monitor.start(queue: queue)
        let _ = semaphore.wait(timeout: .now() + 1.0)
        monitor.cancel()
        
        return box.connectionType
    }
}
