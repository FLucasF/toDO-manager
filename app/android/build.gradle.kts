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
// Plugins com compileSdk antigo (ex.: keyboard_height_plugin, do appflowy_editor, declara 31) quebram a
// checagem de AAR das dependências androidx atuais. Força o mesmo compileSdk do app em todos os plugins.
subprojects {
    val forcarCompileSdk: Project.() -> Unit = {
        (extensions.findByName("android") as? com.android.build.gradle.BaseExtension)?.compileSdkVersion(36)
    }
    if (state.executed) forcarCompileSdk() else afterEvaluate { forcarCompileSdk() }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
