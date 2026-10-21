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

// Alinear JVM targets de Java y Kotlin en todos los subproyectos para evitar
// "Inconsistent JVM Target Compatibility" (edge_detection y flutter_doc_scanner).
subprojects {
    plugins.withId("com.android.library") {
        extensions.configure<com.android.build.gradle.LibraryExtension> {
            compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }
        }
    }
    plugins.withId("org.jetbrains.kotlin.android") {
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            compilerOptions {
                jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
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
