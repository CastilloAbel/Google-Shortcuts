import Foundation
import Network

/// Servicio para acceder a información de red
actor NetworkService {
    static let shared = NetworkService()
    
    private let monitor = NWPathMonitor()
    private var isOnlineValue = false
    
    private init() {
        let queue = DispatchQueue(label: "network.monitor")
        monitor.start(queue: queue)
        
        monitor.pathUpdateHandler = { [weak self] path in
            self?.isOnlineValue = path.status == .satisfied
        }
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
    
    /// Verifica si hay conexión a internet
    nonisolated func isOnline() -> Bool {
        let monitor = NWPathMonitor()
        let semaphore = DispatchSemaphore(value: 0)
        var result = false
        
        monitor.pathUpdateHandler = { path in
            result = path.status == .satisfied
            semaphore.signal()
        }
        
        let queue = DispatchQueue(label: "network.check")
        monitor.start(queue: queue)
        let _ = semaphore.wait(timeout: .now() + 1.0)
        monitor.cancel()
        
        return result
    }
    
    /// Obtiene el tipo de conexión de red
    nonisolated private func getConnectionType() -> NetworkStatus.NetworkConnectionType {
        let monitor = NWPathMonitor()
        let semaphore = DispatchSemaphore(value: 0)
        var result: NetworkStatus.NetworkConnectionType = .unknown
        
        monitor.pathUpdateHandler = { path in
            if path.usesInterfaceType(.wifi) {
                result = .wifi
            } else if path.usesInterfaceType(.cellular) {
                result = .cellular
            } else if path.status == .satisfied {
                result = .unknown
            } else {
                result = .unavailable
            }
            semaphore.signal()
        }
        
        let queue = DispatchQueue(label: "network.type")
        monitor.start(queue: queue)
        let _ = semaphore.wait(timeout: .now() + 1.0)
        monitor.cancel()
        
        return result
    }
}
