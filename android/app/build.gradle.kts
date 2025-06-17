plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// --- BLOCO ADICIONADO ---
// Importa as classes Java necessárias
import java.util.Properties
        import java.io.FileInputStream

// Carrega as propriedades do arquivo key.properties
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
// --- FIM DO BLOCO ADICIONADO ---

dependencies {
    // Import the Firebase BoM (Bill of Materials) para gerenciar as versões das dependências do Firebase
    implementation(platform("com.google.firebase:firebase-bom:33.15.0"))

    // Adicione as dependências dos produtos Firebase que você usa.
    // Quando usando o BoM, você não precisa especificar as versões aqui.
    implementation("com.google.firebase:firebase-messaging-ktx")
    implementation("com.google.firebase:firebase-analytics-ktx")


    // TODO: Adicione outras dependências se for usar mais produtos Firebase no futuro
    // Ex: implementation("com.google.firebase:firebase-firestore-ktx")
}

android {
    // O namespace é obrigatório para as versões mais recentes do Android Gradle Plugin (AGP)
    // Ele deve corresponder ao seu applicationId
    namespace = "com.example.vibration_app"

    // Define a versão do SDK de compilação baseada na configuração do Flutter
    compileSdk = flutter.compileSdkVersion

    // Define a versão do NDK para resolver compatibilidade com alguns plugins
    ndkVersion = "27.0.12077973"

    // --- BLOCO ADICIONADO ---
    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }
    // --- FIM DO BLOCO ADICIONADO ---

    // Configura as opções de compatibilidade de source e target Java
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11 // Recomendado usar Java 11 ou mais recente
        targetCompatibility = JavaVersion.VERSION_11
    }

    // Configura as opções Kotlin para compatibilidade com o Java Target
    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // ID único do seu aplicativo no Google Play Store
        applicationId = "com.example.vibration_app"

        // Versões mínimas e alvo do SDK, e código/nome da versão do app
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // --- LINHA ALTERADA ---
            // Aponta para a nossa configuração de assinatura de release, em vez de 'debug'
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.." // Indica onde o código-fonte Flutter está localizado
}