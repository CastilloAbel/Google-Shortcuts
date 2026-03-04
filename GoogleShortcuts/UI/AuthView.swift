import SwiftUI

/// Vista de autenticación con Google.
///
/// Muestra un botón para iniciar el flujo OAuth2.
/// También explica los permisos necesarios al usuario.
struct AuthView: View {
    
    @EnvironmentObject var authManager: OAuthManager
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()
                
                // Logo / icono
                Image(systemName: "envelope.badge.shield.half.filled")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue, .gray)
                
                // Título
                VStack(spacing: 8) {
                    Text("GmailShortcuts")
                        .font(.largeTitle.bold())
                    
                    Text("Automatiza Gmail desde Shortcuts")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                // Permisos
                VStack(alignment: .leading, spacing: 12) {
                    PermissionRow(
                        icon: "paperplane.fill",
                        text: "Enviar correos desde Shortcuts",
                        color: .blue
                    )
                    PermissionRow(
                        icon: "envelope.open.fill",
                        text: "Leer tus correos recientes",
                        color: .green
                    )
                    PermissionRow(
                        icon: "magnifyingglass",
                        text: "Buscar correos por asunto",
                        color: .orange
                    )
                    PermissionRow(
                        icon: "bell.fill",
                        text: "Verificar correos nuevos",
                        color: .purple
                    )
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
                .padding(.horizontal)
                
                Spacer()
                
                // Botón de Login
                Button(action: { authManager.startLogin() }) {
                    HStack(spacing: 12) {
                        if authManager.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "person.badge.key.fill")
                        }
                        Text(authManager.isLoading ? "Conectando..." : "Conectar con Google")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(authManager.isLoading ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(14)
                }
                .disabled(authManager.isLoading)
                .padding(.horizontal, 24)
                
                // Error
                if let error = authManager.error {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Nota legal
                Text("Solo se accede a tu Gmail. Los datos se guardan localmente en tu dispositivo.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                Spacer()
                    .frame(height: 20)
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
