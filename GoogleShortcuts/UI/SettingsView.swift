import SwiftUI

struct SettingsView: View {
    @AppStorage("pollingEnabled") private var pollingEnabled = false
    @AppStorage("pollingIntervalMinutes") private var pollingIntervalMinutes = 5.0
    @AppStorage("notifyNewEmails") private var notifyNewEmails = true
    
    @State private var isAuthenticated = false
    @State private var locationPermissionStatus = "⏸️ No determinado"
    @State private var isRequestingLocation = false
    
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
        Section("Portapapeles automático") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Estado de ubicación")
                    Spacer()
                    if isRequestingLocation {
                        HStack(spacing: 4) {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Solicitando...")
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    } else {
                        Text(locationPermissionStatus)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if !isRequestingLocation {
                    Button(action: {
                        isRequestingLocation = true
                        print("🔔 [SettingsView] Usuario tocó el botón de ubicación")
                        
                        PermissionManager.shared.requestLocationPermissionManually()
                        
                        // Actualizar estado después de delays progresivos
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            locationPermissionStatus = PermissionManager.shared.getLocationPermissionStatus()
                            print("🔔 [SettingsView] Estado actualizado: \(locationPermissionStatus)")
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            isRequestingLocation = false
                        }
                    }) {
                        HStack {
                            Image(systemName: "location.fill")
                            Text("Habilitar ubicación en segundo plano")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("¿Por qué es necesario?")
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    Text("La app necesita acceso a tu ubicación para mantener activo el monitoreo automático del portapapeles en segundo plano. Tu ubicación nunca se guarda ni se comparte.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\n📌 Si no aparece el popup: Ve a Ajustes del sistema > Google Shortcuts > Ubicación > Selecciona 'Always'")
                        .font(.caption2)
                        .foregroundColor(.orange)
                    
                    // Botón para abrir Ajustes del sistema
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        Link("⚙️ Abrir Ajustes", destination: settingsURL)
                            .font(.caption2)
                            .foregroundColor(.blue)
                            .padding(.top, 4)
                    }
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
