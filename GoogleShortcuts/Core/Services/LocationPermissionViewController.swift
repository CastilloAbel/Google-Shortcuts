import SwiftUI
import CoreLocation

/// UIViewControllerRepresentable para solicitar permiso de ubicación
/// Esto es más confiable que hacerlo directamente desde SwiftUI
struct LocationPermissionViewController: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        return UIViewController()
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Solicitar el permiso desde el UIViewController
        let locationManager = CLLocationManager()
        locationManager.delegate = context.coordinator
        locationManager.requestWhenInUseAuthorization()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, CLLocationManagerDelegate {
        // Delegate methods if needed
    }
}

/// Vista invisible para solicitar permisos de ubicación
struct LocationPermissionTrigger: View {
    @State private var showController = false
    
    var body: some View {
        if showController {
            LocationPermissionViewController()
                .frame(height: 0)
                .hidden()
        }
    }
}
