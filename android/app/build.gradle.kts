plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Add the Google services Gradle plugin
    id("com.google.gms.google-services")
}

dependencies {
    // Import the Firebase BoM (version stable et compatible)
    implementation(platform("com.google.firebase:firebase-bom:33.7.0"))

    // Add the Firebase SDKs you want to use
    // When using the BoM, don't specify versions in Firebase library dependencies
    implementation("com.google.firebase:firebase-analytics-ktx")
    implementation("com.google.firebase:firebase-firestore-ktx")
    implementation("com.google.firebase:firebase-auth-ktx")

    // Core library desugaring for flutter_local_notifications
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    // Add multidex support for older Android versions
    implementation("androidx.multidex:multidex:2.0.1")
}

android {
    namespace = "dev.ekdev.fondationokoukroapp"
    compileSdk = 35
    // Ne spécifiez pas ndkVersion - Flutter utilisera la version par défaut

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        // Update with your actual application ID from Firebase
        applicationId = "dev.ekdev.fondationokoukroapp"
        minSdk = 23  // Firebase Auth requires minSdk 23
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Enable multidex for older Android versions
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")

            // Enable ProGuard for release builds
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug {
            isMinifyEnabled = false
        }
    }

    // Suppression des avertissements de dépréciation
    lint {
        checkReleaseBuilds = false
        abortOnError = false
        disable += "Deprecation"
    }

    // Optimisation du packaging
    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
            excludes += "/META-INF/DEPENDENCIES"
        }
    }
}

flutter {
    source = "../.."
}