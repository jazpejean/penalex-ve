allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// AGP 8+ exige namespace en todos los módulos. Los plugins de Flutter antiguos
// (p. ej. edge_detection 1.1.3) no lo declaran: usamos su group (package
// original) para que el R generado coincida con los paquetes de su código.
subprojects {
    plugins.withId("com.android.library") {
        extensions.configure<com.android.build.gradle.LibraryExtension> {
            // Alinear compileSdk de los plugins con el del app (36). Evita
            // "resource android:attr/lStar not found" en google_mlkit_commons
            // (compila con SDK < 33, pero dependencias como material usan lStar).
            compileSdk = 36
            if (namespace == null) {
                val grupo = project.group.toString()
                namespace = if (grupo.isNotEmpty() && grupo != "unspecified") {
                    grupo
                } else {
                    "com.penalex.ve.${project.name.replace("-", "")}"
                }
            }
        }
    }
}

// Alinear el jvmTarget de Kotlin al target de Java que cada subproyecto defina,
// evitando "Inconsistent JVM Target Compatibility" (edge_detection 1.8,
// flutter_doc_scanner 17, audioplayers_android 1.8, google_mlkit_commons 1.8…).
// Se lee en projectsEvaluated, cuando compileOptions ya está finalizado, y no se
// fuerza ningún valor: solo se replica el target de Java del propio plugin.
gradle.projectsEvaluated {
    subprojects {
        if (extensions.findByName("android") != null) {
            val android = extensions.getByName("android") as com.android.build.gradle.BaseExtension
            val javaTarget = android.compileOptions.targetCompatibility.toString()
            tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
                compilerOptions {
                    jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.fromTarget(javaTarget))
                }
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
