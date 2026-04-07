# 🔧 Guía de Reparación OAuth2 + Configuración Completa

## ❌ Problema Identificado

La sincronización con Google no funciona porque el **Client ID sigue siendo el placeholder** "YOUR_CLIENT_ID" en dos archivos críticos:

### Archivo 1: `GoogleShortcuts/Core/Auth/OAuthConfig.swift`

```swift
// ❌ INCORRECTO (estado actual)
static let clientID = "YOUR_CLIENT_ID.apps.googleusercontent.com"
```

**Consecuencia:**
- El `redirectURI` calculado automáticamente se vuelve: `com.googleusercontent.apps.YOUR_CLIENT_ID:/oauthredirect`
- Google no reconoce este URI como válido
- El callback nunca se devuelve a la app
- **La app se queda en pantalla de carga infinita**

### Archivo 2: `GoogleShortcuts/App/Info.plist`

```xml
<!-- ❌ INCORRECTO (estado actual) -->
<string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
```

**Debería ser:**
```xml
<!-- ✅ CORRECTO (con tu Client ID real) -->
<string>com.googleusercontent.apps.YOUR_REAL_CLIENT_ID.oauthredirect</string>
```

---

## ✅ Solución Paso a Paso

### Paso 0: Obtener tu Client ID de Google Cloud Console

1. Ve a https://console.cloud.google.com/
2. Selecciona tu proyecto "Gmail Shortcuts"
3. Ve a **Credenciales** en el menú de la izquierda
4. Busca tu credencial de tipo **"OAuth 2.0 Client ID (iOS)"**
5. El Client ID tendrá este formato:
   ```
   123456789-abcdefghijklmnopqrstuvwxyz.apps.googleusercontent.com
   ```
   **Copia el valor completo**

### Paso 1: Modificar OAuthConfig.swift

Abre `GoogleShortcuts/Core/Auth/OAuthConfig.swift` y reemplaza:

```swift
// ANTES
static let clientID = "YOUR_CLIENT_ID.apps.googleusercontent.com"

// DESPUÉS
static let clientID = "123456789-abcdefghijklmnopqrstuvwxyz.apps.googleusercontent.com"
```

💡 **Sobre el redirectURI:**
- La propiedad `redirectURI` es **calculada automáticamente** a partir del clientID
- NO la modifiques manualmente
- Después de cambiar el clientID, automáticamente será:
  ```
  com.googleusercontent.apps.123456789-abcdefghijklmnopqrstuvwxyz:/oauthredirect
  ```

### Paso 2: Modificar Info.plist

Abre `GoogleShortcuts/App/Info.plist` y busca la sección:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>com.personal.googleshortcuts</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>googleshortcuts</string>
            <!-- REEMPLAZAR ESTA LÍNEA: -->
            <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

**Reemplaza** `com.googleusercontent.apps.YOUR_CLIENT_ID` **con:**
```xml
<string>com.googleusercontent.apps.123456789-abcdefghijklmnopqrstuvwxyz.oauthredirect</string>
```

⚠️ **IMPORTANTE:** Incluye `.oauthredirect` al final (no solo el Client ID).

### Paso 3: Verificar en Google Cloud Console

1. Ve a https://console.cloud.google.com/
2. Abre tu proyecto "Gmail Shortcuts"
3. Ve a **Credenciales** → selecciona tu OAuth Client ID (iOS)
4. Verifica que el **Redirect URI registrado** sea exactamente:
   ```
   com.googleusercontent.apps.123456789-abcdefghijklmnopqrstuvwxyz:/oauthredirect
   ```

⚠️ **Si NO coincide:**
   - Actualiza el Redirect URI en Google Cloud Console
   - O modifica Info.plist para que coincida con lo que Google tiene registrado

### Paso 4: Rebuild en Codemagic

1. Commit y push los cambios:
   ```bash
   git add GoogleShortcuts/Core/Auth/OAuthConfig.swift
   git add GoogleShortcuts/App/Info.plist
   git commit -m "Fix: Replace placeholder Client ID with real Google OAuth credentials"
   git push
   ```

2. Espera a que Codemagic compile automáticamente
3. Descarga el nuevo `.ipa`
4. Reinstala en SideStore

### Paso 5: Probar Login en iPhone

1. Abre la app en tu iPhone
2. Toca "Acceder con Google"
3. **Ahora deberías ver:**
   - Safari se abre con pantalla de login de Google
   - Ingresas tu contraseña
   - Google te pide permiso (con los 3 permisos: enviar, leer, email)
   - Después de autorizar, **la app vuelve automáticamente** (closeSession en el navegador)
   - La app muestra tu email y estás autenticado ✅

---

## 🔍 Debugging si Aún No Funciona

### Si aún se queda en carga infinita:

1. **Verifica que el Client ID sea correcto:**
   ```swift
   // En OAuthManager.swift, agrega esta línea al inicio de startLogin():
   print("DEBUG - Client ID: \(OAuthConfig.clientID)")
   print("DEBUG - Redirect URI: \(OAuthConfig.redirectURI)")
   ```

2. **Abre Console.app en el Mac y ejecuta:**
   ```bash
   log stream --predicate 'eventMessage contains[cd] "DEBUG"' --level debug
   ```
   Esto mostrará el Client ID y Redirect URI que tu app está usando.

3. **Compara con Google Cloud Console:**
   - Abre https://console.cloud.google.com/
   - Credenciales → iOS Client
   - Verifica que el Redirect URI sea **exacto**

### Si Google muestra error "Redirect URI not registered":

1. Ve a Google Cloud Console
2. Edita el iOS Client
3. Agrega este Redirect URI si no está:
   ```
   com.googleusercontent.apps.YOUR_REAL_CLIENT_ID:/oauthredirect
   ```
4. Guarda y espera 5-10 minutos
5. Reintenta en la app

### Si la app abre Safari pero nada pasa después:

- El problema es el URL Scheme en Info.plist
- Asegúrate que en Info.plist esté registrado el scheme exacto
- El URL scheme debe coincidir con lo que Google devuelve

---

## 📋 Checklist de Verificación

- [ ] Client ID en OAuthConfig.swift es real (no YOUR_CLIENT_ID)
- [ ] Client ID en OAuthConfig.swift coincide con Google Cloud Console
- [ ] Info.plist tiene el scheme: `com.googleusercontent.apps.[TU_CLIENT_ID].oauthredirect`
- [ ] Google Cloud Console tiene registrado ese mismo Redirect URI
- [ ] Has hecho push a Git y Codemagic compiló
- [ ] Has descargado el nuevo .ipa de Codemagic
- [ ] Has reinstalado en SideStore
- [ ] Tictac: toque "Acceder con Google" y esperas a Safari

---

## 🚀 Próximos Pasos Después de Fijar OAuth2

Una vez que OAuth2 funcione:
1. Verifica que puedas listar correos
2. Prueba enviar un correo desde la app
3. Prueba las acciones de Shortcuts (abre Shortcuts app y busca "GmailShortcuts")
4. Una vez confirmado, procederemos con las **Device Actions** (Bluetooth, WiFi, Battery, etc.)

