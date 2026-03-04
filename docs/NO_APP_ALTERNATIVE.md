# Alternativa sin App Nativa: Shortcuts + Google Apps Script

## ¿Por qué esta alternativa?

Si no tienes acceso a un Mac para compilar la app iOS, esta alternativa
te da el **80% de la funcionalidad** usando solo:
- **Apple Shortcuts** (ya instalado en tu iPhone)
- **Google Apps Script** (gratuito, basado en web)
- Tu cuenta Google personal

**No necesitas**: Mac, Xcode, Apple Developer Account, sideloading.

---

## Arquitectura

```
┌──────────────────┐     HTTP GET/POST      ┌──────────────────┐
│                  │ ──────────────────────> │                  │
│  Apple Shortcuts │                         │  Google Apps     │
│  (en tu iPhone)  │ <────────────────────── │  Script (web)    │
│                  │     JSON response       │                  │
└──────────────────┘                         └──────┬───────────┘
                                                    │
                                                    │ Gmail API
                                                    │ (acceso nativo)
                                                    │
                                             ┌──────▼───────────┐
                                             │                  │
                                             │  Tu Gmail        │
                                             │                  │
                                             └──────────────────┘
```

### ¿Por qué Google Apps Script?

- **Acceso nativo a Gmail**: No necesita OAuth externo, accede a tu Gmail directamente
- **Gratuito**: Incluido con cualquier cuenta Google
- **Desplegable como Web App**: Se expone como URL que Shortcuts puede llamar
- **Sin servidor propio**: Google lo hospeda
- **Seguro**: Solo tú puedes ejecutarlo (o puedes protegerlo con un token)

---

## Paso 1: Crear el Google Apps Script

