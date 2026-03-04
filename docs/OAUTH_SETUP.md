# Configuración OAuth2 en Google Cloud Console

## Paso a paso para obtener credenciales de Gmail API

### 1. Crear proyecto en Google Cloud Console

1. Ve a **[Google Cloud Console](https://console.cloud.google.com/)**
2. Inicia sesión con tu cuenta Google personal
3. Haz clic en el selector de proyectos (arriba a la izquierda)
4. Clic en **"Nuevo Proyecto"**
5. Nombre: `GmailShortcuts` (o cualquier nombre)
6. Clic en **"Crear"**
7. Selecciona el proyecto recién creado

### 2. Habilitar Gmail API

1. En el menú lateral: **APIs y servicios > Biblioteca**
2. Busca **"Gmail API"**
3. Clic en **Gmail API**
4. Clic en **"Habilitar"**
5. Espera a que se active

### 3. Configurar pantalla de consentimiento OAuth

1. En el menú: **APIs y servicios > Pantalla de consentimiento de OAuth**
2. Selecciona **"Externo"** (aunque solo seas tú, es la única opción sin Google Workspace)
3. Clic en **"Crear"**

#### Página 1: Información de la aplicación
| Campo | Valor |
|-------|-------|
| Nombre de la app | `GmailShortcuts` |
| Correo de asistencia | Tu email personal |
| Logo | (opcional, puedes omitirlo) |
| Página principal de la app | (dejar vacío o poner cualquier URL) |
| Política de privacidad | (dejar vacío) |
| Términos de servicio | (dejar vacío) |
| Dominios autorizados | (no agregar ninguno) |
| Correo del desarrollador | Tu email personal |

4. Clic en **"Guardar y continuar"**

#### Página 2: Alcances (Scopes)
1. Clic en **"Agregar o quitar alcances"**
2. Busca y selecciona:
   - `https://www.googleapis.com/auth/gmail.send`
   - `https://www.googleapis.com/auth/gmail.readonly`
   - `https://www.googleapis.com/auth/userinfo.email`
3. Clic en **"Actualizar"**
4. Clic en **"Guardar y continuar"**

#### Página 3: Usuarios de prueba
1. Clic en **"Agregar usuarios"**
2. Escribe **tu email** (el que usarás con la app)
3. Clic en **"Agregar"**
4. Clic en **"Guardar y continuar"**

> ⚠️ **IMPORTANTE**: Mientras la app esté en modo "Testing" (no publicada),
> SOLO los emails que agregues aquí podrán iniciar sesión.
> Para uso personal, esto es perfecto. No necesitas publicar la app.

#### Página 4: Resumen
- Revisar y clic en **"Volver al panel"**

### 4. Crear credenciales OAuth 2.0

1. En el menú: **APIs y servicios > Credenciales**
2. Clic en **"Crear credenciales" > "ID de cliente OAuth"**
3. Tipo de aplicación: **"iOS"**
4. Nombre: `GmailShortcuts-iOS`
5. **Bundle ID**: `com.personal.googleshortcuts`
   - Este DEBE coincidir con el `PRODUCT_BUNDLE_IDENTIFIER` del proyecto
   - Si cambias el bundle ID en el proyecto, cámbialo aquí también
6. Clic en **"Crear"**

### 5. Obtener el Client ID

Después de crear las credenciales, Google te muestra:

```
Client ID: XXXXXXXXXXXX-YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY.apps.googleusercontent.com
```

> **NO hay Client Secret** para apps iOS. Google usa PKCE en su lugar.

### 6. Configurar el Client ID en la app

#### Archivo: `GoogleShortcuts/Core/Auth/OAuthConfig.swift`

Reemplaza la línea:
```swift
static let clientID = "YOUR_CLIENT_ID.apps.googleusercontent.com"
```
Con tu Client ID real:
```swift
static let clientID = "XXXXXXXXXXXX-YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY.apps.googleusercontent.com"
```

#### Archivo: `GoogleShortcuts/App/Info.plist`

Busca:
```xml
<string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
```
Reemplaza `YOUR_CLIENT_ID` con la parte ANTES de `.apps.googleusercontent.com`:
```xml
<string>com.googleusercontent.apps.XXXXXXXXXXXX-YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY</string>
```

### 7. Redirect URI (automático)

La redirect URI se construye automáticamente así:
```
com.googleusercontent.apps.{CLIENT_ID_PART}:/oauthredirect
```

Por ejemplo, si tu Client ID es:
```
123456789-abcdefghijklmnop.apps.googleusercontent.com
```

La redirect URI será:
```
com.googleusercontent.apps.123456789-abcdefghijklmnop:/oauthredirect
```

> **No necesitas registrar la redirect URI en Google Cloud Console** para apps iOS.
> Google la infiere del Client ID automáticamente.

---

## Diagrama del flujo OAuth2 + PKCE

```
┌──────────────┐     1. Genera code_verifier     ┌──────────────┐
│              │     + code_challenge              │              │
│   iOS App    │ ─────────────────────────────────>│   Google     │
│              │     2. Abre browser con           │   OAuth      │
│              │     authorization URL             │   Server     │
│              │                                   │              │
│              │     3. Usuario inicia sesión      │              │
│              │     y autoriza permisos           │              │
│              │                                   │              │
│              │ <─────────────────────────────────│              │
│              │     4. Redirect a app con         │              │
│              │     authorization code            │              │
│              │                                   │              │
│              │ ─────────────────────────────────>│              │
│              │     5. POST /token con            │              │
│              │     code + code_verifier          │              │
│              │                                   │              │
│              │ <─────────────────────────────────│              │
│              │     6. Recibe:                    │              │
│              │     - access_token (1h)           │              │
│              │     - refresh_token (permanente)  │              │
└──────────────┘                                   └──────────────┘
```

---

## Preguntas frecuentes

### ¿Necesito verificar la app en Google?
**NO.** Para uso personal, la app se queda en modo "Testing". Solo los usuarios
que agregues manualmente podrán autenticarse (que serás solo tú).

### ¿El Client Secret es necesario?
**NO.** Para apps iOS (clientes públicos), Google usa PKCE en lugar de Client Secret.
No hay secret que proteger.

### ¿Qué pasa si mi app expira cada 7 días?
Los tokens de Google **no se pierden** al re-firmar la app con SideStore.
Están guardados en Keychain, que persiste entre instalaciones mientras
el bundle ID no cambie.

### ¿Los tokens de Google también expiran?
- **Access token**: Expira en ~1 hora. Se renueva automáticamente con el refresh token.
- **Refresh token**: No expira normalmente. Solo se revoca si:
  - Cambias la contraseña de Google
  - Revocas acceso manualmente desde la cuenta Google
  - No usas la app por 6 meses (política de Google)

### ¿Cuotas de Gmail API?
Plan gratuito: **250 unidades de cuota por usuario por segundo**.
Para uso personal (decenas de llamadas al día) nunca llegarás al límite.

### ¿Puedo cambiar los scopes después?
Sí. Modifica los scopes en `OAuthConfig.swift` y en la pantalla de consentimiento
de Google Cloud Console. El usuario deberá re-autorizar la app.
