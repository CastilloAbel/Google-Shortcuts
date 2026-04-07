# 🔨 Guía de Compilación v2.0 - Device Actions + OAuth2 Fix

## 🚨 ANTES de Compilar: OAuth2 Fix OBLIGATORIO

### Paso 1: Reparar Client ID

#### Opción A: Si NO tienes Client ID aún

1. Ve a https://console.cloud.google.com/
2. Crea nuevo proyecto "Gmail Shortcuts"
3. Activa API: Gmail API
4. Crea credencial "OAuth 2.0 Client ID (iOS)"
5. Te dará un Client ID como: `123456789-abcdefg.apps.googleusercontent.com`
6. Cópialo

#### Opción B: Si YA tienes Client ID

Simplemente cópialo de Google Cloud Console

### Paso 2: Reemplazar Client ID en el Código

Abre estos 2 archivos:

**A) `GoogleShortcuts/Core/Auth/OAuthConfig.swift`**

```swift
// ANTES
static let clientID = "YOUR_CLIENT_ID.apps.googleusercontent.com"

// DESPUÉS (reemplaza con tu ID)
static let clientID = "123456789-abcdefghijklmnopqrstuvwxyz.apps.googleusercontent.com"
```

**B) `GoogleShortcuts/App/Info.plist`**

```xml
<!-- ANTES -->
<string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>

<!-- DESPUÉS (reemplaza con tu ID) -->
<string>com.googleusercontent.apps.123456789-abcdefghijklmnopqrstuvwxyz.oauthredirect</string>
```

⚠️ **IMPORTANTE:** Incluye `.oauthredirect` al final en Info.plist

### Paso 3: Verificar en Google Cloud Console

1. Ve a https://console.cloud.google.com/
2. Abre tu proyecto "Gmail Shortcuts"
3. Ve a Credenciales → iOS Client
4. En "Restricted application URIs" o "Authorized redirect URIs", verifica que esté:
   ```
   com.googleusercontent.apps.123456789-abcdefghijklmnopqrstuvwxyz:/oauthredirect
   ```
   (Sin el `.oauthredirect` al final en Google Cloud - la app lo agrega automáticamente)

Si NO está, agrega ese URI, guarda, y espera 5-10 minutos.

### Paso 4: Git Commit

```bash
git add GoogleShortcuts/Core/Auth/OAuthConfig.swift
git add GoogleShortcuts/App/Info.plist
git commit -m "fix: Replace placeholder Client ID with real Google OAuth config"
git push
```

Ahora Codemagic compilará automáticamente.

---

## 🚀 Compilación en Codemagic

### 1. Espera a que Codemagic compile

```
Después de hacer push:
- Codemagic detecta cambios
- Inicia build automático
- Espera ~10-15 minutos
- Ver progreso en: https://codemagic.io/
```

### 2. Descarga el .ipa

```
Una vez compilado exitosamente:
1. Abre https://codemagic.io/
2. Abre tu proyecto "google-shortcuts"
3. Encuentra el último build exitoso
4. Descarga el archivo: `GoogleShortcuts-unsigned.ipa`
```

### 3. Si hay errores de compilación

Abre el log de Codemagic y busca:
- Swift syntax errors → Reporta
- Missing dependencies → Agrega a pubspec.yaml o similar
- Imagen de Xcode incorrecta → Revisa codemagic.yaml

---

## 📱 Instalación en iPhone via SideStore

### Opción 1: SideStore (Recomendado)

```
1. En Windows:
   - Descarga StorageManager o Windows app de SideStore
   - Conecta iPhone via USB a Windows
   - Abre SideStore app en iPhone
   
2. En iPhone (SideStore):
   - Settings → Allow SideStore
   - Habilita WiFi pairing (opcional)

3. En Windows:
   - Selecciona el .ipa descargado
   - Toca "Install"
   - Espera a que se instale (~1-2 minutos)
   
4. En iPhone:
   - Apps sideloaded aparecen en home
   - Abre "GmailShortcuts"
```

### Opción 2: AltStore (Si SideStore falla)

```
1. Descarga AltStore desde altstore.io
2. Conecta iPhone a Windows via USB
3. AltStore reconocerá el iPhone
4. Arrastra el .ipa a AltStore
5. Solicita credenciales Apple ID
6. Instala
```

---

## ✅ Testing Después de la Instalación

### Paso 1: Verificar Instalación

```
[ ] App aparece en home screen
[ ] Toca para abrir
[ ] Ve la pantalla de login
```

### Paso 2: Probar OAuth2 (CRÍTICO)

