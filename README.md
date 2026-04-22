# Penalex VE

Herramienta profesional para el cálculo de la dosimetría penal en Venezuela. Aplicación móvil desarrollada en Flutter con Firebase que permite a jueces, fiscales y abogados calcular penas, gestionar audiencias, realizar quizzes de derecho penal y generar reportes en PDF.

## 🚀 Características Principales

- **📊 Cálculo de Dosimetría Penal**: Conversión de penas en años, meses y días con aplicación de fracción beneficiosa.
- **⚖️ Concurso de Delitos**: Cálculo de penas en casos de concurso real e ideal.
- **📅 Agenda Judicial**: Gestión de audiencias con notificaciones push.
- **🧠 Quiz de Derecho Penal**: Sistema gamificado con niveles, ranking global y logros.
- **📄 Generación de PDFs**: Exportación de cálculos y reportes profesionales.
- **🔐 Autenticación Segura**: Login con email/Google y verificación de dispositivo.
- **🏆 Sistema de Rangos**: Jerarquía judicial desde "Alguacil de Sala" hasta "Presidente Emérito".

## 🛠️ Tecnologías

- **Flutter 3.3+** - Framework multiplataforma
- **Firebase** - Backend como servicio
  - Authentication (email/Google)
  - Firestore (base de datos)
  - Storage (archivos)
  - Cloud Messaging (notificaciones)
- **Provider** - Gestión de estado
- **PDF** - Generación de documentos
- **Table Calendar** - Agenda visual

## 📁 Estructura del Proyecto

```
lib/
├── config/           # Configuración de temas, colores, tipografía
├── logic/            # Lógica de negocio (dosimetría, reportes)
├── models/           # Modelos de datos (Delito, User, Question, etc.)
├── pages/            # Pantallas de la aplicación
├── providers/        # State management con Provider
├── services/         # Servicios (Firebase, PDF, Audio, etc.)
├── utils/            # Utilidades (fechas, cálculos, storage)
└── widgets/          # Componentes reutilizables
```

## ⚙️ Configuración del Entorno

### 1. Prerrequisitos

- Flutter SDK 3.3.0 o superior
- Android Studio / Xcode (para builds nativos)
- Cuenta de Firebase

### 2. Configuración de Firebase

1. Crear proyecto en [Firebase Console](https://console.firebase.google.com/)
2. Añadir aplicaciones Android y Web
3. Descargar `google-services.json` y colocarlo en `android/app/`
4. Copiar las claves de configuración al archivo `.env`:

```bash
# Firebase Configuration
FIREBASE_API_KEY_ANDROID=tu_api_key_android
FIREBASE_APP_ID_ANDROID=tu_app_id_android
FIREBASE_MESSAGING_SENDER_ID=tu_sender_id
FIREBASE_PROJECT_ID=tu_project_id
FIREBASE_STORAGE_BUCKET=tu_storage_bucket

# Firebase Web Configuration
FIREBASE_API_KEY_WEB=tu_api_key_web
FIREBASE_AUTH_DOMAIN=tu_auth_domain

# App Configuration
APP_NAME=Penalex VE
APP_VERSION=1.0.0
```

### 3. Instalación de Dependencias

```bash
flutter pub get
```

### 4. Ejecutar la Aplicación

```bash
# Desarrollo
flutter run

# Build para Android
flutter build apk --release

# Build para iOS
flutter build ios --release
```

## 🔍 Análisis de Código

El proyecto usa reglas de linting extensivas basadas en `flutter_lints`:

```bash
# Análisis estático
dart analyze

# Corregir problemas automáticamente
dart fix --apply
```

## 🐛 Solución de Problemas

### Problemas Comunes

1. **Error de claves de Firebase**: Verificar que el archivo `.env` contenga todas las variables necesarias.
2. **Permisos de Android**: Asegurar que `android/app/src/main/AndroidManifest.xml` tenga los permisos necesarios.
3. **Dependencias conflictivas**: Ejecutar `flutter clean` y `flutter pub get`.

### Errores de Build

- **iOS**: Asegurar que CocoaPods esté actualizado: `pod repo update`
- **Android**: Verificar que la versión de Gradle sea compatible.

## 📱 Capturas de Pantalla

*(Agregar capturas de pantalla de la aplicación aquí)*

## 🔄 Flujo de Trabajo de Desarrollo

1. **Crear rama** para nuevas características: `git checkout -b feature/nueva-funcionalidad`
2. **Hacer commits** descriptivos: `git commit -m "feat: añade cálculo de concurso"`
3. **Verificar análisis**: `dart analyze`
4. **Crear Pull Request** para revisión

## 📄 Licencia

Este proyecto es de uso interno para profesionales del derecho en Venezuela. No está destinado para distribución pública.

## 🤝 Contribución

1. Fork el proyecto
2. Crear rama de feature (`git checkout -b feature/AmazingFeature`)
3. Commit cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abrir Pull Request

## 📞 Soporte

Para soporte técnico o consultas sobre el proyecto, contactar al equipo de desarrollo.

---

**Penalex VE** - Herramienta profesional para el sistema judicial venezolano ⚖️🇻🇪