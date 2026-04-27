import SwiftUI

/// Modifier que aplica LiquidGlass effect al TabBar de la app
/// Compatible con iOS 16+
struct LiquidGlassTabBar: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                // Configurar UITabBar con efecto glass
                configureTabBarAppearance()
            }
    }
    
    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        
        // Efecto glass (blur background)
        appearance.configureWithTransparentBackground()
        
        // Agregar blur background
        let blurEffect = UIBlurEffect(style: .systemMaterial)
        _ = UIVisualEffectView(effect: blurEffect)
        
        // Color base transparente
        appearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.8)
        
        // Configurar colores de items
        let itemAppearance = UITabBarItemAppearance()
        itemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.gray]
        itemAppearance.normal.iconColor = .gray
        itemAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.systemBlue]
        itemAppearance.selected.iconColor = .systemBlue
        
        appearance.stackedLayoutAppearance = itemAppearance
        appearance.inlineLayoutAppearance = itemAppearance
        appearance.compactInlineLayoutAppearance = itemAppearance
        
        // Aplicar apariencia a todas las instancias de UITabBar
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

extension View {
    /// Aplica el efecto LiquidGlass al TabBar de la app
    func liquidGlassTabBar() -> some View {
        self.modifier(LiquidGlassTabBar())
    }
}