```
[ ] Toca "Acceder con Google"
[ ] Se abre Safari con login de Google
[ ] Ingresas tu email
[ ] Ingresas contraseña
[ ] Aceptas permisos (3 permisos de Gmail)
[ ] Safari se cierra y vuelves a la app
[ ] App muestra tu email como "Autenticado"
```

Si se queda en "Cargando" → OAuth2 no está reparado

### Paso 3: Probar Gmail Actions

```
[ ] Toca "Enviar Correo" → puede ingresar datos
[ ] Toca "Ver Correos" → ve tu inbox
[ ] Toca "Buscar" → busca correos
```

### Paso 4: Probar Device Actions

Abre la app **Atajos** (Shortcuts):

```
[ ] Busca "GmailShortcuts" en mi apps
[ ] Ves "Obtener nivel de batería" → tócalo
[ ] Devuelve un número (ej: 73)
[ ] Prueba "¿WiFi encendido?" → true/false
[ ] Prueba "Modelo de dispositivo" → "iPhone 15 Pro"
[ ] Prueba "Espacio disponible" → número en GB
```

Si algunas acciones no aparecen:
1. Cierra completamente Atajos
2. Cierra GmailShortcuts
3. Abre GmailShortcuts
4. Cierra completamente y abre Atajos de nuevo
5. Debería descubrir los intents

---

## 🧪 Crear un Atajo de Ejemplo

### Ejemplo 1: "Enviar si hay Batería"

```
1. Abre Atajos app
2. Crea nuevo atajo
3. Añade acción: "Obtener nivel de batería" (de GmailShortcuts)
4. Pregunta: "¿Es mayor a 20?"
   - Sí → continúa
   - No → mostrar "Batería baja"
5. Si continúa:
   - Añade: "Enviar correo con Gmail"
   - Llena email, asunto, cuerpo
6. Guarda como "Enviar si hay batería"
7. Prueba desde Atajos app
```

### Ejemplo 2: "Ver correos si WiFi"

```
1. Crea nuevo atajo
2. Añade: "Tipo de conexión" (GmailShortcuts)
3. Si result = "wifi"
   - Añade: "Consultar últimos correos"
4. Si result ≠ "wifi"
   - Mostrar alert: "Usa WiFi para ver correos"
5. Guarda
6. Prueba en WiFi vs datos móviles
```

---

## 🆘 Debugging

### OAuth2 se queda cargando

```
[ ] ¿Reemplazaste CLIENT_ID en OAuthConfig.swift? 
    → Sí → continúa
    → No → ve a Paso 2 de esta guía

[ ] ¿Info.plist tiene el scheme correcto?
    → com.googleusercontent.apps.YOUR_ID.oauthredirect
    → Sí → continúa
    → No → corrígelo y re-compila

[ ] ¿Google Cloud Console tiene registrado el redirect URI?
    → com.googleusercontent.apps.YOUR_ID:/oauthredirect
    → Sí → continúa
    → No → agrega y espera 5-10 min

[ ] ¿Todo coincide?
    → Sí → re-compila y reinstala
    → No → verifica cada letra (case-sensitive)
```

### Device Actions no aparecen en Atajos

```
[ ] Reinicia iPhone
[ ] Cierra GmailShortcuts
[ ] Abre GmailShortcuts
[ ] Cierra Atajos
[ ] Abre Atajos app
[ ] Busca acciones de GmailShortcuts
[ ] Si aún no aparecen → Reporta en GitHub
```

### Compilación falla en Codemagic

```
1. Abre el log de Codemagic
2. Busca "error:"
3. Si es Swift syntax → reporta con línea exacta
4. Si es "file not found" → archivo corrupto o ruta mal
5. Si es "no matching overload" → incompatibilidad de tipo
```

---

## 📋 Checklist Completo

- [ ] Client ID reemplazado en OAuthConfig.swift
- [ ] Info.plist URL scheme actualizado con oauthredirect
- [ ] Google Cloud Console tiene redirect URI registrado
- [ ] Git push realizado
- [ ] Codemagic compiló exitosamente
- [ ] .ipa descargado de Codemagic
- [ ] Instalado en iPhone via SideStore
- [ ] OAuth2 Login funciona (no queda cargando)
- [ ] Puedes ver tus correos en la app
- [ ] Device Actions aparecen en Atajos app
- [ ] Creaste un atajo de ejemplo y funciona

---

## 🎉 ¡Listo!

Si todo funciona:
- ✅ OAuth2 arreglado
- ✅ Gmail integration funcionando
- ✅ 20+ Device Actions disponibles
- ✅ Puedes crear atajos sofisticados combinándolas

**Próximo paso**: Crear atajos interesantes en la app Atajos y compartirlas.

---

**Versión**: 2.0
**Actualizado**: 7 de abril de 2026
