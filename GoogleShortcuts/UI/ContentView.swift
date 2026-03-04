import SwiftUI

/// Vista principal de la app.
///
/// Muestra:
/// - Estado de autenticación
/// - Si autenticado: vista de correos con tabs
/// - Si no autenticado: pantalla de login
struct ContentView: View {
    
    @EnvironmentObject var authManager: OAuthManager
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                MainTabView()
            } else {
                AuthView()
            }
        }
        .animation(.easeInOut, value: authManager.isAuthenticated)
    }
}

/// Vista con tabs para la navegación principal.
struct MainTabView: View {
    
    var body: some View {
        TabView {
            EmailListView()
                .tabItem {
                    Label("Inbox", systemImage: "envelope.fill")
                }
            
            SendEmailView()
                .tabItem {
                    Label("Enviar", systemImage: "paperplane.fill")
                }
            
            SettingsView()
                .tabItem {
                    Label("Ajustes", systemImage: "gear")
                }
        }
    }
}

/// Vista para enviar correos manualmente desde la app.
struct SendEmailView: View {
    
    @State private var to = ""
    @State private var subjectText = ""
    @State private var bodyText = ""
    @State private var isSending = false
    @State private var showResult = false
    @State private var resultMessage = ""
    @State private var isError = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Destinatario") {
                    TextField("correo@ejemplo.com", text: $to)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                }
                
                Section("Mensaje") {
                    TextField("Asunto", text: $subjectText)
                    
                    TextEditor(text: $bodyText)
                        .frame(minHeight: 150)
                }
                
                Section {
                    Button(action: {
                        Task { await sendEmail() }
                    }) {
                        HStack {
                            if isSending {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                            Text(isSending ? "Enviando..." : "Enviar correo")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(to.isEmpty || subjectText.isEmpty || isSending)
                }
            }
            .navigationTitle("Enviar correo")
            .alert(resultMessage, isPresented: $showResult) {
                Button("OK") {
                    if !isError {
                        clearForm()
                    }
                }
            }
        }
    }
    
    private func sendEmail() {
        isSending = true
        
        Task {
            do {
                let messageId = try await EmailService.shared.sendEmail(
                    to: to,
                    subject: subjectText,
                    body: bodyText
                )
                resultMessage = "✅ Correo enviado correctamente\nID: \(messageId)"
                isError = false
            } catch {
                resultMessage = "❌ Error: \(error.localizedDescription)"
                isError = true
            }
            
            isSending = false
            showResult = true
        }
    }
    
    private func clearForm() {
        to = ""
        subjectText = ""
        bodyText = ""
    }
}
