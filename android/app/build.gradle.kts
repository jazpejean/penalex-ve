plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.penalex.ve"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.penalex.ve"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Configuración de signing para release
    signingConfigs {
        create("release") {
            // Keystore de release: en CI se inyecta desde secrets (KEYSTORE_BASE64),
            // en local se usa el archivo android/app/keystore/penalex-release.jks
            val storeFileEnv = System.getenv("KEYSTORE_FILE")
            val keystoreFile = if (storeFileEnv != null && storeFileEnv.isNotEmpty()) {
                file(storeFileEnv)
            } else {
                file("keystore/penalex-release.jks")
            }
            if (keystoreFile.exists()) {
                storeFile = keystoreFile
                storePassword = System.getenv("KEYSTORE_PASSWORD") ?: ""
                keyAlias = System.getenv("KEY_ALIAS") ?: "penalex"
                // Keystore PKCS12: store y key usan la MISMA contraseña
                keyPassword = System.getenv("KEYSTORE_PASSWORD") ?: ""
            }
        }
    }

    buildTypes {
        getByName("release") {
            // Firmar release con el keystore propio (CI inyecta el keystore desde secrets)
            signingConfig = signingConfigs.getByName("release")

            // Optimizaciones para release
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    // Aceleración de tareas de compilación Java
    tasks.withType<JavaCompile> {
        options.compilerArgs.add("-Xlint:-options")
        options.isIncremental = true
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
