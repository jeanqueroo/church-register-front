#!/usr/bin/env bash
# Utilidades de desarrollo — Manantial de Bendiciones (Flutter)
# Complementa a scripts/build.sh (que se centra en compilados para stores).
# Aquí: correr en dispositivos, logs, pods iOS, limpieza, análisis/tests, l10n, abrir IDEs.
#
# Uso:
#   ./scripts/dev.sh                # menú interactivo
#   ./scripts/dev.sh run            # ejecuta un subcomando directo
#   ./scripts/dev.sh --help

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

APP_ID_ANDROID="com.church.register.manantial"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "${CYAN}$*${NC}"; }
ok()    { echo -e "${GREEN}$*${NC}"; }
warn()  { echo -e "${YELLOW}$*${NC}"; }
fail()  { echo -e "${RED}$*${NC}"; exit 1; }

is_macos() { [[ "$(uname -s)" == "Darwin" ]]; }

require_flutter() {
  command -v flutter >/dev/null 2>&1 || fail "Flutter no está en el PATH. Ejecuta: flutter doctor"
}

require_macos() {
  is_macos || fail "Esta opción requiere macOS con Xcode."
}

ensure_deps() {
  info "flutter pub get..."
  flutter pub get
}

# ---------------------------------------------------------------------------
# Dispositivos / ejecución
# ---------------------------------------------------------------------------
list_devices() {
  require_flutter
  info "Dispositivos / emuladores disponibles:"
  flutter devices
  echo
  info "Emuladores instalados (flutter emulators):"
  flutter emulators || true
}

run_select_device() {
  require_flutter
  ensure_deps
  info "Dispositivos disponibles:"
  flutter devices
  echo
  read -r -p "ID del dispositivo (-d, vacío = autoselección): " dev_id
  read -r -p "Modo [1=debug (def)  2=profile  3=release]: " mode
  local mode_flag=""
  case "${mode:-1}" in
    2) mode_flag="--profile" ;;
    3) mode_flag="--release" ;;
    *) mode_flag="" ;;
  esac
  if [[ -n "${dev_id}" ]]; then
    info "flutter run -d ${dev_id} ${mode_flag}"
    flutter run -d "${dev_id}" ${mode_flag}
  else
    info "flutter run ${mode_flag}"
    flutter run ${mode_flag}
  fi
}

run_android_emulator() {
  require_flutter
  info "Emuladores Android disponibles:"
  flutter emulators || true
  echo
  read -r -p "ID del emulador a iniciar (vacío = cancelar): " emu_id
  [[ -z "${emu_id}" ]] && { warn "Cancelado."; return; }
  flutter emulators --launch "${emu_id}"
  ok "Emulador lanzándose: ${emu_id}"
}

# ---------------------------------------------------------------------------
# Logs
# ---------------------------------------------------------------------------
logs_flutter() {
  require_flutter
  info "flutter logs (Ctrl+C para salir)..."
  flutter logs
}

logs_android() {
  command -v adb >/dev/null 2>&1 || fail "adb no está en el PATH (instala Android platform-tools)."
  info "logcat filtrado por flutter/${APP_ID_ANDROID} (Ctrl+C para salir)..."
  adb logcat "*:S" flutter:V ActivityManager:I
}

# ---------------------------------------------------------------------------
# iOS — CocoaPods
# ---------------------------------------------------------------------------
ios_pod_install() {
  require_macos
  command -v pod >/dev/null 2>&1 || fail "CocoaPods no instalado. Ejecuta: sudo gem install cocoapods"
  info "pod install en ios/..."
  ( cd "$ROOT/ios" && pod install )
  ok "Pods instalados."
}

ios_pod_update() {
  require_macos
  command -v pod >/dev/null 2>&1 || fail "CocoaPods no instalado."
  info "Actualizando repo de pods y dependencias..."
  ( cd "$ROOT/ios" && pod repo update && pod install --repo-update )
  ok "Pods actualizados."
}

ios_pod_clean() {
  require_macos
  warn "Eliminando Pods/, Podfile.lock y caché de pods..."
  rm -rf "$ROOT/ios/Pods" "$ROOT/ios/Podfile.lock" "$ROOT/ios/.symlinks"
  command -v pod >/dev/null 2>&1 && ( cd "$ROOT/ios" && pod cache clean --all || true )
  ok "Limpieza de pods completada. Ejecuta luego 'pod install'."
}

# ---------------------------------------------------------------------------
# Calidad de código
# ---------------------------------------------------------------------------
analyze() {
  require_flutter
  info "flutter analyze..."
  flutter analyze
}

format_code() {
  require_flutter
  info "dart format lib test..."
  dart format lib test
  ok "Formato aplicado."
}

run_tests() {
  require_flutter
  ensure_deps
  info "flutter test..."
  flutter test
}

gen_l10n() {
  require_flutter
  info "Generando localizaciones (flutter gen-l10n)..."
  flutter gen-l10n
  ok "Localizaciones generadas (lib/l10n)."
}

# ---------------------------------------------------------------------------
# Mantenimiento
# ---------------------------------------------------------------------------
deep_clean() {
  require_flutter
  warn "Limpieza profunda: flutter clean + caché Dart/Gradle + DerivedData iOS"
  flutter clean
  rm -rf "$ROOT/build" "$ROOT/.dart_tool"
  if [[ -d "$ROOT/android" ]]; then
    info "Limpiando Gradle (android)..."
    ( cd "$ROOT/android" && ./gradlew clean >/dev/null 2>&1 || true )
  fi
  if is_macos; then
    info "Limpiando DerivedData de Xcode..."
    rm -rf "$HOME/Library/Developer/Xcode/DerivedData"/Runner-* 2>/dev/null || true
  fi
  ensure_deps
  ok "Limpieza profunda completada."
}

