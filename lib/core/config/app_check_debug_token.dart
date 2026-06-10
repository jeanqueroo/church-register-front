/// Token de depuración de App Check (solo builds debug).
///
/// Genera uno en Firebase Console → App Check → Android → Manage debug tokens
/// → Add → Generate token. Luego ejecuta:
///
/// ```powershell
/// flutter run --dart-define=APP_CHECK_DEBUG_TOKEN=TU-TOKEN-AQUI
/// ```
const String appCheckDebugToken = String.fromEnvironment(
  'APP_CHECK_DEBUG_TOKEN',
  defaultValue: '',
);
