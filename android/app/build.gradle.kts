// Importa as classes Java necessárias para o script.
import java.util.Properties
import java.io.FileInputStream

// Define os plugins necessários para a aplicação Android, Kotlin e Flutter.
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services") // Plugin do Google Services para o Firebase
    id("dev.flutter.flutter-gradle-plugin")
}

// Carrega as propriedades do arquivo key.properties de forma segura.
// Este bloco garante que o build não falhe se o arquivo não existir.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    // Namespace obrigatório para o Android Gradle Plugin. Deve corresponder ao ID da aplicação.
    namespace = "com.example.vibration_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973" // Versão do NDK, pode ser necessária para alguns pacotes.

    // Configuração da assinatura digital para a versão de lançamento (release).
    signingConfigs {
        create("release") {
            // Apenas configura a assinatura se o arquivo key.properties existir.
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    compileOptions {
        // Define a compatibilidade do código-fonte para Java 11.
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        // Habilita o "desugaring" para usar APIs modernas do Java em versões antigas do Android.
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        // Alinha a versão do Kotlin com a do Java.
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId = "com.example.vibration_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Adiciona ofuscação e minificação de código para a versão de release.
            // Isso torna o app menor e mais seguro.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")

            // Associa a configuração de assinatura 'release' a este tipo de build.
            // Esta é a linha que corrige o erro original.
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Importa o Firebase Bill of Materials (BoM) para gerenciar as versões das dependências.
    implementation(platform("com.google.firebase:firebase-bom:33.1.0"))

    // Dependências dos produtos Firebase utilizados no app.
    // As versões são gerenciadas pelo BoM.
    implementation("com.google.firebase:firebase-analytics-ktx")
    implementation("com.google.firebase:firebase-messaging-ktx")
    implementation("com.google.firebase:firebase-firestore-ktx") // Adicionado, pois seu app usa Firestore.

    // Dependência para o "desugaring" das bibliotecas do JDK.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}