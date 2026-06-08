#!/usr/bin/env bash
# Menú de compilación y ejecución — Manantial de Bendiciones
# Docs: https://docs.flutter.dev/deployment/android
#       https://docs.flutter.dev/deployment/ios

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "${CYAN}$*${NC}"; }
ok()    { echo -e "${GREEN}$*${NC}"; }
warn()  { echo -e "${YELLOW}$*${NC}"; }
fail()  { echo -e "${RED}$*${NC}"; exit 1; }

require_flutter() {
  if ! command -v flutter >/dev/null 2>&1; then
    fail "Flutter no está en el PATH. Ejecuta: flutter doctor"
  fi
}

ensure_deps() {
  info "Obteniendo dependencias (flutter pub get)..."
  flutter pub get
}

doctor_check() {
  require_flutter
  flutter doctor -v
}

setup_android_signing() {
  info "Configuración de firma Android"
  local props="$ROOT/android/key.properties"
  local example="$ROOT/android/key.properties.example"
  if [[ ! -f "$props" ]]; then
    cp "$example" "$props"
    ok "Creado android/key.properties desde el ejemplo."
    warn "Edita android/key.properties con tus contraseñas reales."
  else
    ok "android/key.properties ya existe."
  fi
  if [[ -f "$ROOT/upload-keystore.jks" ]]; then
    ok "Keystore encontrado: upload-keystore.jks (raíz del proyecto)"
  elif [[ -f "$ROOT/android/app/upload-keystore.jks" ]]; then
    ok "Keystore encontrado: android/app/upload-keystore.jks"
  else
    warn "No se encontró upload-keystore.jks."
    warn "Genera uno con keytool (ver android/key.properties.example)."
  fi
}

