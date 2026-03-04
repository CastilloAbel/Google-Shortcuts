import SwiftUI

/// Vista de lista de correos del inbox.
///
/// Muestra los correos más recientes con pull-to-refresh
/// y búsqueda integrada.
struct EmailListView: View {
    
    @State private var emails: [Email] = []
    @State private var isLoading = false
    @State private var error: String?
    @State private var searchText = ""
    @State private var selectedEmail: Email?
    
    @StateObject private var pollingService = MailPollingService.shared
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading && emails.isEmpty {
                    ProgressView("Cargando correos...")
                } else if let error = error, emails.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text(error)
                            .multilineTextAlignment(.center)
                        Button("Reintentar") { loadEmails() }
                    }
                    .padding()
                } else {
                    emailList
                }
            }
            .navigationTitle("Inbox")
            .searchable(text: $searchText, prompt: "Buscar correos...")
            .onSubmit(of: .search) { searchEmails() }
            .refreshable { await refreshEmails() }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if pollingService.isPolling {
                        ProgressView()
                    } else {
                        Button(action: loadEmails) {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    if pollingService.newEmailCount > 0 {
                        Text("\(pollingService.newEmailCount) nuevos")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            }
            .sheet(item: $selectedEmail) { email in
                EmailDetailView(email: email)
            }
        }
        .onAppear {
            loadEmails()
            pollingService.startForegroundPolling()
        }
        .onDisappear {
            pollingService.stopForegroundPolling()
        }
    }
    
    // MARK: - Email List
    
    private var emailList: some View {
        List(filteredEmails) { email in
            EmailRow(email: email)
                .onTapGesture {
                    selectedEmail = email
                }
        }
        .listStyle(.plain)
        .overlay {
            if filteredEmails.isEmpty && !searchText.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text("No se encontraron resultados para \"\(searchText)\"")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                .padding()
            }
        }
    }
    
    private var filteredEmails: [Email] {
        if searchText.isEmpty {
            return emails
        }
        return emails.filter { email in
            email.subject.localizedCaseInsensitiveContains(searchText) ||
            email.from.localizedCaseInsensitiveContains(searchText) ||
            email.snippet.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    // MARK: - Data Loading
    
    private func loadEmails() {
        isLoading = true
        error = nil
        
        Task {
            do {
                emails = try await EmailService.shared.getRecentEmails(forceRefresh: true)
            } catch {
                self.error = error.localizedDescription
            }
            isLoading = false
        }
    }
    
    private func refreshEmails() async {
        do {
            emails = try await EmailService.shared.getRecentEmails(forceRefresh: true)
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    private func searchEmails() {
        guard !searchText.isEmpty else { return }
        
        isLoading = true
        Task {
            do {
                emails = try await EmailService.shared.search(query: searchText)
            } catch {
                self.error = error.localizedDescription
            }
            isLoading = false
        }
    }
}

// MARK: - Email Row

struct EmailRow: View {
    let email: Email
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                if email.isUnread {
                    Circle()
                        .fill(.blue)
                        .frame(width: 8, height: 8)
                }
                
                Text(email.senderName)
                    .font(.headline)
                    .fontWeight(email.isUnread ? .bold : .regular)
                    .lineLimit(1)
                
                Spacer()
                
                Text(email.formattedDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text(email.subject)
                .font(.subheadline)
                .fontWeight(email.isUnread ? .semibold : .regular)
                .lineLimit(1)
            
            Text(email.snippet)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Email Detail

struct EmailDetailView: View {
    let email: Email
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(email.subject)
                            .font(.title2.bold())
                        
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .foregroundStyle(.blue)
                            VStack(alignment: .leading) {
                                Text(email.senderName)
                                    .font(.subheadline.bold())
                                Text(email.from)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        HStack {
                            Image(systemName: "clock")
                                .foregroundStyle(.secondary)
                            Text(email.formattedDate)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Divider()
                    
                    // Body
                    Text(email.body.isEmpty ? email.snippet : email.body)
                        .font(.body)
                        .textSelection(.enabled)
                }
                .padding()
            }
            .navigationTitle("Detalle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
    }
}
