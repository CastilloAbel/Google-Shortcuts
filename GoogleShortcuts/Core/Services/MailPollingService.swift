import Foundation

/// Servicio de polling para detectar nuevos correos.
///
/// ## ¿Por qué polling y no push?
///
/// Las Push Notifications de Apple (APNs) requieren:
/// 1. Apple Developer Program pago ($99/año)
/// 2. Certificado de push notification
/// 3. aps-environment entitlement (no disponible con cuenta gratuita)
/// 4. Un servidor backend que reciba webhooks de Gmail y envíe pushes
///
/// ### Alternativa: Background App Refresh + Polling
///
/// iOS permite `UIBackgroundModes: fetch` sin cuenta paga.
/// El sistema decide cuándo despertar la app (típicamente cada 15-60 min).
/// Cuando despierta, verificamos si hay correos nuevos y mostramos
/// una notificación local (que SÍ funciona sin cuenta paga).
///
/// ### Limitaciones del polling:
/// - No es instantáneo (retraso de 15-60 minutos)
/// - iOS puede reducir frecuencia si el usuario no abre la app
/// - Consume algo de batería (mínimo)
/// - No funciona si la app está cerrada por completo
///
/// ### Alternativa complementaria: Shortcuts Automation
/// El usuario puede crear una automatización en Shortcuts que:
/// 1. Se ejecute cada X minutos (usando "Automation > Time of Day")
/// 2. Llame a nuestro App Intent "Check New Emails"
/// 3. Muestre una notificación si hay correos nuevos
/// Esta es la alternativa MÁS confiable sin push notifications.
@MainActor
class MailPollingService: ObservableObject {
    
    static let shared = MailPollingService()
    
    // MARK: - Published State
    
    @Published var lastCheckDate: Date?
    @Published var newEmailCount: Int = 0
    @Published var isPolling: Bool = false
    
    // MARK: - Configuration
    
    /// Intervalo mínimo entre checks (en segundos).
    /// En foreground se puede verificar más frecuentemente.
    var foregroundInterval: TimeInterval = 300 // 5 minutos
    
    /// Timer para polling en foreground.
    private var foregroundTimer: Timer?
    
    /// Último historyId conocido (para detectar cambios).
    private var lastKnownHistoryId: String? {
        get { UserDefaults.standard.string(forKey: "lastKnownHistoryId") }
        set { UserDefaults.standard.set(newValue, forKey: "lastKnownHistoryId") }
    }
    
    /// IDs de mensajes ya notificados (evitar duplicados).
    private var notifiedMessageIds: Set<String> {
        get {
            Set(UserDefaults.standard.stringArray(forKey: "notifiedMessageIds") ?? [])
        }
        set {
            // Mantener solo los últimos 100 IDs
            let limited = Array(newValue.suffix(100))
            UserDefaults.standard.set(limited, forKey: "notifiedMessageIds")
        }
    }
    
    private init() {}
    
    // MARK: - Foreground Polling
    
    /// Inicia el polling cuando la app está en foreground.
    func startForegroundPolling() {
        stopForegroundPolling()
        
        foregroundTimer = Timer.scheduledTimer(
            withTimeInterval: foregroundInterval,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.checkForNewEmails()
            }
        }
        
        // Check inmediato
        Task {
            await checkForNewEmails()
        }
    }
    
    /// Detiene el polling de foreground.
    func stopForegroundPolling() {
        foregroundTimer?.invalidate()
        foregroundTimer = nil
    }
    
    // MARK: - Check for New Emails
    
    /// Verifica si hay correos nuevos desde el último check.
    ///
    /// - Returns: Array de emails nuevos encontrados
    @discardableResult
    func checkForNewEmails() async -> [Email] {
        guard !isPolling else { return [] }
        
        isPolling = true
        defer {
            isPolling = false
            lastCheckDate = Date()
        }
        
        do {
            let newEmails = try await EmailService.shared.checkNewEmails()
            
            // Filtrar los que ya fueron notificados
            let trulyNew = newEmails.filter { !notifiedMessageIds.contains($0.id) }
            
            newEmailCount = trulyNew.count
            
            // Mostrar notificación local si hay nuevos
            if !trulyNew.isEmpty {
                await showLocalNotification(for: trulyNew)
                
                // Marcar como notificados
                var ids = notifiedMessageIds
                for email in trulyNew {
                    ids.insert(email.id)
                }
                notifiedMessageIds = ids
            }
            
            return trulyNew
        } catch {
            print("Error checking new emails: \(error)")
            return []
        }
    }
    
    // MARK: - Local Notifications
    
    /// Muestra una notificación local para los correos nuevos.
    ///
    /// Las notificaciones locales SÍ funcionan con cuenta Apple gratuita.
    /// No requieren APNs ni entitlements especiales.
    private func showLocalNotification(for emails: [Email]) async {
        let center = UNUserNotificationCenter.current()
        
        // Solicitar permiso (solo la primera vez)
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        guard granted else { return }
        
        if emails.count == 1, let email = emails.first {
            // Notificación individual
            let content = UNMutableNotificationContent()
            content.title = email.senderName
            content.subtitle = email.subject
            content.body = email.snippet
            content.sound = .default
            
            let request = UNNotificationRequest(
                identifier: "email_\(email.id)",
                content: content,
                trigger: nil // Inmediata
            )
            
            try? await center.add(request)
        } else {
            // Notificación agrupada
            let content = UNMutableNotificationContent()
            content.title = "Nuevos correos"
            content.body = "Tienes \(emails.count) correos nuevos sin leer"
            content.sound = .default
            
            let request = UNNotificationRequest(
                identifier: "emails_batch_\(Date().timeIntervalSince1970)",
                content: content,
                trigger: nil
            )
            
            try? await center.add(request)
        }
    }
    
    // MARK: - Background Fetch Support
    
    /// Método para ser llamado desde el background fetch del sistema.
    /// Se configura en el AppDelegate / SceneDelegate.
    ///
    /// Para activar background fetch con cuenta gratuita:
    /// 1. Agregar `fetch` en UIBackgroundModes del Info.plist ✅
    /// 2. Configurar intervalo mínimo en `application(_:didFinishLaunchingWithOptions:)`:
    ///    `UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)`
    ///
    /// NOTA: iOS decide CUÁNDO ejecutar el fetch. No hay garantía de intervalo.
    func performBackgroundFetch() async -> Bool {
        let newEmails = await checkForNewEmails()
        return !newEmails.isEmpty
    }
}

// Importar UserNotifications
import UserNotifications
