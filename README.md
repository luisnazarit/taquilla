# 🎨 Taquilla - Editor de Fotos

Una aplicación iOS para editar fotos con filtros, textos arrastrables y efectos.

## 🚀 Cómo Abrir el Proyecto

1. **Abre Xcode**
2. **File → Open**
3. **Navega a la carpeta del proyecto**
4. **Selecciona `Taquilla.xcodeproj`**
5. **Haz clic en "Open"**

## 📱 Características

### ✅ Editor de Fotos (Completado)
- **Selector de Imágenes**: Acceso a la galería de fotos
- **8 Filtros Profesionales**: Vintage, B&W, Sepia, Vivid, Cool, Warm, Dramatic
- **Textos Arrastrables**: Agregar y mover textos por la imagen
- **Editor de Texto Avanzado**: 
  - Cambiar contenido, color, tamaño y estilo
  - Vista previa en tiempo real
- **Guardado**: Las fotos editadas se guardan en la galería

### 🔄 En Desarrollo
- **Collage**: Crear collages con múltiples fotos
- **Galería**: Ver todas las fotos editadas

## 🛠️ Requisitos Técnicos

- **iOS 17.0+**
- **Xcode 15.0+**
- **Swift 5.0+**

## 📋 Permisos Necesarios

La aplicación solicita los siguientes permisos:
- **Galería de Fotos**: Para seleccionar imágenes
- **Cámara**: Para tomar fotos (opcional)
- **Guardar en Galería**: Para guardar fotos editadas

## 🎯 Cómo Usar

1. **Seleccionar Foto**: Toca el botón "Foto" para elegir una imagen
2. **Aplicar Filtros**: Usa el botón "Filtros" para ver opciones
3. **Agregar Texto**: Toca "Texto" para agregar texto arrastrable
4. **Editar Texto**: Toca cualquier texto para abrir el editor
5. **Guardar**: Usa el botón "Guardar" para guardar la imagen

## 📁 Estructura del Proyecto

```
Taquilla/
├── TaquillaApp.swift          # App principal
├── ContentView.swift          # Navegación por pestañas
├── PhotoEditorView.swift      # Editor principal
├── Models.swift               # Modelos de datos y filtros
├── ImagePicker.swift          # Selector de imágenes
├── TextEditorView.swift       # Editor de texto
├── FilterPreviewView.swift    # Vista previa de filtros
├── CollageView.swift          # Vista collage (placeholder)
├── GalleryView.swift          # Vista galería (placeholder)
├── Info.plist                # Configuración y permisos
└── Assets.xcassets           # Recursos de la app
```

## 🔧 Desarrollo

Para ejecutar la aplicación:
1. Abre `Taquilla.xcodeproj` en Xcode
2. Selecciona un simulador o dispositivo
3. Presiona ⌘+R para ejecutar

¡Disfruta editando tus fotos! 📸✨

# taquilla
