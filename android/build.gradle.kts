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

// Alinear el jvmTarget de Kotlin al target de Java que cada subproyecto defina,
// evitando "Inconsistent JVM Target Compatibility" (edge_detection 1.8,
// flutter_doc_scanner 17, audioplayers_android 1.8, etc.). Se aplica tras la
// evaluación para que los build.gradle propios de cada plugin no lo sobrescriban.
subprojects {
    afterEvaluate {
        if (extensions.findByName("android") != null) {
            val android = extensions.getByName("android") as com.android.build.gradle.LibraryExtension
            val javaTarget = android.compileOptions.targetCompatibility
            plugins.withId("org.jetbrains.kotlin.android") {
                tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
                    compilerOptions {
                        jvmTarget.set(
                            org.jetbrains.kotlin.gradle.dsl.JvmTarget.fromTarget(javaTarget.toString())
                        )
                    }
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
