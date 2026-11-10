allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// firebase_app_check 0.4.9+ needs RecaptchaAppCheckProviderFactory.getInstance(siteKey)
// and InternalDebugSecretProvider (Firebase Android BoM >= 34.17 / 35.x).
extra["FlutterFire"] = hashMapOf("FirebaseSDKVersion" to "35.1.0")

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
