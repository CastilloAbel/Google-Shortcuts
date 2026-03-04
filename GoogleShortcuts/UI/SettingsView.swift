import SwiftUI

struct SettingsView: View {
    @AppStorage("pollingEnabled") private var pollingEnabled = false
    @AppStorage("pollingIntervalMinutes") private var pollingIntervalMinutes = 5.0
    @AppStorage("notifyNewEmails") private var notifyNewEmails = true
    
    @State private var isAuthenticated = false
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - Account Section
                accountSection
                
                // MARK: - Polling Section
                pollingSection
                
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