pub_get()     { require_flutter; ensure_deps; ok "Dependencias actualizadas."; }
pub_upgrade() { require_flutter; info "flutter pub upgrade..."; flutter pub upgrade; ok "Listo."; }
pub_outdated(){ require_flutter; info "flutter pub outdated..."; flutter pub outdated || true; }
doctor()      { require_flutter; flutter doctor -v; }

# ---------------------------------------------------------------------------
# Abrir IDEs / proyectos nativos
# ---------------------------------------------------------------------------
open_xcode() {
  require_macos
  local ws="$ROOT/ios/Runner.xcworkspace"
  [[ -d "$ws" ]] || fail "No existe $ws (ejecuta 'pod install' primero)."
  info "Abriendo Xcode..."
  open "$ws"
}

open_android_studio() {
  if is_macos; then
    open -a "Android Studio" "$ROOT/android" 2>/dev/null \
      || fail "No se pudo abrir Android Studio. Ábrelo manualmente sobre la carpeta android/."
    info "Abriendo Android Studio sobre android/..."
  else
    command -v studio.sh >/dev/null 2>&1 \
      && studio.sh "$ROOT/android" \
      || fail "Abre Android Studio manualmente sobre la carpeta android/."
  fi
}

# ---------------------------------------------------------------------------
# Menú
# ---------------------------------------------------------------------------
show_menu() {
  echo
  echo "=================================================="
  echo "  Manantial de Bendiciones — Utilidades de dev"
  echo "  (para compilados de tienda usa scripts/build.sh)"
  echo "=================================================="
  echo "  EJECUTAR"
  echo "    1) Listar dispositivos / emuladores"
  echo "    2) Ejecutar eligiendo dispositivo y modo"
  echo "    3) Lanzar emulador Android"
  echo "  LOGS"
  echo "    4) flutter logs"
  echo "    5) adb logcat (Android)"
  echo "  iOS — CocoaPods (solo macOS)"
  echo "    6) pod install"
  echo "    7) pod update (--repo-update)"
  echo "    8) Limpiar Pods/"
  echo "  CALIDAD"
  echo "    9) flutter analyze"
  echo "   10) dart format"
  echo "   11) flutter test"
  echo "   12) Generar l10n"
  echo "  MANTENIMIENTO"
  echo "   13) pub get"
  echo "   14) pub upgrade"
  echo "   15) pub outdated"
  echo "   16) Limpieza profunda (clean + cachés)"
  echo "   17) flutter doctor -v"
  echo "  IDEs"
  echo "   18) Abrir Xcode (macOS)"
  echo "   19) Abrir Android Studio"
  echo "    0) Salir"
  echo "=================================================="
}

dispatch() {
  case "$1" in
    1|devices)        list_devices ;;
    2|run)            run_select_device ;;
    3|emulator)       run_android_emulator ;;
    4|logs)           logs_flutter ;;
    5|logcat)         logs_android ;;
    6|pod-install)    ios_pod_install ;;
    7|pod-update)     ios_pod_update ;;
    8|pod-clean)      ios_pod_clean ;;
    9|analyze)        analyze ;;
    10|format)        format_code ;;
    11|test)          run_tests ;;
    12|l10n)          gen_l10n ;;
    13|get)           pub_get ;;
    14|upgrade)       pub_upgrade ;;
    15|outdated)      pub_outdated ;;
    16|clean)         deep_clean ;;
    17|doctor)        doctor ;;
    18|xcode)         open_xcode ;;
    19|studio)        open_android_studio ;;
    *) return 1 ;;
  esac
}

main() {
  require_flutter
  while true; do
    show_menu
    read -r -p "Opción: " choice
    case "$choice" in
      0|q|Q) ok "Hasta luego."; exit 0 ;;
      *)
        if ! dispatch "$choice"; then
          warn "Opción no válida."
        fi
        ;;
    esac
    echo
    read -r -p "Enter para continuar..." _
  done
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  cat <<'EOF'
Utilidades de desarrollo — Manantial de Bendiciones

Uso:
  ./scripts/dev.sh                 Menú interactivo
  ./scripts/dev.sh <subcomando>    Ejecuta directo

Subcomandos:
  devices       Listar dispositivos / emuladores
  run           Ejecutar eligiendo dispositivo y modo (debug/profile/release)
  emulator      Lanzar un emulador Android
  logs          flutter logs
  logcat        adb logcat (Android)
  pod-install   pod install (iOS, macOS)
  pod-update    pod update --repo-update (iOS, macOS)
  pod-clean     Eliminar Pods/ y caché (iOS, macOS)
  analyze       flutter analyze
  format        dart format lib test
  test          flutter test
  l10n          flutter gen-l10n
  get           flutter pub get
  upgrade       flutter pub upgrade
  outdated      flutter pub outdated
  clean         Limpieza profunda (flutter clean + cachés Gradle/Xcode)
  doctor        flutter doctor -v
  xcode         Abrir Runner.xcworkspace en Xcode (macOS)
  studio        Abrir android/ en Android Studio

Para compilados de tienda (AAB/APK/IPA) usa scripts/build.sh
EOF
  exit 0
fi

if [[ -n "${1:-}" ]]; then
  dispatch "$1" || fail "Subcomando no válido: $1  (usa --help)"
else
  main
fi
