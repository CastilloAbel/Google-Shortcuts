import SwiftUI

/// Modifier que aplica un efecto glass (vidrio esmerilado) que cambia según el tema.
///
/// En Light Mode: vidrio transparente con blur suave
/// En Dark Mode: vidrio oscuro con blur más intenso
///
/// Uso:
/// ```swift
/// VStack { ... }
///     .glassEffect()
/// ```
struct GlassEffect: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Capa de color base según el tema
                    if colorScheme == .dark {
                        // Dark mode: vidrio oscuro con tono azul
                        Color.black.opacity(0.15)
                            .blur(radius: 10)
                    } else {
                        // Light mode: vidrio claro con tono
                        Color.white.opacity(0.3)
                            .blur(radius: 10)
                    }
                }
            )
            .background(colorScheme == .dark ? Color.black.opacity(0.05) : Color.white.opacity(0.1))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 8, x: 0, y: 2)
    }
}

/// Extensión para usar `glassEffect()` en cualquier View
extension View {
    func glassEffect() -> some View {
        self.modifier(GlassEffect())
    }
}

/// Versión avanzada con custom colors
struct GlassEffectAdvanced: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    let lightColor: Color
    let darkColor: Color
    let blur: CGFloat
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    if colorScheme == .dark {
                        darkColor.opacity(0.2)
                            .blur(radius: blur)
                    } else {
                        lightColor.opacity(0.3)
                            .blur(radius: blur)
                    }
                }
            )
            .background(colorScheme == .dark ? Color.black.opacity(0.05) : Color.white.opacity(0.1))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 8, x: 0, y: 2)
    }
}

extension View {
    /// Aplica glass effect con colores personalizados
    func glassEffect(lightColor: Color = .white, darkColor: Color = .black, blur: CGFloat = 10) -> some View {
        self.modifier(GlassEffectAdvanced(lightColor: lightColor, darkColor: darkColor, blur: blur))
    }
}

// Vista de ejemplo/preview
struct GlassEffectExample: View {
    var body: some View {
        ZStack {
            // Fondo degradado
            LinearGradient(
                gradient: Gradient(colors: [.blue, .purple]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Card 1: Glass effect básico
                VStack(spacing: 16) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                    
                    Text("Liquid Glass")
                        .font(.title2.bold())
                    
                    Text("Efecto de vidrio esmerilado")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .glassEffect()
                
                // Card 2: Con contenido interactivo
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        
                        Text("Light Mode: vidrio claro")
                            .font(.caption)
                    }
                    
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        
                        Text("Dark Mode: vidrio oscuro")
                            .font(.caption)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .glassEffect()
                
                Spacer()
            }
            .padding(16)
        }
    }
}

#Preview {
    GlassEffectExample()
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    GlassEffectExample()
        .preferredColorScheme(.dark)
}