### 1.1 Ir a Google Apps Script
1. Ve a **[script.google.com](https://script.google.com)**
2. Inicia sesión con tu cuenta Google personal
3. Clic en **"Nuevo proyecto"**
4. Nombra el proyecto: `GmailShortcuts-API`

### 1.2 Reemplazar el código

Borra todo el contenido del archivo `Code.gs` y pega el siguiente código:

```javascript
/**
 * GmailShortcuts API - Google Apps Script
 * 
 * Actúa como intermediario entre Apple Shortcuts y Gmail.
 * Se despliega como Web App y acepta requests GET/POST.
 * 
 * SEGURIDAD: Usa un token secreto para autenticar las requests.
 * Solo requests con el token correcto son procesadas.
 */

// ⚠️ CAMBIA ESTO: Genera un token aleatorio largo
// Puedes usar: https://generate-random.org/api-token-generator
const SECRET_TOKEN = "CAMBIA_ESTO_POR_UN_TOKEN_ALEATORIO_LARGO_123456";

/**
 * Maneja requests GET (para acciones simples desde Shortcuts).
 */
function doGet(e) {
  return handleRequest(e);
}

/**
 * Maneja requests POST (para enviar correos con body largo).
 */
function doPost(e) {
  return handleRequest(e);
}

/**
 * Router principal.
 */
function handleRequest(e) {
  try {
    // Verificar token de seguridad
    const token = e.parameter.token;
    if (token !== SECRET_TOKEN) {
      return jsonResponse({ error: "Unauthorized" }, 401);
    }
    
    const action = e.parameter.action;
    
    switch (action) {
      case "send":
        return sendEmail(e);
      case "recent":
        return getRecentEmails(e);
      case "search":
        return searchEmails(e);
      case "unread":
        return getUnreadCount(e);
      case "check_new":
        return checkNewEmails(e);
      case "ping":
        return jsonResponse({ status: "ok", email: Session.getActiveUser().getEmail() });
      default:
        return jsonResponse({ error: "Acción no válida. Usa: send, recent, search, unread, check_new, ping" });
    }
  } catch (error) {
    return jsonResponse({ error: error.toString() }, 500);
  }
}

// ========================================
// ACCIONES
// ========================================

/**
 * Envía un correo electrónico.
 * 
 * Parámetros:
 * - to: dirección de destino (requerido)
 * - subject: asunto (requerido)
 * - body: cuerpo del correo (requerido)
 * - cc: (opcional)
 * - bcc: (opcional)
 */
function sendEmail(e) {
  const to = e.parameter.to;
  const subject = e.parameter.subject;
  const body = e.parameter.body || getPostBody(e);
  const cc = e.parameter.cc || "";
  const bcc = e.parameter.bcc || "";
  
  if (!to || !subject) {
    return jsonResponse({ error: "Faltan parámetros: to, subject" });
  }
  
  const options = {};
  if (cc) options.cc = cc;
  if (bcc) options.bcc = bcc;
  
  GmailApp.sendEmail(to, subject, body, options);
  
  return jsonResponse({
    success: true,
    message: "Correo enviado correctamente",
    to: to,
    subject: subject
  });
}

/**
 * Obtiene los últimos correos del inbox.
 * 
 * Parámetros:
 * - count: número de correos (default: 10, max: 50)
 */
function getRecentEmails(e) {
  const count = Math.min(parseInt(e.parameter.count) || 10, 50);
  
  const threads = GmailApp.getInboxThreads(0, count);
  const emails = threads.map(thread => {
    const message = thread.getMessages()[thread.getMessageCount() - 1];
    return {
      id: message.getId(),
      from: message.getFrom(),
      to: message.getTo(),
      subject: message.getSubject(),
      date: message.getDate().toISOString(),
      snippet: message.getPlainBody().substring(0, 200),
      isUnread: message.isUnread(),
      hasAttachments: message.getAttachments().length > 0
    };
  });
  
  return jsonResponse({
    count: emails.length,
    emails: emails
  });
}

/**
 * Busca correos por query.
 * 
 * Parámetros:
 * - query: texto/query de búsqueda de Gmail (requerido)
 * - count: máximo de resultados (default: 10)
 */
function searchEmails(e) {
  const query = e.parameter.query;
  const count = Math.min(parseInt(e.parameter.count) || 10, 50);
  
  if (!query) {
    return jsonResponse({ error: "Falta parámetro: query" });
  }
  
  const threads = GmailApp.search(query, 0, count);
  const emails = threads.map(thread => {
    const message = thread.getMessages()[thread.getMessageCount() - 1];
    return {
      id: message.getId(),
      from: message.getFrom(),
      subject: message.getSubject(),
      date: message.getDate().toISOString(),
      snippet: message.getPlainBody().substring(0, 200),
      isUnread: message.isUnread()
    };
  });
  
  return jsonResponse({
    query: query,
    count: emails.length,
    emails: emails
  });
}

/**
 * Obtiene el conteo de correos no leídos.
 */
function getUnreadCount(e) {
  const count = GmailApp.getInboxUnreadCount();
  return jsonResponse({
    unreadCount: count
  });
}

/**
 * Verifica correos nuevos en las últimas N horas.
 * 
 * Parámetros:
 * - hours: últimas N horas a verificar (default: 1)
 */
function checkNewEmails(e) {
  const hours = parseInt(e.parameter.hours) || 1;
  const query = `is:unread newer_than:${hours}h`;
  
  const threads = GmailApp.search(query, 0, 20);
  const emails = threads.map(thread => {
    const message = thread.getMessages()[thread.getMessageCount() - 1];
    return {
      from: message.getFrom(),
      subject: message.getSubject(),
      date: message.getDate().toISOString(),
      isUnread: true
    };
  });
  
  return jsonResponse({
    hasNew: emails.length > 0,
    count: emails.length,
    emails: emails
  });
}

// ========================================
// HELPERS
// ========================================

function getPostBody(e) {
  if (e.postData) {
    try {
      const json = JSON.parse(e.postData.contents);
      return json.body || "";
    } catch (_) {
      return e.postData.contents;
    }
  }
  return "";
}

function jsonResponse(data, statusCode) {
  return ContentService
    .createTextOutput(JSON.stringify(data))
    .setMimeType(ContentService.MimeType.JSON);
}
```

### 1.3 Configurar el token de seguridad

En la línea:
```javascript
const SECRET_TOKEN = "CAMBIA_ESTO_POR_UN_TOKEN_ALEATORIO_LARGO_123456";
```

Reemplaza con un token largo y aleatorio. Puedes generarlo así:
- Ve a [generate-random.org/api-token-generator](https://generate-random.org/api-token-generator)
- O simplemente inventa uno largo: `MiTokenSecreto_2024_Gmail_a8f3k2m9`

### 1.4 Desplegar como Web App

1. En Google Apps Script: **Implementar > Nueva implementación**
2. Tipo: **Aplicación web**
3. Descripción: `GmailShortcuts API v1`
4. **Ejecutar como**: "Yo" (tu email)
5. **Quién tiene acceso**: "Cualquier persona" 
   - ⚠️ Esto es necesario para que Shortcuts pueda llamar a la URL
   - La seguridad la da tu `SECRET_TOKEN`
6. Clic en **"Implementar"**
7. **Autorizar acceso**: Google te pedirá permisos de Gmail. Acéptalos.
8. **Copia la URL de la Web App** — la necesitarás para Shortcuts

La URL tendrá este formato:
```
https://script.google.com/macros/s/AKfycbx.../exec
```

### 1.5 Probar en el navegador

Abre esta URL en tu navegador (reemplaza con tu URL y token):
```
https://script.google.com/macros/s/TU_URL/exec?action=ping&token=TU_TOKEN
```

Deberías ver:
```json
{"status":"ok","email":"tu-email@gmail.com"}
```

---

## Paso 2: Crear los Shortcuts en iPhone

### Shortcut 1: Enviar correo

1. Abrir app **Shortcuts**
2. **"+"** > Crear nuevo shortcut
3. Nombre: "Enviar correo Gmail"

#### Acciones:
```
1. [Solicitar entrada] → Tipo: Texto → Pregunta: "¿A quién?"
   → Guardar en variable: destinatario

2. [Solicitar entrada] → Tipo: Texto → Pregunta: "¿Asunto?"
   → Guardar en variable: asunto

3. [Solicitar entrada] → Tipo: Texto → Pregunta: "¿Cuerpo del correo?"
   → Guardar en variable: cuerpo

4. [URL] → https://script.google.com/macros/s/TU_URL/exec?action=send&token=TU_TOKEN&to=[destinatario]&subject=[asunto]&body=[cuerpo]

5. [Obtener contenido de URL] → Método: GET

6. [Obtener valor del diccionario] → Clave: "success"

7. [Si] → es igual a → true
   → [Mostrar notificación] → "✅ Correo enviado"
   [Si no]
   → [Mostrar notificación] → "❌ Error al enviar"
```

### Shortcut 2: Ver últimos correos

```
1. [URL] → https://script.google.com/macros/s/TU_URL/exec?action=recent&token=TU_TOKEN&count=5

2. [Obtener contenido de URL] → Método: GET

3. [Obtener valor del diccionario] → Clave: "emails"

4. [Repetir con cada uno]
   → [Obtener valor del diccionario] → Clave: "from"
      → Guardar en variable: remitente
   → [Obtener valor del diccionario] → Clave: "subject"
      → Guardar en variable: asunto
   → [Texto] → "De: [remitente] - [asunto]"
   → [Agregar a variable] → variable: listaCorreos

5. [Elegir de lista] → [listaCorreos]
   (Muestra los correos para que elijas uno)
```

### Shortcut 3: Verificar correos nuevos (para automatización)

```
1. [URL] → https://script.google.com/macros/s/TU_URL/exec?action=check_new&token=TU_TOKEN&hours=1

2. [Obtener contenido de URL]

3. [Obtener valor del diccionario] → Clave: "hasNew"

4. [Si] → es igual a → true
   → [Obtener valor del diccionario] → Clave: "count" (del paso 2)
   → [Mostrar notificación] → "📬 Tienes [count] correos nuevos"
```

### Shortcut 4: Buscar correos

```
1. [Solicitar entrada] → Tipo: Texto → "¿Qué buscar?"
   → Guardar en variable: query

2. [URL] → https://script.google.com/macros/s/TU_URL/exec?action=search&token=TU_TOKEN&query=[query]

3. [Obtener contenido de URL]

4. [Obtener valor del diccionario] → Clave: "emails"

5. [Repetir con cada uno]
   → [Texto] → "📌 [subject] - De: [from]"
   → [Agregar a variable] → resultados

6. [Elegir de lista] → [resultados]
```

### Automatización: Verificar correos cada 30 minutos

1. En Shortcuts: pestaña **Automatización**
2. **"+"** > **Automatización personal**
3. **"Hora del día"** → cada 30 minutos (o la frecuencia que prefieras)
   - Puedes crear varias: 8:00, 8:30, 9:00, etc.
4. **"Ejecutar inmediatamente"** (sin preguntar)
5. Agregar las acciones del Shortcut 3 (verificar correos nuevos)

---

## Paso 3: Seguridad adicional

### Protección del token
- El `SECRET_TOKEN` viaja en la URL como parámetro
- HTTPS encripta la URL completa en tránsito
- Google Apps Script solo acepta HTTPS
- **Riesgo**: Si alguien obtiene tu URL completa, puede usar tu API
- **Mitigación**: Usa un token largo y aleatorio. No lo compartas.

### Limitar funcionalidad (opcional)
Si quieres desactivar alguna función (ej: solo lectura, sin envío),
comenta la línea correspondiente en el switch del script:
```javascript
case "send":
  // return sendEmail(e);
  return jsonResponse({ error: "Envío deshabilitado" });
```

---

## Comparación: App Nativa vs Apps Script

| Funcionalidad | App Nativa | Apps Script |
|---|---|---|
| Enviar correo | ✅ | ✅ |
| Leer correos | ✅ | ✅ |
| Buscar correos | ✅ | ✅ |
| Contar no leídos | ✅ | ✅ |
| Verificar nuevos | ✅ | ✅ |
| App Intents (voz/Siri) | ✅ | ❌ |
| Funciona sin internet | ❌ | ❌ |
| Necesita Mac para compilar | ✅ | ❌ |
| Necesita re-firmar cada 7d | ✅ | ❌ |
| Interfaz visual | ✅ (SwiftUI) | ❌ |
| Tiempo de setup | ~2 horas | ~20 minutos |
| Requiere Apple Developer | Apple ID gratuito | Nada |

---

## Limitaciones de esta alternativa

1. **Sin Siri**: No hay App Intents, así que no puedes invocar con voz
2. **Sin UI propia**: No hay app visual en tu iPhone
3. **Necesita internet**: Cada acción llama a Google
4. **Latencia**: Las requests a Apps Script tardan 1-3 segundos
5. **Cuotas de Apps Script**: 
   - 100 emails/día (cuenta gratuita)
   - 20,000 requests/día (más que suficiente)
6. **Token en URL**: Menos seguro que OAuth2 nativo (pero suficiente para uso personal)

---

## ¿Cuál elegir?

- **Solo quiero automatizar rápido** → Apps Script (esta guía)
- **Quiero Siri + interfaz visual + experiencia nativa** → App nativa + buscar acceso a Mac
- **Quiero ambas** → Empezar con Apps Script, y cuando tengas acceso a Mac, compilar la app nativa
