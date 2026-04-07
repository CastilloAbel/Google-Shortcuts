# ⚡ QUICK START - Pasos Inmediatos

## 🚨 TU PROBLEMA: OAuth2 no funciona

### POR QUÉ FALLA:
- El Client ID aún es un placeholder ("YOUR_CLIENT_ID")
- Google no sabe a dónde devolver la autorización
- La app se queda cargando infinitamente

### SOLUCIÓN (5 pasos, ~15 minutos):

---

## PASO 1: Obtener tu Client ID

Abre: https://console.cloud.google.com/

1. Selecciona proyecto "Gmail Shortcuts"
2. Ve a: **Credenciales** (menú izquierda)
3. Busca tu credencial tipo "OAuth 2.0 Client ID (iOS)"
4. Ve a: **Descarga JSON** o copia manualmente el valor

Deberá parecer algo así:
```
123456789-abcdefghijklmnopqrstuvwxyz.apps.googleusercontent.com
```

**📋 Copia este valor exacto en un editor de texto temporalmente**

---

## PASO 2: Reemplazar en OAuthConfig.swift

Archivo: `GoogleShortcuts/Core/Auth/OAuthConfig.swift`

**Busca:**
```swift
static let clientID = "YOUR_CLIENT_ID.apps.googleusercontent.com"
```

**Reemplaza con:**
```swift
static let clientID = "TU_CLIENT_ID_REAL.apps.googleusercontent.com"
```

(Copia el que obtuviste en PASO 1)

---

## PASO 3: Reemplazar en Info.plist

Archivo: `GoogleShortcuts/App/Info.plist`

**Busca:**
```xml
<string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
```

**Reemplaza con:**
```xml
<string>com.googleusercontent.apps.TU_CLIENT_ID_REAL.oauthredirect</string>
```

⚠️ **IMPORTANTE**: Incluye `.oauthredirect` al final

---

## PASO 4: Verificar en Google Cloud Console

1. Ve a Google Cloud Console de nuevo
2. Ve a: **Credenciales** → Tu iOS Client
3. Busca la sección "Redirect URIs" o "Authorized URIs"
4. Verifica que esté registrado:
   ```
   com.googleusercontent.apps.TU_CLIENT_ID_REAL:/oauthredirect
   ```

**Si NO está:**
- Agrégalo manualmente
- Haz click **GUARDAR**
- Espera 5-10 minutos a que se propaguen los cambios

---

## PASO 5: Git Push

```bash
git add GoogleShortcuts/Core/Auth/OAuthConfig.swift
git add GoogleShortcuts/App/Info.plist
git commit -m "fix: Replace placeholder Client ID with real Google OAuth config"
git push
```

**Codemagic compilará automáticamente en ~10-15 minutos**

---

## ✅ VERIFICAR QUE FUNCIONA

Una vez que Codemagic termine la compilación:

1. **Descarga el .ipa** desde Codemagic
2. **Reinstala en iPhone** via SideStore
3. **Abre la app**
4. **Toca "Acceder con Google"**
5. **Deberías ver:**
   - Safari se abre con login de Google
   - Ingresas tu email
   - Ingresas contraseña
   - Aceptas permisos
   - **La app vuelve automáticamente** ✅
   - Ves tu email como "Autenticado"

Si seguía cargando infinitamente pero ahora funciona → **¡PROBLEMA RESUELTO!**

---

## 🎯 DESPUÉS DE FIJAR OAUTH2

### 1. Probar en la App
- Abre "Enviar Correo" → escribe correo de prueba
- Abre "Ver Correos" → deberías ver tu inbox
- Toca un correo para ver contenido

### 2. Probar Device Actions (NUEVO)

Abre app **Atajos** (Shortcuts):

1. Busca tu app: "GmailShortcuts"
2. Deberías ver 25+ acciones:
   - "Obtener nivel de batería"
   - "¿WiFi encendido?"
   - "Modelo de dispositivo"
   - "Espacio disponible"
   - ... y más

3. Haz click en una acción para probar:
   - "Obtener nivel de batería" → debería devolver un número (0-100)
   - "¿WiFi encendido?" → debería devolver true/false
   - etc.

---

## 📚 DOCUMENTACIÓN COMPLETA

Después de fijar OAuth2, lee en este orden:

1. **[DEVICE_ACTIONS.md](docs/DEVICE_ACTIONS.md)** 
   - Guía de 20+ acciones nuevas
   - Cómo usarlas en Atajos
   - Casos de uso prácticos

2. **[COMPILATION_GUIDE_V2.md](docs/COMPILATION_GUIDE_V2.md)**
   - Detalles de compilación
   - Debugging avanzado
   - Testing checklist

3. **[ARCHITECTURE_V2.md](docs/ARCHITECTURE_V2.md)**
   - Cómo está estructurado el código
   - Próximas features planificadas

---

## ❓ FAQ Rápido

### P: ¿Cuánto tiempo toma?
R: 5 minutos hacer los cambios + 15 minutos Codemagic = 20 min total

### P: ¿Pierdo mis correos al reinstalar?
R: No, todo está en Gmail. Solo es reinstalar la app.

### P: ¿Necesito un Mac?
R: No, Codemagic compila en la nube.

### P: ¿Se vuelve a expirar en 7 días?
R: Sí, pero solo necesitas reinstalar con SideStore (5 minutos).

### P: ¿Por qué 20+ Device Actions?
R: Para crear automatizaciones complejas en Atajos sin necesidad de autenticación.

---

## 🆘 SI AÚN NO FUNCIONA

Email exactamente lo que ves (screenshot):
1. Abre OAuthConfig.swift → Cliente ID que pusiste
2. Abre Info.plist → URL scheme que pusiste
3. Abre Google Cloud Console → Redirect URI registrado
4. Codemagic build log → errores exactos

Send this info + screenshots para debugging rápido.

---

**Versión**: Quick Start v2.0  
**Actualizado**: 7 de abril de 2026

