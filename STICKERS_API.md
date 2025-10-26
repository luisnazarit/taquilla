# 🎨 Sistema de Stickers desde API

## 📋 Configuración

### 1. URL del Endpoint
Para cambiar la URL del endpoint, edita el archivo `Taquilla/Models.swift`:

```swift
// 🔧 CONFIGURACIÓN: Cambia esta URL para apuntar a tu endpoint
private let stickersEndpoint = "https://api.example.com/stickers"
```

**Reemplaza `https://api.example.com/stickers` con tu URL real.**

---

## 🌐 Estructura del Endpoint

### **URL:** `GET /stickers`

### **Respuesta esperada:**
```json
{
  "stickers": [
    {
      "name": "emoji_feliz",
      "url": "https://cdn.example.com/stickers/emoji_feliz.png",
      "thumbnail": "https://cdn.example.com/stickers/thumbs/emoji_feliz.png"
    },
    {
      "name": "corazon",
      "url": "https://cdn.example.com/stickers/corazon.png",
      "thumbnail": "https://cdn.example.com/stickers/thumbs/corazon.png"
    },
    {
      "name": "estrella",
      "url": "https://cdn.example.com/stickers/estrella.png",
      "thumbnail": "https://cdn.example.com/stickers/thumbs/estrella.png"
    }
  ]
}
```

### **Campos requeridos:**

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `name` | `string` | Nombre único del sticker (se usa como identificador) |
| `url` | `string` | URL completa de la imagen PNG del sticker |
| `thumbnail` | `string` | URL de la miniatura (opcional, para previews) |

---

## 🖼️ Especificaciones de Imágenes

### **Formato:** PNG con transparencia
### **Tamaño recomendado:** 200x200px a 400x400px
### **Tamaño máximo:** 1MB por imagen
### **Transparencia:** Soporte completo para PNG con canal alpha

---

## 🔧 Ejemplo de Implementación del Servidor

### **Node.js + Express:**
```javascript
const express = require('express');
const app = express();

app.get('/stickers', (req, res) => {
  res.json({
    stickers: [
      {
        name: "emoji_feliz",
        url: "https://tu-cdn.com/stickers/emoji_feliz.png",
        thumbnail: "https://tu-cdn.com/stickers/thumbs/emoji_feliz.png"
      },
      {
        name: "corazon",
        url: "https://tu-cdn.com/stickers/corazon.png",
        thumbnail: "https://tu-cdn.com/stickers/thumbs/corazon.png"
      }
    ]
  });
});

app.listen(3000, () => {
  console.log('API de stickers corriendo en puerto 3000');
});
```

### **Python + Flask:**
```python
from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/stickers')
def get_stickers():
    return jsonify({
        "stickers": [
            {
                "name": "emoji_feliz",
                "url": "https://tu-cdn.com/stickers/emoji_feliz.png",
                "thumbnail": "https://tu-cdn.com/stickers/thumbs/emoji_feliz.png"
            },
            {
                "name": "corazon", 
                "url": "https://tu-cdn.com/stickers/corazon.png",
                "thumbnail": "https://tu-cdn.com/stickers/thumbs/corazon.png"
            }
        ]
    })

if __name__ == '__main__':
    app.run(debug=True)
```

---

## 📱 Funcionalidades de la App

### **Carga automática:**
- Los stickers se cargan cuando el usuario toca el botón "Stickers"
- Se hace una petición HTTP GET al endpoint configurado
- Se muestra un loading mientras se cargan las imágenes

### **Gestos soportados:**
- **Arrastrar:** Mover el sticker por la imagen
- **Pinch:** Escalar el sticker (0.3x a 4.0x)
- **Doble tap:** Eliminar el sticker
- **Botón X:** Eliminar el sticker

### **Persistencia:**
- Los stickers se mantienen al cambiar filtros
- Se incluyen en la imagen final al guardar/compartir

---

## 🚀 Ventajas del Sistema API

### ✅ **Escalabilidad:**
- Agregar nuevos stickers sin actualizar la app
- Gestión centralizada de contenido
- Actualizaciones en tiempo real

### ✅ **Flexibilidad:**
- Cambiar stickers dinámicamente
- A/B testing de contenido
- Personalización por usuario/región

### ✅ **Mantenimiento:**
- No requiere actualizaciones de app
- Gestión de contenido desde backend
- Monitoreo de uso y popularidad

---

## 🔍 Debugging

### **Logs en consola:**
```
🌐 Cargando stickers desde: https://tu-api.com/stickers
✅ Stickers cargados exitosamente: 5
```

### **Errores comunes:**
- **URL inválida:** Verificar que la URL esté bien formada
- **Error HTTP:** Verificar que el servidor esté funcionando
- **JSON inválido:** Verificar la estructura de la respuesta
- **Imágenes no cargan:** Verificar URLs de imágenes y CORS

---

## 📝 Notas de Implementación

1. **CORS:** Asegúrate de que tu servidor permita peticiones desde la app
2. **HTTPS:** Usa HTTPS en producción para seguridad
3. **Caché:** Considera implementar caché en el servidor
4. **CDN:** Usa un CDN para servir las imágenes rápidamente
5. **Monitoreo:** Implementa logging para monitorear el uso

---

## 🎯 Próximos Pasos

1. **Configurar tu endpoint** con la estructura JSON requerida
2. **Subir imágenes PNG** a tu servidor/CDN
3. **Actualizar la URL** en `Models.swift`
4. **Probar la funcionalidad** en la app
5. **Monitorear logs** para verificar que funciona correctamente
