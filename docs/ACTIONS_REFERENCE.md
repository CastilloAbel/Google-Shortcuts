# 📖 Referencia Rápida - Todas las Acciones Disponibles

## 📊 Tabla Resumen de Acciones

### 🔋 Batería (4 acciones)

| Acción | Parámetros | Devolución | Ejemplo |
|--------|-----------|-----------|---------|
| Obtener nivel de batería | Ninguno | Número 0-100 | 73 |
| ¿Batería baja? | Umbral (%) [def: 20] | true/false | true |
| Estado de batería | Ninguno | "charging"/"full"/"unplugged" | "charging" |
| ¿Modo bajo consumo? | Ninguno | true/false | false |

### 📡 Conectividad (4 acciones)

| Acción | Parámetros | Devolución | Ejemplo |
|--------|-----------|-----------|---------|
| ¿Bluetooth encendido? | Ninguno | true/false | true |
| ¿WiFi encendido? | Ninguno | true/false | true |
| ¿VPN conectado? | Ninguno | true/false | false |
| ¿Datos móviles? | Ninguno | true/false | true |

### 📱 Dispositivo (3 acciones)

| Acción | Parámetros | Devolución | Ejemplo |
|--------|-----------|-----------|---------|
| Modelo de dispositivo | Ninguno | String | "iPhone 15 Pro" |
| Nombre del dispositivo | Ninguno | String | "iPhone de Abel" |
| Versión de iOS | Ninguno | String | "17.4.1" |

### 🌐 Red & Almacenamiento (5 acciones)

| Acción | Parámetros | Devolución | Ejemplo |
|--------|-----------|-----------|---------|
| ¿Conectado a internet? | Ninguno | true/false | true |
| Tipo de conexión | Ninguno | "wifi"/"cellular"/"unavailable" | "wifi" |
| Espacio disponible | Ninguno | Número (GB) | 45.2 |
| Almacenamiento total | Ninguno | Número (GB) | 128.0 |
| Brillo de pantalla | Ninguno | 0-100 (%) | 75 |

### 🎨 Pantalla & Preferencias (3 acciones)

| Acción | Parámetros | Devolución | Ejemplo |
|--------|-----------|-----------|---------|
| ¿Modo oscuro? | Ninguno | true/false | false |
| ¿Tiene notch/isla dinámica? | Ninguno | true/false | true |
| [Pendiente] Brillo automático | Ninguno | true/false | true |

### ✉️ Gmail (5 acciones - Requiere autenticación)

| Acción | Parámetros | Devolución | Nota |
|--------|-----------|-----------|------|
| Enviar correo | to, subject, body | Success/Error msg | Requiere auth |
| Ver últimos correos | count (def: 10) | [Email objects] | Requiere auth |
| Buscar correos | query | [Email objects] | Requiere auth |
| Verificar correos nuevos | Ninguno | true/false | Requiere auth |
| Contar no leídos | Ninguno | Número | Requiere auth |

---

## 🎯 Cómo Usarlas en Atajos

### Acceder a una acción

```
1. Abre app "Atajos" (Shortcuts)
2. Crea un nuevo atajo (Tapón +)
3. Haz clic: Añadir acción
4. Busca: "GmailShortcuts" o nombre de la acción
5. Selecciona la acción
6. Configura parámetros si los hay
```

### Conexiones entre acciones

```
Acción A (devolución) → Acción B (parámetro entrada)

Ejemplo:
├─ Obtener nivel batería (devuelve: 73)
│  ↓
├─ ¿Es > 50? (pregunta: ¿nivel > 50?)
│  ├─ SÍ → Enviar correo
│  └─ NO → Mostrar alerta "Batería baja"
```

---

## 💡 Patrones Útiles

### Patrón 1: Condicional Simple

```
Acción A (boolean)
├─ SÍ → Acción B
└─ NO → Acción C
```

**Ejemplo:**
```
¿WiFi encendido?
├─ SÍ → "Descargar archivo"
└─ NO → "Esperar WiFi"
```

### Patrón 2: Múltiples Condiciones

```
SI (Condición 1) Y (Condición 2)
   → Acción X
SINO
   → Acción Y
```

**Ejemplo:**
```
SI (Nivel batería > 20%) Y (¿WiFi? = true)
   → Enviar correo
SINO
   → Guardar borrador
```

