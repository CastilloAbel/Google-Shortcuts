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
        ZStack {
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
            .liquidGlassTabBar()
            .animation(.easeInOut, value: authManager.isAuthenticated)
            .onAppear {
                // Solicitar únicamente permiso de ubicación (para portapapeles automático)
                // Las notificaciones se pueden agregar después si son necesarias
                PermissionManager.shared.requestAllPermissions()
                // Inicializar servicio de portapapeles
                ClipboardService.shared.initializeService()
            }
        }
    }
}

/// Vista con contenido de Gmail (pestañas de Inbox, Enviar, Ajustes con swipe).
struct GmailTabView: View {
    @State private var selectedGmailTab: GmailTab = .inbox
    
    var body: some View {
        ZStack {
            // MARK: - Contenido con transición suave
            Group {
                switch selectedGmailTab {
                case .inbox:
                    EmailListView()
                        .transition(.opacity)
                
                case .send:
                    SendEmailView()
                        .transition(.opacity)
                
                case .settings:
                    SettingsView()
                        .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // MARK: - Selector de pestañas (Segmented Picker tipo iOS Music)
            VStack {
                HStack(spacing: 0) {
                    ForEach(GmailTab.allCases, id: \.self) { tab in
                        VStack(spacing: 4) {
                            Label(tab.label, systemImage: tab.icon)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(selectedGmailTab == tab ? .blue : .gray)
                            
                            if selectedGmailTab == tab {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.blue)
                                    .frame(height: 3)
                                    .transition(.scale)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedGmailTab = tab
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 4)
                .background(Color(.systemBackground))
                
                Divider()
                
                Spacer()
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .navigationTitle("Gmail")
    }
}

// MARK: - Enum para las pestañas de Gmail
enum GmailTab: CaseIterable, Hashable {
    case inbox
    case send
    case settings
    
    var label: String {
        switch self {
        case .inbox: return "Inbox"
        case .send: return "Enviar"
        case .settings: return "Ajustes"
        }
    }
    
    var icon: String {
        switch self {
        case .inbox: return "envelope.fill"
        case .send: return "paperplane.fill"
        case .settings: return "gear"
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
