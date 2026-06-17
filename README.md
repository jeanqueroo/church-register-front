# Manantial de Bendiciones

Aplicación Flutter de **gestión pastoral** para la iglesia: integrantes, líderes, visitas, mapas, dashboards y notificaciones. Acceso restringido por roles (no es app pública).

| Campo | Valor |
|-------|-------|
| **Nombre en tienda** | Manantial de Bendiciones |
| **Package Android** | `com.church.register.manantial` |
| **Bundle iOS** (pendiente alinear) | `com.church.register.churchRegister` |
| **Versión actual** | Ver `pubspec.yaml` (ej. `1.0.2+3`) |
| **Guía de despliegue** | [`DESPLIEGUE.md`](DESPLIEGUE.md) |
| **Estados e historial** | [`docs/estados-e-historial-creyentes-lideres.md`](docs/estados-e-historial-creyentes-lideres.md) |
| **Proyecto Firebase** | `church-register-ce4de` |
| **Contacto** | contacto@manantialdebendiciones.org |

---

## Estructura del proyecto

```
church-register-front/
├── lib/                    # Código Flutter (es/en i18n)
├── docs/                   # Documentación técnica del dominio
│   └── estados-e-historial-creyentes-lideres.md
├── android/                # Config Android + firma release
├── ios/                    # Config iOS (requiere Mac)
├── hosting/public/         # Páginas web → Firebase Hosting
│   ├── index.html
│   └── privacy-policy.html
├── store/                  # Assets y textos de Play Console (no van al hosting)
│   ├── play-store-icon-512.png
│   ├── play-store-feature-graphic-1024x500.png
│   ├── generate_play_assets.py
│   └── PLAY_CONSOLE.md     # Ficha detallada de la tienda
├── scripts/
│   ├── build.bat           # Menú Windows
│   └── build.sh            # Menú macOS / Linux / Git Bash
├── firebase.json           # Hosting, Firestore, Storage, Functions
└── FIREBASE_SETUP.md       # Config Firebase de la app
```

**Importante:** `hosting/public/` es solo para la web (políticas legales). `store/` es para gráficos y textos de Google Play.

---

## Documentación del proyecto

| Documento | Contenido |
|-----------|-----------|
| [`docs/estados-e-historial-creyentes-lideres.md`](docs/estados-e-historial-creyentes-lideres.md) | Estados de creyentes y líderes, recorrido (registro → líder → célula → bautismo), subcolecciones `history` y `visits`, campos en Firestore y flujos por pantalla |
| [`DESPLIEGUE.md`](DESPLIEGUE.md) | Despliegue y publicación |
| [`FIREBASE_SETUP.md`](FIREBASE_SETUP.md) | Configuración Firebase |

---

## Requisitos previos

### Desarrollo

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable)
- Android Studio + SDK (licencias aceptadas: `flutter doctor --android-licenses`)
- Para iOS: macOS + Xcode + cuenta Apple Developer

### Despliegue

- Cuenta **Google Play Developer** (~25 USD, una vez)
- **Firebase CLI** para hosting: `npm install -g firebase-tools` → `firebase login`
- Keystore Android (`upload-keystore.jks`) + `android/key.properties`

Comprobar entorno:

```powershell
flutter doctor -v
scripts\build.bat 13
```

---

## Scripts de compilación y despliegue

Menú interactivo o ejecución directa con número de opción:

```powershell
# Windows
scripts\build.bat
scripts\build.bat 6

# macOS / Linux / Git Bash
./scripts/build.sh
./scripts/build.sh 6
```

| Opción | Acción |
|--------|--------|
| **1** | Android debug (`flutter run`) |
| **2** | Android release en dispositivo |
| **3** | Instalar release (`flutter install --release`) |
| **4–5** | iOS local (solo Mac) |
| **6** | **Google Play: App Bundle (.aab)** ★ producción |
| **7** | APK release (fat) |
| **8** | APK split por ABI |
| **9** | APK debug (pruebas) |
| **10–11** | iOS App Store / build sin codesign (solo Mac) |
| **12** | Configurar firma Android (`key.properties`) |
| **13** | `flutter doctor -v` |
| **14** | `flutter clean` + `pub get` |
| **15** | **Desplegar Firebase Hosting** (política de privacidad) |
| **16** | Vista previa hosting local (`http://localhost:5000`) |

Documentación oficial:

