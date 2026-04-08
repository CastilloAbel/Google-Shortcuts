import SwiftUI

/// Vista de autenticación con Google.
///
/// Permite al usuario:
/// 1. Conectar con Google para usar atajos de Gmail
/// 2. Omitir autenticación para usar atajos de dispositivo
struct AuthView: View {
    
    @EnvironmentObject var authManager: OAuthManager
    
    @State private var showDeviceActions = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Fondo en modo oscuro/claro
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        Spacer()
                            .frame(height: 16)
                        
                        // Logo / icono
                        Image(systemName: "envelope.badge.shield.half.filled")
                            .font(.system(size: 60))
                            .foregroundStyle(.blue, .gray)
                        
                        // Título
                        VStack(spacing: 6) {
                            Text("Google Shortcuts")
                                .font(.title3.bold())
                            
                            Text("Automatiza Gmail y tu dispositivo")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                        .multilineTextAlignment(.center)
                        
                        Spacer()
                            .frame(height: 12)
                        
                        // Sección: Atajos de Gmail
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Atajos Gmail", systemImage: "mail.fill")
                                .font(.caption.bold())
                                .foregroundStyle(.blue)
                            
                            PermissionRow(
                                icon: "paperplane.fill",
                                text: "Enviar correos",
                                color: .blue
                            )
                            PermissionRow(
                                icon: "envelope.open.fill",
                                text: "Leer correos",
                                color: .green
                            )
                            PermissionRow(
                                icon: "magnifyingglass",
                                text: "Buscar correos",
                                color: .orange
                            )
                            PermissionRow(
                                icon: "bell.fill",
                                text: "Verificar nuevos",
                                color: .purple
                            )
                        }
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        Spacer()
                            .frame(height: 8)
                        
                        // Sección: Atajos de Dispositivo
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Atajos del Dispositivo", systemImage: "iphone")
                                .font(.caption.bold())
                                .foregroundStyle(.green)
                            
                            PermissionRow(
                                icon: "battery.50percent",
                                text: "Nivel de batería",
                                color: .green
                            )
                            PermissionRow(
                                icon: "bluetooth",
                                text: "Estado Bluetooth/WiFi",
                                color: .blue
                            )
                            PermissionRow(
                                icon: "iphone.gen3",
                                text: "Info del dispositivo",
                                color: .orange
                            )
                        }
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        Spacer()
                            .frame(height: 16)
                        
                        // Botones de acción
                        VStack(spacing: 12) {
                            // Conectar con Google
                            Button(action: { authManager.startLogin() }) {
                                HStack(spacing: 10) {
                                    if authManager.isLoading {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Image(systemName: "person.badge.key.fill")
                                    }
                                    Text(authManager.isLoading ? "Conectando..." : "Conectar con Google")
                                        .font(.system(.body, design: .rounded))
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(12)
                                .background(authManager.isLoading ? Color.gray : Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .disabled(authManager.isLoading)
                            
                            // Omitir - Usar solo atajos de dispositivo
                            Button(action: { showDeviceActions = true }) {
                                HStack(spacing: 10) {
                                    Image(systemName: "arrow.right.circle")
                                    Text("Usar Atajos del Dispositivo")
                                        .font(.system(.body, design: .rounded))
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(12)
                                .background(Color(.systemGray6))
                                .foregroundColor(.primary)
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Error message
                        if let error = authManager.error {
                            Text(error)
                                .font(.caption2)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(12)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                                .padding(.horizontal)
                        }
                        
                        // Nota legal
                        Text("Los datos se guardan localmente en tu dispositivo. No se envía información a servidores externos.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                        
                        Spacer()
                            .frame(height: 20)
                    }
                    .padding(.horizontal, 16)
                }
            }
            .navigationDestination(isPresented: $showDeviceActions) {
                DeviceActionsView()
                    .navigationBarBackButtonHidden(false)
            }
        }
    }
}

/// Fila de permiso individual.
struct PermissionRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(text)
                .font(.subheadline)
            
            Spacer()
        }
    }
}
