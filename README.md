# Notificaciones — Ajolotito Hambriento

Proyecto Flutter basado en el manual **Ajolotito Hambriento: Notificaciones en Flutter bien hechas**.

Incluye notificaciones locales, canales de Android, permiso solicitado desde un botón, preferencias guardadas, horas de silencio (22:00–08:00), avisos programados, modo clase y pruebas unitarias.

## Requisitos

- Flutter estable con Dart 3.8 o superior.
- Android Studio (Android SDK y emulador) o un teléfono Android con depuración USB.
- VS Code con las extensiones Flutter y Dart.

## Preparar y ejecutar

1. Descomprime el ZIP.
2. Abre la carpeta `notificaciones` en VS Code.
3. Haz doble clic en `setup.bat` o ejecuta estos comandos en la terminal integrada:

```bash
flutter doctor
flutter create . --platforms=android --project-name notificaciones
flutter pub get
```

4. El script `setup.bat` también intenta activar automáticamente el desugaring requerido por el plugin en `android/app/build.gradle.kts`. Si prefieres hacerlo manualmente, dentro de `android { compileOptions { ... } }` agrega:

```kotlin
isCoreLibraryDesugaringEnabled = true
```

En el bloque `dependencies` agrega:

```kotlin
coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
```

Si ya existe un bloque `dependencies`, agrega la línea dentro del mismo. El `setup.bat` conserva/restaura el manifiesto Android con los permisos y receptores de notificaciones.

5. Conecta un teléfono Android o inicia un emulador y ejecuta:

```bash
flutter run
```

Para ejecutar las pruebas automáticas:

```bash
flutter test
```

## Probar las notificaciones

1. Abre la app y pulsa **Avísame cuando tenga hambre**.
2. Lee la explicación y pulsa **Sí, avísame** para solicitar el permiso del sistema.
3. Pulsa **Probar una notificación ahora** para comprobar que Android muestra avisos.
4. Abre Ajustes (engranaje) y activa **Modo clase**. La saciedad baja más rápido; minimiza la app para probar los avisos programados.
5. Puedes apagar por separado los avisos de hambre y las sorpresas.

Las notificaciones son locales: no necesitan API key, Firebase ni conexión a internet. El proyecto no implementa notificaciones push remotas.

## Estructura

```text
notificaciones/
├── android/app/src/main/AndroidManifest.xml
├── config/
│   ├── AndroidManifest.xml
│   ├── NOTA_ANDROID.txt
│   └── configurar_android.ps1
├── lib/
│   ├── dominio/
│   │   ├── mascota.dart
│   │   └── politica.dart
│   ├── infra/notificaciones_locales.dart
│   └── main.dart
├── test/
│   ├── mascota_test.dart
│   └── politica_test.dart
├── setup.bat
└── pubspec.yaml
```
