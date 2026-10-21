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

// Plugins antiguos (edge_detection) compilan Java a 1.8 pero Kotlin a 17:
// alineamos el jvmTarget de Kotlin con el de Java para evitar el error
// "Inconsistent JVM Target Compatibility".
subprojects {
    plugins.withId("org.jetbrains.kotlin.android") {
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            compilerOptions {
                jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_1_8)
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
