import org.gradle.api.tasks.Delete
import org.gradle.api.file.Directory

// ✅ Eliminamos cualquier bloque de "repositories" o "allprojects"

// Configura directorios de build
val newBuildDir: Directory = rootProject.layout.buildDirectory
    .dir("../../build")
    .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

// Tarea clean
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

