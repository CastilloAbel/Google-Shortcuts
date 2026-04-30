import SwiftUI

struct SettingsView: View {
    @AppStorage("pollingEnabled") private var pollingEnabled = false
    @AppStorage("pollingIntervalMinutes") private var pollingIntervalMinutes = 5.0
    @AppStorage("notifyNewEmails") private var notifyNewEmails = true
    
    @State private var isAuthenticated = false
    @State private var locationPermissionStatus = "⏸️ No determinado"
    @State private var isRequestingLocation = false
    @StateObject private var locationTracker = LocationTracker()
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - Account Section
                accountSection
                
                // MARK: - Polling Section
                pollingSection
                
                // MARK: - Clipboard Section
                clipboardSection
                
                // MARK: - Shortcuts Section
                shortcutsSection
                
                // MARK: - Limitations Section
                limitationsSection
                
                // MARK: - About Section
                aboutSection
            }
            .navigationTitle("Ajustes")
            .onAppear {
                isAuthenticated = (try? TokenStorage.shared.loadTokens()) != nil
                locationPermissionStatus = PermissionManager.shared.getLocationPermissionStatus()
            }
            .onDisappear {
                // Refrescar estado cuando regresa de Ajustes del sistema
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    locationPermissionStatus = PermissionManager.shared.getLocationPermissionStatus()
                }
            }
        }
    }
    
    // MARK: - Sections
    
    private var accountSection: some View {
        Section("Cuenta") {
            if isAuthenticated {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Conectado con Google")
                }
                
                Button(role: .destructive) {
                    TokenStorage.shared.deleteTokens()
                    isAuthenticated = false
                } label: {
                    Label("Cerrar sesión", systemImage: "rectangle.portrait.and.arrow.right")
                }
            } else {
                HStack {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                    Text("No conectado")
                }
            }
        }
    }
    
    private var pollingSection: some View {
        Section("Verificación de correos") {
            Toggle("Verificación automática", isOn: $pollingEnabled)
            
            if pollingEnabled {
                HStack {
                    Text("Intervalo")
                    Spacer()
                    Picker("", selection: $pollingIntervalMinutes) {
                        Text("1 min").tag(1.0)
                        Text("5 min").tag(5.0)
                        Text("10 min").tag(10.0)
                        Text("15 min").tag(15.0)
                        Text("30 min").tag(30.0)
                    }
                    .pickerStyle(.menu)
                }
            }
            
            Toggle("Notificar nuevos correos", isOn: $notifyNewEmails)
        }
    }
    
    private var clipboardSection: some View {
        Section("Portapapeles automático + Test de Ubicación") {
            VStack(alignment: .leading, spacing: 12) {
                // MARK: - Estado de ubicación general
                HStack {
                    Text("Estado de permisos")
                    Spacer()
                    Text(locationPermissionStatus)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // MARK: - Test en vivo de ubicación
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        Image(systemName: "location.circle.fill")
                            .font(.title3)
                            .foregroundColor(locationTracker.location != nil ? .green : .gray)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Test de ubicación")
                                .font(.caption)
                                .fontWeight(.bold)
                            
                            Text(locationTracker.statusMessage)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if locationTracker.isUpdating {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(6)
                    
                    // Mostrar coordenadas si hay ubicación
                    if let location = locationTracker.location {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Latitud")
                                    .font(.caption)
                                Spacer()
                                Text(String(format: "%.4f", location.latitude))
                                    .font(.caption)
                                    .monospaced()
                            }
                            
                            HStack {
                                Text("Longitud")
                                    .font(.caption)
                                Spacer()
                                Text(String(format: "%.4f", location.longitude))
                                    .font(.caption)
                                    .monospaced()
                            }
                            
                            HStack {
                                Text("Precisión")
                                    .font(.caption)
                                Spacer()
                                Text(String(format: "%.0fm", locationTracker.accuracy))
                                    .font(.caption)
                            }
                        }
                        .padding(8)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(6)
                    } else {
                        Text("Sin ubicación recibida aún")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(8)
                    }
                }
                
                // MARK: - Botones de acción
                VStack(spacing: 8) {
                    Button(action: {
                        locationTracker.startTracking()
                    }) {
                        HStack {
                            Image(systemName: "location.fill")
                            Text("Probar obtener ubicación")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    
                    if locationTracker.isUpdating {
                        Button(action: {
                            locationTracker.stopTracking()
                        }) {
                            HStack {
                                Image(systemName: "stop.circle.fill")
                                Text("Detener")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .foregroundColor(.white)
                            .background(Color.red)
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        Link(destination: settingsURL) {
                            HStack {
                                Image(systemName: "gear")
                                Text("⚙️ Ajustes de la app")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .foregroundColor(.white)
                            .background(Color.green)
                            .cornerRadius(8)
                        }
                    }
                }
                
                // MARK: - Información
                VStack(alignment: .leading, spacing: 6) {
                    Text("❓ ¿Cómo funciona?")
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    Text("1️⃣ Toca 'Probar obtener ubicación'")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("2️⃣ Debería aparecer un popup pidiendo permisos")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("3️⃣ Si funciona, verás coordenadas abajo ✅")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("4️⃣ Si no funciona, ve a Ajustes > Ubicación > 'Always'")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    private var shortcutsSection: some View {
        Section("Shortcuts") {
            VStack(alignment: .leading, spacing: 8) {
                Label("Acciones disponibles", systemImage: "command")
                    .font(.headline)
                
                Text("• Enviar correo")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("• Consultar últimos correos")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("• Buscar correos")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
            
            Text("Abre la app Shortcuts y busca 'GoogleShortcuts' para usar estas acciones.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var limitationsSection: some View {
        Section("Limitaciones") {
            VStack(alignment: .leading, spacing: 6) {
                LimitationRow(
                    icon: "clock.badge.exclamationmark",
                    text: "La app expira cada 7 días (re-firmar con SideStore)"
                )
                LimitationRow(
                    icon: "bell.slash",
                    text: "Sin push notifications (se usa polling)"
                )
                LimitationRow(
                    icon: "arrow.clockwise",
                    text: "Verificación solo cuando la app está abierta"
                )
                LimitationRow(
                    icon: "key",
                    text: "Los tokens persisten al re-firmar"
                )
            }
            .padding(.vertical, 4)
        }
    }
    
    private var aboutSection: some View {
        Section("Acerca de") {
            HStack {
                Text("Versión")
                Spacer()
                Text("1.0.0")
                    .foregroundColor(.secondary)
            }
            HStack {
                Text("iOS mínimo")
                Spacer()
                Text("16.0")
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct LimitationRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.orange)
                .frame(width: 20)
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