- [Android deployment](https://docs.flutter.dev/deployment/android)
- [iOS deployment](https://docs.flutter.dev/deployment/ios)

---

## Android — firma y compilación de producción

### 1. Keystore

Generar (solo si aún no tienes uno y **no** publicaste la app antes):

```powershell
keytool -genkey -v -keystore upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Coloca el archivo en la **raíz del proyecto** y crea `android/key.properties` desde el ejemplo:

```powershell
scripts\build.bat 12
copy android\key.properties.example android\key.properties
```

Ejemplo de `android/key.properties` (no subir a git):

```properties
storePassword=TU_CONTRASEÑA
keyPassword=TU_CONTRASEÑA
keyAlias=upload
storeFile=../upload-keystore.jks
```

> **Nota:** Si existen dos archivos `.jks` (raíz y `android/app/`), usa el de la raíz con `storeFile=../upload-keystore.jks`. Deben ser el mismo keystore que registraste en Play Console.

### 2. Compilar para producción

```powershell
scripts\build.bat 6
```

Salida:

```
build\app\outputs\bundle\release\app-release.aab
```

Sube ese **AAB** en Play Console → Producción → Crear versión.

### 3. Icono en el dispositivo

Regenerar launcher desde el logo:

```powershell
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

Fuente: `assets/images/logo_iglesia.png` (config en `pubspec.yaml`).

---

## Firebase Hosting — política de privacidad

### Editar contenido

- `hosting/public/privacy-policy.html` — política de privacidad (ES)
- `hosting/public/index.html` — índice con enlaces

### Desplegar

```powershell
scripts\build.bat 15
# o
firebase deploy --only hosting
```

### URLs publicadas

| Página | URL |
|--------|-----|
| Inicio | https://church-register-ce4de.web.app |
| Política de privacidad | https://church-register-ce4de.web.app/privacy-policy |

Usa la URL de **privacidad** en Play Console (campo obligatorio).

Vista previa local: `scripts\build.bat 16`

---

## Google Play Console

Guía extendida en [`store/PLAY_CONSOLE.md`](store/PLAY_CONSOLE.md).

### Nombre de la app (máx. 30 caracteres)

```
Manantial de Bendiciones
```

### Descripción corta (máx. 80 caracteres)

```
Gestión pastoral: integrantes, líderes, visitas, mapas y reportes de iglesia.
```

### Descripción completa (máx. 4000 caracteres)

Ver texto completo en [`store/PLAY_CONSOLE.md`](store/PLAY_CONSOLE.md) (3872 caracteres).

### Gráficos

| Archivo | Uso | Especificaciones |
|---------|-----|------------------|
| `store/play-store-icon-512.png` | Icono de la aplicación | 512×512 px, PNG 32-bit, &lt; 1 MB, cuadrado sin esquinas redondeadas |
| `store/play-store-feature-graphic-1024x500.png` | Banner / gráfico de funciones | 1024×500 px |

Regenerar desde el logo:

```powershell
python store/generate_play_assets.py
```

**Icono Play Store:** no incluir texto promocional, precios ni badges. Google aplica máscara con radio 30 %; el logo debe quedar dentro de la zona central (~384 px).

### Capturas de pantalla

Mínimo **2**; recomendado **4–8** (1080×1920 px vertical). Guardar en `store/screenshots/`.

Pantallas sugeridas: inicio/menú, lista de integrantes, registro de visita, mapa, dashboards.

### Categoría

- **Principal:** Productividad  
- **Secundaria (opcional):** Estilo de vida

### Clasificación de contenido

- No dirigida a niños / mayores de 18 años  
- Sin anuncios  
- Sin compras in-app

### Seguridad de los datos (resumen)

| Dato | Recopila | Comparte | Cifrado |
|------|----------|----------|---------|
| Nombre, correo, teléfono | Sí | No (Firebase como procesador) | Sí |
| Ubicación (direcciones/mapas) | Sí (opcional) | No | Sí |
| Fotos | Opcional | No | Sí |
| Token FCM | Sí | No | Sí |

Finalidad: funcionalidad de la app. Los datos **no se venden**.

### Checklist antes de enviar a revisión

- [ ] Nombre, descripciones y categoría
- [ ] Correo de contacto verificado
- [ ] URL de privacidad: https://church-register-ce4de.web.app/privacy-policy
- [ ] Icono 512×512 y banner 1024×500
- [ ] Al menos 2 capturas de pantalla
- [ ] AAB firmado (`scripts\build.bat 6`)
- [ ] Formulario “Seguridad de los datos”
- [ ] Clasificación de contenido

---

## iOS / App Store (pendiente)

En **Windows** solo Android. Para App Store hace falta **Mac + Xcode + cuenta Apple Developer**.

| Pendiente | Detalle |
|-----------|---------|
| `GoogleService-Info.plist` | Descargar de Firebase Console → `ios/Runner/` |
| `lib/firebase_options.dart` | Completar valores iOS (`flutterfire configure`) |
| Bundle ID | Unificar con Android si es posible (`com.church.register.manantial`) |
| Certificados | Configurar en Xcode → Signing & Capabilities |
| Build IPA | `./scripts/build.sh 10` (solo Mac) |

---

## Versionado y despliegue

Guía completa (versiones para Play Console, AAB, hosting, checklist): **[`DESPLIEGUE.md`](DESPLIEGUE.md)**

Resumen: en `pubspec.yaml`, `version: 1.0.2+3` → `1.0.2` es lo que ven los usuarios; `3` es el código que **debe subir** en cada release.

---

## Firebase de la app (backend)

Configuración de Auth, Firestore, FCM, Storage y reglas: ver [`FIREBASE_SETUP.md`](FIREBASE_SETUP.md).

Archivos locales (no en git):

- `android/app/google-services.json`
- `android/key.properties`
- `*.jks`

---

## Problemas frecuentes

### `keystore password was incorrect`

- Verifica contraseñas en `android/key.properties`.
- Confirma que `storeFile` apunta al `.jks` correcto (preferir `../upload-keystore.jks` en la raíz).
- Prueba el keystore: `keytool -list -keystore upload-keystore.jks -alias upload`

### Build release usa firma debug

Ocurre si falta `key.properties` o el keystore no existe. La app compila pero **Play Console rechazará** el AAB. Corrige la firma antes de subir.

### Firebase CLI no encontrado

```powershell
npm install -g firebase-tools
firebase login
```

### iOS en Windows

Opciones 4, 5, 10 y 11 del script requieren macOS. Usa un Mac o CI (Codemagic, GitHub Actions, etc.).

---

## Enlaces útiles

- [Play Console](https://play.google.com/console)
- [Firebase Console](https://console.firebase.google.com/project/church-register-ce4de)
- [Hosting publicado](https://church-register-ce4de.web.app)
- [Política de privacidad](https://church-register-ce4de.web.app/privacy-policy)
- [Especificaciones icono Play Store](https://developer.android.com/distribute/google-play/resources/icon-design-specifications)
