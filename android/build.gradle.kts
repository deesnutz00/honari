buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.8.10")
        classpath("com.android.tools.build:gradle:8.1.0") // or your current Gradle plugin version
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
