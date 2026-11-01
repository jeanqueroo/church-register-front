@echo off
setlocal EnableExtensions EnableDelayedExpansion

REM Menú de compilación y ejecución — Manantial de Bendiciones
REM Docs: https://docs.flutter.dev/deployment/android

cd /d "%~dp0.."
set "ROOT=%CD%"

where flutter >nul 2>&1
if errorlevel 1 (
  echo [ERROR] Flutter no está en el PATH. Ejecuta: flutter doctor
  exit /b 1
)

if not "%~1"=="" goto :run_direct

:menu
echo.
echo ========================================
echo   Manantial de Bendiciones — Build
echo ========================================
echo   LOCAL — Android
echo     1^) Ejecutar debug ^(flutter run^)
echo     2^) Ejecutar release en dispositivo
echo     3^) Instalar release en dispositivo ^(flutter install^)
echo   LOCAL — iOS ^(requiere macOS + Xcode^)
echo     4^) Ejecutar debug
echo     5^) Ejecutar release en dispositivo
echo   STORES — Android
echo     6^) Google Play: App Bundle ^(.aab^) ★ recomendado
echo     7^) APK release ^(fat^)
echo     8^) APK release split por ABI
echo     9^) APK debug ^(pruebas rápidas^)
echo   STORES — iOS ^(requiere macOS + Xcode^)
echo    10^) App Store: IPA ^(flutter build ipa^)
echo    11^) iOS release sin codesign ^(pruebas^)
echo   HERRAMIENTAS
echo    12^) Configurar firma Android ^(key.properties^)
echo    13^) flutter doctor -v
echo    14^) Limpiar + pub get
echo   HOSTING — Firebase ^(políticas legales^)
echo    15^) Desplegar hosting ^(firebase deploy --only hosting^)
echo    16^) Vista previa local ^(http://localhost:5000^)
echo     0^) Salir
echo ========================================
set /p "CHOICE=Opción: "
call :dispatch "!CHOICE!"
if errorlevel 1 goto :menu_fail
echo.
pause
goto :menu

:run_direct
set "CHOICE=%~1"
call :dispatch "%CHOICE%"
exit /b !ERRORLEVEL!

:dispatch
set "OPT=%~1"
if "%OPT%"=="0" exit /b 0
if "%OPT%"=="1" goto :run_android_debug
if "%OPT%"=="2" goto :run_android_release
if "%OPT%"=="3" goto :install_android_release
if "%OPT%"=="4" goto :ios_unsupported
if "%OPT%"=="5" goto :ios_unsupported
if "%OPT%"=="6" goto :build_android_aab
if "%OPT%"=="7" goto :build_android_apk
if "%OPT%"=="8" goto :build_android_apk_split
if "%OPT%"=="9" goto :build_android_apk_debug
if "%OPT%"=="10" goto :ios_unsupported
if "%OPT%"=="11" goto :ios_unsupported
if "%OPT%"=="12" goto :setup_android_signing
if "%OPT%"=="13" goto :doctor
if "%OPT%"=="14" goto :clean
if "%OPT%"=="15" goto :hosting_deploy
if "%OPT%"=="16" goto :hosting_serve
echo [ERROR] Opción no válida: %OPT%
exit /b 1

:menu_fail
echo.
pause
exit /b 1

:ensure_deps
echo [INFO] flutter pub get...
call flutter pub get
if errorlevel 1 exit /b 1
exit /b 0

:check_android_signing
if not exist "%ROOT%\android\key.properties" (
  echo [WARN] Falta android\key.properties — release usará firma debug.
  exit /b 1
)
if exist "%ROOT%\upload-keystore.jks" (
  echo [OK] Keystore: upload-keystore.jks
  exit /b 0
)
if exist "%ROOT%\android\app\upload-keystore.jks" (
  echo [OK] Keystore: android\app\upload-keystore.jks
  exit /b 0
)
echo [WARN] No se encontró upload-keystore.jks
exit /b 1

