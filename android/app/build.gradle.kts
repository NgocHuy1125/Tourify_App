import org.gradle.api.JavaVersion

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    // Plugin cần thiết để kết nối với Firebase
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.tourify_app"
    // Sử dụng biến compileSdk từ Flutter, thường là 34
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973" // Giữ nguyên phiên bản ndk của bạn

    compileOptions {
        // Sử dụng cú pháp Kotlin đúng
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        // Sử dụng cú pháp Kotlin đúng
        jvmTarget = "1.8"
    }

    defaultConfig {
        applicationId = "com.example.tourify_app"
        
        // **THIẾT LẬP QUAN TRỌNG**
        // Phiên bản Android tối thiểu, bắt buộc là 23 cho firebase_auth
        minSdk = 23
        
        // Sử dụng biến targetSdk từ Flutter
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // Firebase Bill of Materials (BOM) - Quản lý phiên bản các thư viện Firebase
    implementation(platform("com.google.firebase:firebase-bom:33.1.1"))

    // Thư viện cần thiết cho Google Analytics
    implementation("com.google.firebase:firebase-analytics")

    // Thư viện bắt buộc cho các tính năng xác thực (đăng nhập, đăng ký)
    implementation("com.google.firebase:firebase-auth")
}

flutter {
    source = "../.."
}