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
            // TODO: Para producción, configurar con keystore real
            // Descomentar y configurar las siguientes líneas:
            // storeFile = file("path/to/keystore.jks")
            // storePassword = System.getenv("KEYSTORE_PASSWORD")
            // keyAlias = System.getenv("KEY_ALIAS")
            // keyPassword = System.getenv("KEY_PASSWORD")
        }
    }

    buildTypes {
        getByName("release") {
            // Comentado temporalmente - usar debug signing para desarrollo
            // Para producción, descomentar y configurar signing release:
            // signingConfig = signingConfigs.getByName("release")
            
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