:run_android_debug
call :ensure_deps || exit /b 1
echo [INFO] Ejecutando Android debug. Conecta dispositivo o emulador.
call flutter run
exit /b !ERRORLEVEL!

:run_android_release
call :ensure_deps || exit /b 1
echo [INFO] Ejecutando Android release...
call flutter run --release
exit /b !ERRORLEVEL!

:install_android_release
echo [INFO] Instalando release en dispositivo...
call flutter install --release
exit /b !ERRORLEVEL!

:ios_unsupported
echo [ERROR] iOS solo se compila en macOS con Xcode.
echo        En Windows usa un Mac o CI para App Store.
exit /b 1

:build_android_aab
call :ensure_deps || exit /b 1
call :check_android_signing
echo [INFO] Compilando App Bundle para Google Play...
call flutter build appbundle --release
if errorlevel 1 exit /b 1
echo [OK] AAB: build\app\outputs\bundle\release\app-release.aab
exit /b 0

:build_android_apk
call :ensure_deps || exit /b 1
call :check_android_signing
echo [INFO] Compilando APK release...
call flutter build apk --release
if errorlevel 1 exit /b 1
echo [OK] APK: build\app\outputs\flutter-apk\app-release.apk
exit /b 0

:build_android_apk_split
call :ensure_deps || exit /b 1
call :check_android_signing
echo [INFO] Compilando APKs split por ABI...
call flutter build apk --release --split-per-abi
if errorlevel 1 exit /b 1
echo [OK] APKs en: build\app\outputs\flutter-apk\
dir /b build\app\outputs\flutter-apk\*.apk 2>nul
exit /b 0

:build_android_apk_debug
call :ensure_deps || exit /b 1
echo [INFO] Compilando APK debug...
call flutter build apk --debug
if errorlevel 1 exit /b 1
echo [OK] APK: build\app\outputs\flutter-apk\app-debug.apk
exit /b 0

:setup_android_signing
if not exist "%ROOT%\android\key.properties" (
  copy /Y "%ROOT%\android\key.properties.example" "%ROOT%\android\key.properties" >nul
  echo [OK] Creado android\key.properties desde el ejemplo.
  echo [WARN] Edita android\key.properties con tus contraseñas reales.
) else (
  echo [OK] android\key.properties ya existe.
)
if exist "%ROOT%\upload-keystore.jks" (
  echo [OK] Keystore en raíz: upload-keystore.jks
) else if exist "%ROOT%\android\app\upload-keystore.jks" (
  echo [OK] Keystore: android\app\upload-keystore.jks
) else (
  echo [WARN] Genera upload-keystore.jks con keytool ^(ver key.properties.example^).
)
exit /b 0

:doctor
call flutter doctor -v
exit /b !ERRORLEVEL!

:clean
echo [INFO] flutter clean...
call flutter clean
call :ensure_deps || exit /b 1
echo [OK] Listo.
exit /b 0

:require_firebase
where firebase >nul 2>&1
if errorlevel 1 (
  echo [ERROR] Firebase CLI no instalado.
  echo        npm install -g firebase-tools
  echo        firebase login
  exit /b 1
)
exit /b 0

:hosting_deploy
call :require_firebase || exit /b 1
if not exist "%ROOT%\hosting\public\privacy-policy.html" (
  echo [ERROR] Falta hosting\public\privacy-policy.html
  exit /b 1
)
echo [INFO] Desplegando Firebase Hosting ^(proyecto church-register-ce4de^)...
call firebase deploy --only hosting
if errorlevel 1 exit /b 1
echo [OK] URL privacidad: https://church-register-ce4de.web.app/privacy-policy
exit /b 0

:hosting_serve
call :require_firebase || exit /b 1
echo [INFO] Emulador hosting en http://localhost:5000
echo       Ctrl+C para detener.
call firebase emulators:start --only hosting
exit /b !ERRORLEVEL!