### Patrón 3: Loop Temporal

```
Repetir cada [X minutos]
   → Verificar acción
   → Si condición → hacer algo
```

**Ejemplo:**
```
Cada 30 minutos:
   → ¿Correos nuevos?
   → SI → Mostrar notificación
```

---

## 🔥 Ejemplos Prácticos

### Ejemplo 1: No enviar en roaming

```
"Enviar email de forma segura"

1. ¿Tipo de conexión? = "cellular"
   SÍ → Mostrar: "¿Estás en roaming? (caro)"
        Preguntar usuario
        SI → continuar
        NO → abortar
   NO → continuar

2. Enviar correo
```

### Ejemplo 2: Monitorear batería

```
"Monitoreo autom. cada hora"

Repetir cada hora:
   1. Obtener nivel batería
   2. SI < 20%
      → Mostrar "Batería crítica"
   3. SI < 50% Y Modo bajo consumo = false
      → Sugerir activar modo bajo consumo
```

### Ejemplo 3: Sincronización inteligente

```
"Sincronizar correos (coste optimizado)"

Cada 5 minutos:
   1. SI WiFi encendido
      → Sincronizar todo
   2. SI Datos móviles Y Bajo consumo = true
      → Sincronizar solo asuntos (no adjuntos)
   3. SI Batería < 10%
      → Pausar sincronización
```

### Ejemplo 4: Resumen matutino

```
"Resumen del dispositivo a las 8 AM"

1. Obtener:
   - Nivel batería
   - Últimos correos (3)
   - Espacio disponible
   - Versión iOS
   
2. Formatear: "Buenos días Abel:
              Batería: XX%
              Correos: 3 nuevos
              Espacio: XX GB
              iOS: XX.X"
              
3. Mostrar en notificación
```

---

## ⚙️ Tipos de Datos

### Boolean (true/false)
| Acción | Devuelve |
|--------|----------|
| ¿Batería baja? | true / false |
| ¿Bluetooth? | true / false |
| ¿WiFi? | true / false |
| ¿Online? | true / false |
| ¿Modo oscuro? | true / false |

### String (texto)
| Acción | Ejemplo |
|--------|---------|
| Modelo | "iPhone 15 Pro" |
| Nombre | "iPhone de Abel" |
| iOS version | "17.4.1" |
| Estado batería | "charging" |
| Tipo conexión | "wifi" |

### Number (número)
| Acción | Rango | Unidad |
|--------|-------|--------|
| Nivel batería | 0-100 | % |
| Espacio libre | any | GB |
| Almacén total | any | GB |
| Brillo pantalla | 0-100 | % |

---

## 🚫 Limitaciones Conocidas

### No se puede hacer:
- ❌ Encender/apagar Bluetooth
- ❌ Conectarse a WiFi automáticamente
- ❌ Activar/desactivar modo avión
- ❌ Cambiar volumen del sistema
- ❌ Activar linterna (Apple lo bloquea)

### Funciona parcialmente:
- ⚠️ Bluetooth: Solo detectar si está ON, no ver dispositivos
- ⚠️ Audio: Solo ver destino, no cambiar
- ⚠️ Motion: Requiere permisos extras no incluidos

---

## 📌 Tips de Atajos

### Tip 1: Usar variables

```
1. Obtener nivel batería → guardar en variable %Battery
2. %Battery > 50? → comparar
3. Usar %Battery en otros lugares
```

### Tip 2: Logging/Debugging

```
Inicio de atajo:
  1. Obtener nivel batería → log
  2. Tipo conexión → log
  3. iOS version → log
Esto ayuda si luego falla
```

### Tip 3: Crear acciones reutilizables

```
Crear "Validar device state"
  INPUT: min_battery, require_wifi
  
  LOGIC:
  - Verificar batería
  - Verificar WiFi
  - Devolver: true (todo OK) / false (algo falta)
  
Luego llamar de otros atajos
```

---

## 🔗 Enlaces Útiles

- [Device Actions - Guía Completa](DEVICE_ACTIONS.md)
- [Ejemplos Avanzados](ARCHITECTURE_V2.md)
- [Troubleshooting](COMPILATION_GUIDE_V2.md#debugging)

---

**Última actualización**: 7 de abril de 2026  
**Versión**: v2.0 Actions Reference

