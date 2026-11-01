allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// firebase_app_check 0.4.5+ needs App Check APIs from BOM >= 34.16.0
// (InternalDebugSecretProvider). Overrides firebase_core's default 34.15.0.
extra["FlutterFire"] = hashMapOf("FirebaseSDKVersion" to "34.16.0")

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
