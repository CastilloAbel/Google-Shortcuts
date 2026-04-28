import SwiftUI

/// Botón de portapapeles que muestra un menú con el histórico
struct ClipboardButton: View {
    private let clipboardService = ClipboardService.shared
    @State private var showMenu = false
    
    var onSelect: (ClipboardItem) -> Void
    
    var body: some View {
        Menu {
            if clipboardService.history.isEmpty {
                Button(action: {}) {
                    Label("Portapapeles vacío", systemImage: "doc.on.clipboard")
                }
                .disabled(true)
            } else {
                Section("Últimos items") {
                    ForEach(Array(clipboardService.history.prefix(10)), id: \.id) { item in
                        Button(action: {
                            onSelect(item)
                            clipboardService.copyToClipboard(item)
                        }) {
                            HStack {
                                Image(systemName: typeIcon(item.type))
                                    .frame(width: 16)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.displayText)
                                        .font(.caption)
                                        .lineLimit(1)
                                    
                                    Text(item.relativeTime)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                
                Divider()
                
                Link(destination: URL(string: "shortcuts://")!) {
                    Label("Ver todo el histórico", systemImage: "list.bullet")
                }
            }
        } label: {
            Image(systemName: "doc.on.clipboard")
                .foregroundColor(.blue)
        }
    }
    
    private func typeIcon(_ type: ClipboardItem.ContentType) -> String {
        switch type {
        case .text:
            return "doc.text"
        case .url:
            return "link.circle"
        case .image:
            return "photo.circle"
        case .pdf:
            return "doc.pdf.circle"
        case .file:
            return "doc.circle"
        case .unknown:
            return "questionmark.circle"
        }
    }
}

#Preview {
    ClipboardButton { item in
        print("Selected: \(item.content)")
    }
}
