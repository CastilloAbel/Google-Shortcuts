import SwiftUI

/// Vista que muestra el histórico del portapapeles
struct ClipboardView: View {
    @StateObject private var clipboardService = ClipboardService.shared
    @State private var showConfirmClear = false
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - Header
                HStack {
                    Text("Portapapeles")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    // Botón limpiar histórico
                    if !clipboardService.history.isEmpty {
                        Button(action: { showConfirmClear = true }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
                .padding()
                
                Divider()
                
                // MARK: - Content
                if clipboardService.history.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.on.clipboard")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        
                        Text("Portapapeles vacío")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Los elementos que copies aparecerán aquí")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    List {
                        ForEach(clipboardService.history) { item in
                            ClipboardItemRow(item: item) {
                                clipboardService.copyToClipboard(item)
                            } onDelete: {
                                clipboardService.removeItem(item)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .confirmationDialog(
            "¿Limpiar histórico?",
            isPresented: $showConfirmClear,
            actions: {
                Button("Limpiar", role: .destructive) {
                    clipboardService.clearHistory()
                }
                Button("Cancelar", role: .cancel) {}
            },
            message: {
                Text("Se eliminarán todos los elementos del histórico del portapapeles.")
            }
        )
    }
}

/// Fila individual para un item del portapapeles
struct ClipboardItemRow: View {
    let item: ClipboardItem
    let onCopy: () -> Void
    let onDelete: () -> Void
    
    @State private var showDetail = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Ícono según tipo
                Image(systemName: typeIcon)
                    .foregroundColor(typeColor)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.displayText)
                        .font(.body)
                        .lineLimit(2)
                    
                    Text(item.relativeTime)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Botón copiar
                Button(action: onCopy) {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                showDetail = true
            }
        }
        .padding(.vertical, 8)
        .sheet(isPresented: $showDetail) {
            ClipboardDetailView(item: item, onCopy: onCopy)
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive, action: onDelete) {
                Label("Eliminar", systemImage: "trash")
            }
        }
    }
    
    private var typeIcon: String {
        switch item.type {
        case .text:
            return "doc.text"
        case .url:
            return "link"
        case .image:
            return "photo"
        case .unknown:
            return "questionmark.circle"
        }
    }
    
    private var typeColor: Color {
        switch item.type {
        case .text:
            return .blue
        case .url:
            return .purple
        case .image:
            return .green
        case .unknown:
            return .gray
        }
    }
}

/// Vista detallada de un item del portapapeles
struct ClipboardDetailView: View {
    let item: ClipboardItem
    let onCopy: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    // Tipo y tiempo
                    HStack {
                        Label(item.type.rawValue.capitalized, systemImage: typeIcon)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(item.timestamp.formatted(date: .abbreviated, time: .standard))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    
                    // Contenido
                    ScrollView {
                        Text(item.content)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    
                    Spacer()
                    
                    // Botón copiar
                    Button(action: {
                        onCopy()
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "doc.on.doc")
                            Text("Copiar")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
                .padding()
            }
            .navigationTitle("Detalles")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var typeIcon: String {
        switch item.type {
        case .text:
            return "doc.text"
        case .url:
            return "link"
        case .image:
            return "photo"
        case .unknown:
            return "questionmark.circle"
        }
    }
}

#Preview {
    ClipboardView()
}
