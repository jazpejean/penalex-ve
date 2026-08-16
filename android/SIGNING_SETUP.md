# Configuración de Firma de Release para Android

Este documento explica cómo configurar la firma de release para publicar la aplicación en Google Play Store.

## ⚠️ Estado Actual
La aplicación actualmente **NO** tiene configurado un signing de release. Esto significa que no se puede publicar en producción.

## 📋 Pasos para Configurar Signing de Release

### 1. Generar Keystore
Ejecuta el siguiente comando para generar un keystore:

```bash
keytool -genkey -v -keystore ~/penalex-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias penalex-key
```

**Importante:** Guarda de forma segura:
- La contraseña del keystore
- La contraseña de la clave
- El alias de la clave

### 2. Crear archivo key.properties
Crea el archivo `android/key.properties` (este archivo NO debe estar en git):

```properties
storePassword=TU_CONTRASEÑA_KEYSTORE
keyPassword=TU_CONTRASEÑA_CLAVE
keyAlias=penalex-key
storeFile=/ruta/completa/a/penalex-release-key.jks
```

### 3. Agregar key.properties al .gitignore
Asegúrate de que `android/key.properties` esté en el `.gitignore`:

```
**/android/key.properties
```

### 4. Actualizar build.gradle.kts
Descomentar y actualizar la configuración en `android/app/build.gradle.kts`:

```kotlin
// Cargar propiedades del keystore
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    // ... configuración existente ...
    
    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
            }
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}
```

### 5. Compilar Release APK
Una vez configurado, compila el APK de release:

```bash
flutter build apk --release
```

O para App Bundle (recomendado para Google Play):

```bash
flutter build appbundle --release
```

## 🔐 Seguridad
- **NUNCA** subas el archivo `.jks` al repositorio
- **NUNCA** subas el archivo `key.properties` al repositorio
- Guarda backups seguros del keystore en múltiples ubicaciones
- Si pierdes el keystore, no podrás actualizar la app en Google Play Store

## 📚 Referencias
- [Documentación oficial de Flutter](https://docs.flutter.dev/deployment/android#signing-the-app)
- [Documentación de Android sobre App Signing](https://developer.android.com/studio/publish/app-signing)
