import SwiftUI

/// Vista principal de la app.
///
/// Muestra un TabView con:
/// - Tab 1: Gmail (requiere autenticación con Google)
/// - Tab 2: Device Actions (sin autenticación)
/// - Tab 3: Portapapeles (histórico de items copiados)
struct ContentView: View {
    
    @EnvironmentObject var authManager: OAuthManager
    
    @State private var selectedTab: Int = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // MARK: - Tab 1: Gmail
            Group {
                if authManager.isAuthenticated {
                    GmailTabView()
                } else {
                    AuthView()
                }
            }
            .tag(0)
            .tabItem {
                Label("Gmail", systemImage: "envelope.fill")
            }
            
            // MARK: - Tab 2: Device Actions
            DeviceActionsView()
                .tag(1)
                .tabItem {
                    Label("Dispositivo", systemImage: "iphone")
                }
            
            // MARK: - Tab 3: Portapapeles
            ClipboardView()
                .tag(2)
                .tabItem {
                    Label("Portapapeles", systemImage: "doc.on.clipboard")
                }
        }
        .animation(.easeInOut, value: authManager.isAuthenticated)
    }
}

/// Vista con contenido de Gmail (tabs de Inbox, Enviar, Ajustes).
struct GmailTabView: View {
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
                    HStack {
                        TextField("correo@ejemplo.com", text: $to)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                        
                        ClipboardButton { item in
                            to = item.content
                        }
                    }
                }
                
                Section("Mensaje") {
                    HStack {
                        TextField("Asunto", text: $subjectText)
                        
                        ClipboardButton { item in
                            subjectText = item.content
                        }
                    }
                    
                    HStack(alignment: .top) {
                        TextEditor(text: $bodyText)
                            .frame(minHeight: 150)
                        
                        VStack(spacing: 16) {
                            ClipboardButton { item in
                                bodyText = item.content
                            }
                            
                            Spacer()
                        }
                    }
                }
                
                Section {
                    Button(action: {
                        Task { sendEmail() }
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
