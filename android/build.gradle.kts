import java.util.Properties
import java.io.File

// 1. Đọc file .env để lấy Mapbox Download Token
val env = Properties()
val envFile = File(rootProject.projectDir, "../.env")
if (envFile.exists()) {
    envFile.inputStream().use { env.load(it) }
}
val mapboxToken = env.getProperty("MAPBOX_DOWNLOADS_TOKEN") ?: ""

// 2. Cung cấp Token cho Plugin Mapbox qua biến extra (Dùng cho cả Gradle 7 & 8)
if (mapboxToken.isNotEmpty()) {
    extra.set("SDK_REGISTRY_TOKEN", mapboxToken)
}

allprojects {
    repositories {
        google()
        mavenCentral()
        // Repository của Mapbox yêu cầu authentication
        maven {
            url = uri("https://api.mapbox.com/downloads/v2/releases/maven")
            authentication {
                create<BasicAuthentication>("basic")
            }
            credentials {
                username = "mapbox"
                password = mapboxToken
            }
        }
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
    
    project.evaluationDependsOn(":app")

    // Fix lỗi Namespace cho các thư viện nếu cần (Đảm bảo chạy được trên AGP 8+)
    project.plugins.withId("com.android.library") {
        fixNamespaceAndManifest(project)
    }
    project.plugins.withId("com.android.application") {
        fixNamespaceAndManifest(project)
    }

    // Ép Java 17 cho Task (Cấu hình "hiền" để đồng nhất với app)
    tasks.withType<JavaCompile>().configureEach {
        sourceCompatibility = "17"
        targetCompatibility = "17"
    }
}

fun fixNamespaceAndManifest(project: Project) {
    val android = project.extensions.findByName("android")
    if (android != null) {
        try {
            val getNamespace = android.javaClass.getMethod("getNamespace")
            val setNamespace = android.javaClass.getMethod("setNamespace", String::class.java)
            if (getNamespace.invoke(android) == null) {
                val ns = "com.traveladvisor.fix.${project.name.replace("-", "_").replace(":", "_")}"
                setNamespace.invoke(android, ns)
            }

            project.tasks.matching { it.name.contains("process") && it.name.contains("Manifest") }.configureEach {
                doFirst {
                    val manifestFile = File(project.projectDir, "src/main/AndroidManifest.xml")
                    if (manifestFile.exists()) {
                        val content = manifestFile.readText()
                        if (content.contains("package=")) {
                            val newContent = content.replace(Regex("""package\s*=\s*"[^"]*""""), "")
                            manifestFile.writeText(newContent)
                        }
                    }
                }
            }
        } catch (e: Exception) {}
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
