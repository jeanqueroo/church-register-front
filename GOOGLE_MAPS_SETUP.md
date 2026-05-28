# Google Maps en la app

La app usa **Google Maps** para mapas, **Places Autocomplete** para buscar direcciones y **Geocoding** para coordenadas y asignación de líderes.

## 1. Google Cloud Console

En el mismo proyecto que Firebase (recomendado):

1. Activa **facturación** en el proyecto.
2. Habilita estas APIs:
   - Maps SDK for Android
   - Maps SDK for iOS (si compilas para iPhone)
   - Places API
   - Geocoding API
3. Crea una **API key** y restríngela:
   - **Android:** app `com.church.register.church_registe` + SHA-1 del keystore.
   - **iOS:** bundle ID de la app.

SHA-1 (debug):

```powershell
cd android
.\gradlew signingReport
```

## 2. Configurar la API key en el proyecto

### Dart (Places + Geocoding en la app)

Copia el ejemplo y pega tu key:

```powershell
copy lib\core\config\maps_api_key.example.dart lib\core\config\maps_api_key.dart
```

Edita `lib/core/config/maps_api_key.dart`:

```dart
const String kGoogleMapsApiKey = 'AIza...';
```

Alternativa sin archivo:

```powershell
flutter run --dart-define=GOOGLE_MAPS_API_KEY=AIza...
```

### Android (mapa nativo)

En `android/local.properties` (junto a `flutter.sdk`):

```properties
GOOGLE_MAPS_API_KEY=AIza...
```

### iOS

En `ios/Runner/Info.plist`, clave `GMSApiKey`:

```xml
<key>GMSApiKey</key>
<string>AIza...</string>
```

## 3. Ejecutar / compilar

```powershell
flutter pub get
flutter run
```

APK:

```powershell
flutter build apk --release
```

## 4. Comprobar que funciona

- Registrar integrante o líder → buscar dirección → deben aparecer sugerencias de Google.
- Vista de mapa de integrantes → mapa de Google con marcadores.
- Si falta la key, verás un aviso en pantalla.

## Costes

Google cobra por uso de Maps, Places y Geocoding. Hay cupo gratuito mensual; revisa la consola de facturación.
