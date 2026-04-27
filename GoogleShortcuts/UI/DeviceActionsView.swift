import SwiftUI

/// Vista que muestra los atajos del dispositivo disponibles.
/// No requiere autenticación con Google.
struct DeviceActionsView: View {
    
    var body: some View {
        NavigationStack {
            List {
                // MARK: - Battery Section
                Section("🔋 Batería") {
                    DeviceActionItem(
                        title: "Nivel de Batería",
                        description: "Obtiene el porcentaje actual de batería del dispositivo",
                        icon: "battery.50percent",
                        color: .yellow
                    )
                    
                    DeviceActionItem(
                        title: "¿Batería Baja?",
                        description: "Verifica si la batería está por debajo del 20%",
                        icon: "battery.25percent",
                        color: .red
                    )
                    
                    DeviceActionItem(
                        title: "Modo Bajo Consumo",
                        description: "Verifica si el modo batería está activado",
                        icon: "battery.25percent.circle",
                        color: .orange
                    )
                }
                
                // MARK: - Connectivity Section
                Section("📡 Conectividad") {
                    DeviceActionItem(
                        title: "¿Bluetooth Encendido?",
                        description: "Verifica si Bluetooth está habilitado",
                        icon: "bluetooth.circle",
                        color: .blue
                    )
                    
                    DeviceActionItem(
                        title: "¿WiFi Encendido?",
                        description: "Verifica si WiFi está conectado",
                        icon: "wifi",
                        color: .blue
                    )
                }
                
                // MARK: - Device Info Section (Coming Soon)
                Section("ℹ️ Información del Dispositivo") {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Modelo del Dispositivo", systemImage: "iphone")
                        Text("Obtendrá el modelo de tu iPhone")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Versión de iOS", systemImage: "info.circle")
                        Text("Obtendrá la versión actual de iOS")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                
                // MARK: - Note
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Cómo Usar", systemImage: "questionmark.circle")
                            .font(.caption.bold())
                        
                        Text("1. Abre la app Shortcuts\n2. Crea un atajo nuevo\n3. Busca las acciones de Google Shortcuts\n4. Arrastra las acciones que necesites\n5. Personaliza según tus necesidades")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Atajos del Dispositivo")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

/// Componente que muestra la información de una acción de dispositivo.
struct DeviceActionItem: View {
    
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                    .frame(width: 32, alignment: .center)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body.bold())
                    
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    DeviceActionsView()
}
