@echo off
chcp 65001 > nul
echo Preparando el proyecto Flutter Notificaciones...
where flutter >nul 2>nul
if errorlevel 1 (
  echo ERROR: Flutter no esta en el PATH. Instala Flutter y vuelve a ejecutar este archivo.
  pause
  exit /b 1
)
flutter create . --platforms=android --project-name notificaciones
if errorlevel 1 goto error
copy /Y config\AndroidManifest.xml android\app\src\main\AndroidManifest.xml >nul
powershell -NoProfile -ExecutionPolicy Bypass -File config\configurar_android.ps1
if errorlevel 1 goto error
flutter pub get
if errorlevel 1 goto error
echo.
echo Proyecto preparado. Ejecuta: flutter run
pause
exit /b 0
:error
echo Ocurrio un error. Revisa la instalacion de Flutter con flutter doctor.
pause
exit /b 1
