import SwiftUI

/// Vista de ajustes de la app.
///
/// Permite:
/// - Ver info de la cuenta conectada
/// - Configurar intervalo de polling
/// - Cerrar sesión
/// - Ver info sobre limitaciones y la app
struct SettingsView: View {
    
    @EnvironmentObject var authManager: OAuthManager
    @StateObject private var pollingService = MailPollingService.shared
    
    @State private var pollingIntervalMinutes: Double = 5
    @State private var showLogoutAlert = false
    
    var body: some View {
        NavigationStack {
            Form {
                // Cuenta
                Section("Cuenta Google") {
                    if let email = authManager.userEmail {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.blue)
                            VStack(alignment: .leading) {
                                Text(email)
                                    .font(.subheadline)
                                Text("Conectado")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                    
                    Button("Cerrar sesión", role: .destructive) {
                        showLogoutAlert = true
                    }
                }
                
                // Polling
                Section {
                    VStack(alignment: .leading) {
                        Text("Verificar cada \(Int(pollingIntervalMinutes)) minutos")
                        Slider(
                            value: $pollingIntervalMinutes,
                            in: 1...60,
                            step: 1
                        )
                        .onChange(of: pollingIntervalMinutes) { _, newValue in
                            pollingService.foregroundInterval = newValue * 60
                        }
                    }
                    
                    if let lastCheck = pollingService.lastCheckDate {
                        HStack {
                            Text("Última verificación")
                            Spacer()
                            Text(lastCheck, style: .relative)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Verificación de correos")
                } footer: {
                    Text("Solo funciona mientras la app está abierta. Para verificación automática, crea una automatización en Shortcuts.")
                }
                
                // Shortcuts Help
                Section("Usar con Shortcuts") {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Enviar correo", systemImage: "paperplane.fill")
                        Label("Consultar últimos correos", systemImage: "envelope.fill")
                        Label("Buscar correos", systemImage: "magnifyingglass")
                        Label("Verificar correos nuevos", systemImage: "bell.fill")
                        Label("Contar no leídos", systemImage: "envelope.badge")
                    }
                    .font(.subheadline)
                    
                    Text("Abre la app **Shortcuts**, crea un nuevo shortcut y busca \"GmailShortcuts\" para ver todas las acciones disponibles.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // Info
                Section("Información") {
                    HStack {
                        Text("Versión")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("iOS mínimo")
                        Spacer()
                        Text("16.0")
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Limitaciones
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        LimitationRow(
                            icon: "clock.badge.exclamationmark",
                            text: "La app se debe re-firmar cada 7 días con SideStore"
                        )
                        LimitationRow(
                            icon: "key.fill",
                            text: "Tus tokens de Google se mantienen al re-firmar"
                        )
                        LimitationRow(
                            icon: "bell.slash",
                            text: "Sin push notifications (usa polling o automatización en Shortcuts)"
                        )
                    }
                } header: {
                    Text("Limitaciones")
                } footer: {
                    Text("Esta app funciona con Apple ID gratuito. Algunas funciones de iOS requieren Developer Program pago.")
                }
            }
            .navigationTitle("Ajustes")
            .alert("¿Cerrar sesión?", isPresented: $showLogoutAlert) {
                Button("Cancelar", role: .cancel) {}
                Button("Cerrar sesión", role: .destructive) {
                    Task { await authManager.logout() }
                }
            } message: {
                Text("Deberás volver a iniciar sesión con Google para usar las funciones de Gmail.")
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
                .foregroundStyle(.orange)
                .frame(width: 20)
            Text(text)
                .font(.caption)
        }
    }
}
