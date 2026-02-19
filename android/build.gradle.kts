allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory
    .dir("../../build")
    .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    buildscript {
        configurations.classpath {
            resolutionStrategy.eachDependency {
                if (requested.group == "com.android.tools.build" &&
                    requested.name == "gradle") {
                    useVersion("8.11.1")
                }
            }
        }
    }

    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)




    afterEvaluate {
        if (extensions.findByName("android") != null) {
            try {
                configure<com.android.build.gradle.BaseExtension> {
                    if (namespace == null) {
                        namespace = project.group.toString()
                    }
                }
            } catch (e: Exception) {

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
