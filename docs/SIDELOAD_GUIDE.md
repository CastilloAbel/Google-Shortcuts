# Guía de Sideloading con SideStore / LiveContainer

## ¿Qué es Sideloading?

Instalar apps fuera de la App Store usando tu Apple ID gratuito
para firmar el binario. Apple permite firmar hasta 3 apps simultáneas
con renovación cada 7 días.

---

## Opción A: SideStore (Recomendada)

### ¿Qué es SideStore?
Fork de AltStore que no requiere un PC conectado para re-firmar.
Usa un WireGuard VPN local para simular una conexión a un "Mac" 
y renovar automáticamente la firma cada 7 días.

### Instalación de SideStore

#### Requisitos
- iPhone con iOS 16+
- PC con Windows (para la instalación inicial)
- Cable USB Lightning/USB-C
- Wi-Fi

#### Pasos
1. **Descargar SideStore**: [sidestore.io](https://sidestore.io)
2. **Instalar SideServer** en Windows:
   - Descargar desde [github.com/SideStore/SideServer-Windows](https://github.com/SideStore/SideServer-Windows)
   - Instalar iTunes (versión de escritorio, NO de Microsoft Store)
   - Instalar iCloud (versión de escritorio)
3. **Conectar iPhone por USB**
4. **Ejecutar SideServer**:
   - Ingresar tu Apple ID
   - SideServer instala SideStore en el iPhone
5. **En el iPhone**:
   - Ajustes > General > VPN y administración de dispositivos
   - Confiar en el perfil de desarrollo
6. **Configurar WireGuard** (para renovación automática):
   - Instalar WireGuard desde App Store (es gratis)
   - SideStore configura el VPN automáticamente
   - Activar el VPN cuando necesites renovar

### Instalar tu app (.ipa) con SideStore

1. Transfiere el archivo `GoogleShortcuts.ipa` a tu iPhone:
   - Via AirDrop (si tienes Mac)
   - Via Files app + iCloud Drive
   - Via compartir archivo por email/Telegram/WhatsApp
   - Via cable USB con iTunes (arrastrar al área de archivos)
2. En el iPhone, abre el `.ipa` con **SideStore**:
   - "Abrir con" > SideStore
   - O desde SideStore: "My Apps" > "+" > seleccionar el .ipa
3. SideStore firma la app con tu Apple ID y la instala
4. **Primera vez**: Ve a Ajustes > General > VPN y Gestión de dispositivos > Confiar

### Renovación automática (cada 7 días)
- SideStore renueva automáticamente si:
  - WireGuard VPN está activo
  - SideStore se ha abierto recientemente
- **TIP**: Crea una automatización en Shortcuts:
  - Trigger: "Cada lunes a las 8:00"
  - Action: "Abrir app SideStore"
  - Esto asegura que SideStore se ejecute y renueve

---

## Opción B: LiveContainer

### ¿Qué es LiveContainer?
Una app que funciona como "contenedor" para ejecutar otras apps dentro de ella.
No consume slots de sideloading adicionales (LiveContainer es 1 slot, 
pero puede contener múltiples apps).

### Ventajas sobre SideStore
- Solo usa 1 slot de sideloading para múltiples apps
- No necesita re-firmar cada app individualmente
- Más estable para algunos usos

### Desventajas
- Las apps corren "dentro" de LiveContainer, no como apps independientes
- Los App Intents podrían no funcionar correctamente dentro de LiveContainer
- URL Schemes requieren configuración adicional

### Instalación
1. Obtener LiveContainer .ipa desde [github.com/khanhduytran0/LiveContainer](https://github.com/khanhduytran0/LiveContainer)
2. Instalar LiveContainer con SideStore o AltStore
3. Abrir LiveContainer
4. Importar tu .ipa dentro de LiveContainer

> ⚠️ **NOTA sobre App Intents y LiveContainer**:
> Los App Intents podrían NO registrarse correctamente cuando la app
> corre dentro de LiveContainer, porque el sistema iOS busca los intents
> en el bundle principal (que sería LiveContainer, no tu app).
> **Recomendación**: Usa SideStore para esta app específica.

---

## Opción C: AltStore (Alternativa clásica)

Similar a SideStore pero requiere un PC encendido en la misma red Wi-Fi
para renovar cada 7 días.

1. Descargar AltServer: [altstore.io](https://altstore.io)
2. Instalar AltServer en Windows
3. Instalar AltStore en iPhone via cable USB
4. Transferir .ipa a AltStore para instalar

---

## Comportamiento de los tokens con sideloading

### ¿Los tokens de Google se pierden al re-firmar?

**NO.** Los tokens se guardan en dos lugares:

| Almacenamiento | Persiste al re-firmar | Condición |
|---|---|---|
| Keychain | ✅ Sí | Mientras el Bundle ID no cambie |
| UserDefaults (App Group) | ✅ Sí | Mientras el App Group ID no cambie |

El Bundle ID (`com.personal.googleshortcuts`) NO cambia al re-firmar con SideStore.
Solo cambia si modificas el proyecto y recompilas con un ID diferente.

### ¿Qué pasa si la app expira y no la renuevo?

1. La app NO se abre (iOS la bloquea)
2. Los datos internos (tokens, configuración) se MANTIENEN
3. Al re-firmar con SideStore, todo vuelve a funcionar sin re-login
4. Las automatizaciones de Shortcuts dejarán de funcionar hasta re-firmar

### ¿Los Shortcuts se pierden?

**NO.** Los Shortcuts que crees se mantienen en la app Shortcuts.
Solo fallarán si la app está expirada. Al renovar, vuelven a funcionar.

---

## Checklist post-instalación

- [ ] App instalada y se abre correctamente
- [ ] Confiar en perfil de desarrollo (Ajustes > General > VPN y Gestión de dispositivos)
- [ ] Iniciar sesión con Google (botón "Conectar con Google")
- [ ] Verificar que el OAuth callback funciona (vuelve a la app después del login)
- [ ] Enviar un correo de prueba desde la app
- [ ] Abrir app Shortcuts y verificar que aparecen las acciones de "GmailShortcuts"
- [ ] Crear un shortcut de prueba "Enviar correo con GmailShortcuts"
- [ ] Ejecutar el shortcut
- [ ] Configurar WireGuard/SideStore para renovación automática

---

## Troubleshooting

### "No se puede verificar la app"
→ Ajustes > General > VPN y Gestión de dispositivos > Confiar en tu perfil

### "La app ya no es válida" / no se abre
→ La firma de 7 días expiró. Abre SideStore y renueva.

### "Error de OAuth: no se puede volver a la app"
→ Verifica que el URL Scheme en Info.plist coincide con tu Client ID de Google.
   El scheme debe ser `com.googleusercontent.apps.TU_CLIENT_ID`

### Las acciones no aparecen en Shortcuts
→ Reinicia el iPhone. iOS indexa App Intents en background y puede tardar unos minutos.

### SideStore no puede renovar
→ Verifica que WireGuard VPN está activo.
→ Abre SideStore manualmente y pulsa "Refresh All".

### La app usa mucha batería
→ Reduce el intervalo de polling en Ajustes (ej: 30 min en vez de 5 min).
→ O desactiva el polling y usa solo Shortcuts bajo demanda.