check_android_release_signing() {
  local props="$ROOT/android/key.properties"
  if [[ ! -f "$props" ]]; then
    warn "Falta android/key.properties — la release usará firma debug."
    return 1
  fi
  local store_file
  store_file=$(grep -E '^storeFile=' "$props" | cut -d= -f2- | tr -d '\r')
  local resolved="$ROOT/android/$store_file"
  if [[ "$store_file" == ../* ]]; then
    resolved="$ROOT/${store_file#../}"
  fi
  if [[ ! -f "$resolved" ]]; then
    warn "Keystore no encontrado en: $store_file"
    return 1
  fi
  ok "Keystore: $resolved"
  return 0
}

run_android_debug() {
  require_flutter
  ensure_deps
  info "Ejecutando en Android (debug). Conecta un dispositivo o inicia un emulador."
  flutter run
}

run_android_release_local() {
  require_flutter
  ensure_deps
  info "Ejecutando en Android (release local)."
  flutter run --release
}

run_ios_debug() {
  require_flutter
  if [[ "$(uname -s)" != "Darwin" ]]; then
    fail "Compilar/ejecutar iOS requiere macOS con Xcode."
  fi
  ensure_deps
  info "Ejecutando en iOS (debug). Conecta un simulador o dispositivo."
  flutter run
}

run_ios_release_local() {
  require_flutter
  if [[ "$(uname -s)" != "Darwin" ]]; then
    fail "Compilar/ejecutar iOS requiere macOS con Xcode."
  fi
  ensure_deps
  info "Ejecutando en iOS (release local)."
  flutter run --release
}

build_android_aab() {
  require_flutter
  ensure_deps
  check_android_release_signing || warn "Se firmará con clave debug si falla la release."
  info "Compilando App Bundle para Google Play (flutter build appbundle --release)..."
  flutter build appbundle --release
  ok "AAB: build/app/outputs/bundle/release/app-release.aab"
}

build_android_apk() {
  require_flutter
  ensure_deps
  check_android_release_signing || warn "Se firmará con clave debug si falla la release."
  info "Compilando APK release (flutter build apk --release)..."
  flutter build apk --release
  ok "APK: build/app/outputs/flutter-apk/app-release.apk"
}

build_android_apk_split() {
  require_flutter
  ensure_deps
  check_android_release_signing || warn "Se firmará con clave debug si falla la release."
  info "Compilando APKs por arquitectura (--split-per-abi)..."
  flutter build apk --release --split-per-abi
  ok "APKs en: build/app/outputs/flutter-apk/"
  ls -la build/app/outputs/flutter-apk/*.apk 2>/dev/null || true
}

build_android_apk_debug() {
  require_flutter
  ensure_deps
  info "Compilando APK debug..."
  flutter build apk --debug
  ok "APK: build/app/outputs/flutter-apk/app-debug.apk"
}

install_android_release() {
  require_flutter
  info "Instalando build release en dispositivo conectado..."
  flutter install --release
}

build_ios_ipa() {
  require_flutter
  if [[ "$(uname -s)" != "Darwin" ]]; then
    fail "flutter build ipa requiere macOS con Xcode y certificados Apple."
  fi
  ensure_deps
  info "Compilando IPA para App Store (flutter build ipa --release)..."
  flutter build ipa --release
  ok "IPA en: build/ios/ipa/"
}

build_ios_release_no_codesign() {
  require_flutter
  if [[ "$(uname -s)" != "Darwin" ]]; then
    fail "Requiere macOS con Xcode."
  fi
  ensure_deps
  info "Compilando iOS sin codesign (solo para pruebas de build)..."
  flutter build ios --release --no-codesign
  ok "Build iOS en: build/ios/iphoneos/Runner.app"
}

clean_project() {
  require_flutter
  info "Limpiando proyecto..."
  flutter clean
  ensure_deps
  ok "Listo."
}

require_firebase() {
  if ! command -v firebase >/dev/null 2>&1; then
    fail "Firebase CLI no instalado. Ejecuta: npm install -g firebase-tools && firebase login"
  fi
}

hosting_deploy() {
  require_firebase
  local page="$ROOT/hosting/public/privacy-policy.html"
  if [[ ! -f "$page" ]]; then
    fail "Falta hosting/public/privacy-policy.html"
  fi
  info "Desplegando Firebase Hosting (proyecto church-register-ce4de)..."
  firebase deploy --only hosting
  ok "URL privacidad: https://church-register-ce4de.web.app/privacy-policy"
}

hosting_serve() {
  require_firebase
  info "Emulador hosting en http://localhost:5000 (Ctrl+C para detener)"
  firebase emulators:start --only hosting
}

show_menu() {
  echo
  echo "========================================"
  echo "  Manantial de Bendiciones — Build"
  echo "========================================"
  echo "  LOCAL — Android"
  echo "    1) Ejecutar debug (flutter run)"
  echo "    2) Ejecutar release en dispositivo"
  echo "    3) Instalar release en dispositivo (flutter install)"
  echo "  LOCAL — iOS (solo macOS)"
  echo "    4) Ejecutar debug"
  echo "    5) Ejecutar release en dispositivo"
  echo "  STORES — Android"
  echo "    6) Google Play: App Bundle (.aab) ★ recomendado"
  echo "    7) APK release (fat)"
  echo "    8) APK release split por ABI"
  echo "    9) APK debug (pruebas rápidas)"
  echo "  STORES — iOS (solo macOS)"
  echo "   10) App Store: IPA (flutter build ipa)"
  echo "   11) iOS release sin codesign (pruebas)"
  echo "  HERRAMIENTAS"
  echo "   12) Configurar firma Android (key.properties)"
  echo "   13) flutter doctor -v"
  echo "   14) Limpiar + pub get"
  echo "  HOSTING — Firebase (políticas legales)"
  echo "   15) Desplegar hosting (firebase deploy --only hosting)"
  echo "   16) Vista previa local (http://localhost:5000)"
  echo "    0) Salir"
  echo "========================================"
}

main() {
  require_flutter
  while true; do
    show_menu
    read -r -p "Opción: " choice
    case "$choice" in
      1) run_android_debug ;;
      2) run_android_release_local ;;
      3) install_android_release ;;
      4) run_ios_debug ;;
      5) run_ios_release_local ;;
      6) build_android_aab ;;
      7) build_android_apk ;;
      8) build_android_apk_split ;;
      9) build_android_apk_debug ;;
      10) build_ios_ipa ;;
      11) build_ios_release_no_codesign ;;
      12) setup_android_signing ;;
      13) doctor_check ;;
      14) clean_project ;;
      15) hosting_deploy ;;
      16) hosting_serve ;;
      0|q|Q) ok "Hasta luego."; exit 0 ;;
      *) warn "Opción no válida." ;;
    esac
    echo
    read -r -p "Enter para continuar..." _
  done
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  echo "Uso: ./scripts/build.sh"
  echo "     ./scripts/build.sh 6   (ejecuta opción 6 directamente)"
  exit 0
fi

if [[ -n "${1:-}" ]]; then
  choice="$1"
else
  main
  exit 0
fi

case "$choice" in
  1) run_android_debug ;;
  2) run_android_release_local ;;
  3) install_android_release ;;
  4) run_ios_debug ;;
  5) run_ios_release_local ;;
  6) build_android_aab ;;
  7) build_android_apk ;;
  8) build_android_apk_split ;;
  9) build_android_apk_debug ;;
  10) build_ios_ipa ;;
  11) build_ios_release_no_codesign ;;
  12) setup_android_signing ;;
  13) doctor_check ;;
  14) clean_project ;;
  15) hosting_deploy ;;
  16) hosting_serve ;;
  *) fail "Opción no válida: $choice" ;;
esac
