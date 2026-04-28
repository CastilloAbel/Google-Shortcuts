import SwiftUI
import Foundation

/// Vista que muestra el histórico del portapapeles  
struct ClipboardView: View {
    @State private var showConfirmClear = false
    // Observar cambios en el singleton sin crear duplicados
    @StateObject private var observedService = ClipboardService.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header
            HStack {
                Text("Portapapeles")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                // Botón refresh (capturar del portapapeles)
                Button(action: {
                    observedService.captureCurrentClipboard()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.blue)
                }
                
                // Botón limpiar histórico
                if !observedService.history.isEmpty {
                    Button(action: { showConfirmClear = true }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
            }
            .padding()
            
            Divider()
            
            // MARK: - Content
            if observedService.history.isEmpty {
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
                    ForEach(observedService.history) { item in
                        ClipboardItemRow(
                            item: item,
                            onCopy: {
                                observedService.copyToClipboard(item)
                            },
                            onDelete: {
                                observedService.removeItem(item)
                            }
                        )
                    }
                }
                .listStyle(.plain)
            }
        }
        .confirmationDialog(
            "¿Limpiar histórico?",
            isPresented: $showConfirmClear,
            actions: {
                Button("Limpiar", role: .destructive) {
                    observedService.clearHistory()
                }
                Button("Cancelar", role: .cancel) {}
            },
            message: {
                Text("Se eliminarán todos los elementos del histórico del portapapeles.")
            }
        )
    }
}

/// Fila individual para un item del portapapeles con soporte de imágenes
struct ClipboardItemRow: View {
    let item: ClipboardItem
    let onCopy: () -> Void
    let onDelete: () -> Void
    
    @State private var showDetail = false
    @State private var showImageMenu = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Si es una imagen, mostrar preview
            if item.type == .image, let image = ClipboardService.shared.getImage(from: item) {
                ZStack(alignment: .topTrailing) {
                    // Imagen con tap para abrir menu
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 150)
                        .clipped()
                        .cornerRadius(8)
                        .onTapGesture {
                            showImageMenu = true
                        }
                    
                    // Badge con fecha y delete button
                    VStack(alignment: .trailing, spacing: 4) {
                        Button(action: onDelete) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.red)
                                .background(
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 22, height: 22)
                                )
                        }
                        
                        Text(item.relativeTime)
                            .font(.caption2)
                            .foregroundColor(.white)
                            .shadow(radius: 2)
                    }
                    .padding(8)
                }
                
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Imagen", systemImage: "photo.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Menu {
                        Button(action: onCopy) {
                            Label("Copiar", systemImage: "doc.on.doc")
                        }
                        
                        Button(action: { shareImage(image) }) {
                            Label("Compartir", systemImage: "square.and.arrow.up")
                        }
                        
                        Button(action: { saveToPhotos(image) }) {
                            Label("Guardar en Fotos", systemImage: "photo.on.rectangle")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal, 8)
            } else if item.type == .pdf || item.type == .file {
                // Mostrar PDFs y archivos
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: item.type == .pdf ? "doc.pdf.fill" : "doc.fill")
                            .font(.system(size: 32))
                            .foregroundColor(item.type == .pdf ? .red : .blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.fileName ?? "Archivo")
                                .font(.headline)
                                .lineLimit(1)
                            
                            if let fileSize = item.fileSize {
                                let sizeStr = ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file)
                                Text(sizeStr)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text(item.relativeTime)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button(action: onDelete) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.red)
                        }
                    }
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            } else {
                // Texto o URL - vista normal
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
        case .pdf:
            return "doc.pdf"
        case .file:
            return "doc"
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
        case .pdf:
            return .red
        case .file:
            return .orange
        case .unknown:
            return .gray
        }
    }
    
    // MARK: - Acciones para Imágenes
    
    private func shareImage(_ image: UIImage) {
        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
    
    private func saveToPhotos(_ image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        // Mostrar toast o feedback visual
        print("✅ Imagen guardada en Fotos")
    }
}

/// Vista detallada de un item del portapapeles
struct ClipboardDetailView: View {
    let item: ClipboardItem
    let onCopy: () -> Void
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) var openURL
    
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
                    
                    // Contenido - mostrar imagen o texto según el tipo
                    ScrollView {
                        if item.type == .image, let image = ClipboardService.shared.getImage(from: item) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(8)
                                .frame(maxHeight: 300)
                        } else {
                            Text(item.content)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                    }
                    
                    Spacer()
                    
                    // Botones de acción según el tipo
                    VStack(spacing: 12) {
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
                        
                        // Botón Visitar para URLs
                        if item.type == .url, let url = URL(string: item.content) {
                            Button(action: {
                                openURL(url)
                                dismiss()
                            }) {
                                HStack {
                                    Image(systemName: "safari")
                                    Text("Visitar")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                        }
                        
                        // Botón Abrir en Safari para PDFs
                        if item.type == .pdf, let url = URL(string: item.content) {
                            Button(action: {
                                openURL(url)
                                dismiss()
                            }) {
                                HStack {
                                    Image(systemName: "safari")
                                    Text("Abrir en Safari")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                        }
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
        case .pdf:
            return "doc.pdf"
        case .file:
            return "doc"
        case .unknown:
            return "questionmark.circle"
        }
    }
}

#Preview {
    ClipboardView()
}
