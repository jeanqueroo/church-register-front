# Guía de despliegue — Manantial de Bendiciones

Documento de referencia para publicar nuevas versiones en **Google Play**, **Firebase Hosting** y compilaciones de producción.

| Campo | Valor |
|-------|-------|
| **Package Android** | `com.church.register.manantial` |
| **Versión actual** | Ver `pubspec.yaml` (ahora: `1.0.2+3`) |
| **Proyecto Firebase** | `church-register-ce4de` |
| **Política de privacidad** | https://church-register-ce4de.web.app/privacy-policy |

Documentación relacionada:

- [README.md](README.md) — visión general del proyecto
- [store/PLAY_CONSOLE.md](store/PLAY_CONSOLE.md) — textos y gráficos de la tienda
- [FIREBASE_SETUP.md](FIREBASE_SETUP.md) — backend Firebase

---

## Scripts rápidos

```powershell
# Windows — menú interactivo
scripts\build.bat

# Compilar AAB para Google Play (producción)
scripts\build.bat 6

# Desplegar política de privacidad (Firebase Hosting)
scripts\build.bat 15

# Comprobar entorno
scripts\build.bat 13
```

```bash
# macOS / Linux / Git Bash
./scripts/build.sh 6
./scripts/build.sh 15
```

| Opción | Acción |
|--------|--------|
| **6** | App Bundle `.aab` para Google Play |
| **12** | Ayuda con firma Android (`key.properties`) |
| **14** | `flutter clean` + `pub get` |
| **15** | `firebase deploy --only hosting` |
| **16** | Vista previa hosting local |

Salida del AAB de producción:

```
build\app\outputs\bundle\release\app-release.aab
```

---

## Versionado para Google Play

La versión se define en **`pubspec.yaml`**:

```yaml
version: 1.0.2+3
#        │     │
#        │     └── versionCode (número interno, entero)
#        └── versionName (lo que ven los usuarios en la tienda)
```

### Qué significa cada número

| Parte | Ejemplo | En Play Console | Descripción |
|-------|---------|-----------------|-------------|
| Antes del `+` | `1.0.2` | **Nombre de la versión** (`versionName`) | Versión visible para usuarios (ej. "1.0.2") |
| Después del `+` | `3` | **Código de versión** (`versionCode`) | Entero interno; **debe aumentar en cada subida** |

Flutter traduce esto automáticamente en Android (`android/app/build.gradle.kts` usa `flutter.versionName` y `flutter.versionCode`).

### Reglas obligatorias de Google Play

1. **El `versionCode` (número después del `+`) siempre debe ser mayor** que el de la última versión aceptada en Play Console.
2. No puedes reutilizar un `versionCode` que ya subiste, aunque borres la versión en borrador.
3. El `versionName` puede repetirse en teoría, pero conviene cambiarlo para que los usuarios distingan actualizaciones.

### Cómo elegir el siguiente número

**Paso 1 — Revisa en Play Console** qué versión subiste por última vez:

Play Console → Tu app → **Producción** (o Prueba interna/cerrada) → pestaña **Versiones** → mira el último **Código de versión**.

**Paso 2 — Incrementa el código:**

| Última subida | Siguiente en `pubspec.yaml` |
|---------------|----------------------------|
| `1.0.0+1` | `1.0.1+2` |
| `1.0.1+2` | `1.0.2+3` |
| `1.0.2+3` | `1.0.3+4` o `1.1.0+4` |

**Paso 3 — Ajusta el nombre visible** según el tipo de cambio:

| Tipo de cambio | Ejemplo |
|----------------|---------|
| Corrección de bugs | `1.0.2` → `1.0.3` |
| Funciones nuevas (menor) | `1.0.2` → `1.1.0` |
| Cambio grande / ruptura | `1.0.2` → `2.0.0` |

### Ejemplo práctico (release con cambios recientes)

Si la última versión en Play fue `1.0.1+2`, edita `pubspec.yaml`:

```yaml
version: 1.0.2+3
```

Luego compila y sube:

```powershell
scripts\build.bat 6
```

En Play Console verás:

- **Nombre de la versión:** `1.0.2`
- **Código de versión:** `3`

### Forzar versión sin editar `pubspec.yaml`

Útil en CI/CD o pruebas puntuales:

```powershell
flutter build appbundle --release --build-name=1.0.2 --build-number=3
```

> En el flujo habitual, edita `pubspec.yaml` y usa `scripts\build.bat 6` sin parámetros extra.

---

## Flujo completo: nueva versión en Google Play

### 1. Actualizar versión

Edita `pubspec.yaml` y sube el número después del `+`.

### 2. Compilar AAB firmado

Requisitos:

- `upload-keystore.jks` en la raíz del proyecto
- `android/key.properties` configurado (`scripts\build.bat 12`)

```powershell
scripts\build.bat 6
```

### 3. Subir a Play Console

1. [Play Console](https://play.google.com/console) → **Manantial de Bendiciones**
2. **Producción** (o canal de prueba) → **Crear nueva versión**
3. Sube `build\app\outputs\bundle\release\app-release.aab`
4. Verifica que el **código de versión** sea mayor al anterior
5. Completa **Notas de la versión** (qué cambió para los usuarios)
6. Revisa checklist y envía a revisión

### Checklist antes de enviar

- [ ] `versionCode` incrementado en `pubspec.yaml`
- [ ] AAB generado con `scripts\build.bat 6`
- [ ] Firma correcta (no debug)
- [ ] URL de privacidad vigente
- [ ] Notas de la versión redactadas
- [ ] Capturas/icono actualizados si cambió la UI de forma notable

Textos y gráficos de la ficha: [store/PLAY_CONSOLE.md](store/PLAY_CONSOLE.md)

---

## Firma Android (release)

### `android/key.properties` (no subir a git)

```properties
storePassword=TU_CONTRASEÑA
keyPassword=TU_CONTRASEÑA
keyAlias=upload
storeFile=../upload-keystore.jks
```

El keystore debe ser **el mismo** registrado en Play Console. Si publicaste la app con un keystore distinto, no podrás actualizarla con otro.

Verificar keystore:

```powershell
keytool -list -keystore upload-keystore.jks -alias upload
```

---

## Firebase Hosting (política de privacidad)

Archivos:

- `hosting/public/privacy-policy.html`
- `hosting/public/index.html`

Desplegar:

```powershell
scripts\build.bat 15
```

URLs:

| Página | URL |
|--------|-----|
| Inicio | https://church-register-ce4de.web.app |
| Política de privacidad | https://church-register-ce4de.web.app/privacy-policy |

Usa la URL de privacidad en el formulario de Play Console.

---

## Icono y splash

Regenerar desde el logo de la iglesia:

```powershell
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

Gráficos para Play Store (512×512, banner 1024×500):

```powershell
python store/generate_play_assets.py
```

---

## Problemas frecuentes

### Play Console rechaza el AAB: código de versión duplicado

El `versionCode` no es mayor que el anterior. Sube el número después del `+` en `pubspec.yaml` y vuelve a compilar.

### `keystore password was incorrect`

Revisa `android/key.properties` y que `storeFile` apunte al `.jks` correcto (`../upload-keystore.jks`).

### Build release con firma debug

Falta `key.properties` o el keystore. Play Console **rechazará** el bundle. Corrige antes de subir.

### Firebase CLI no encontrado

```powershell
npm install -g firebase-tools
firebase login
```

---

## iOS / App Store

Requiere **macOS + Xcode + cuenta Apple Developer**. En Windows solo Android.

```bash
./scripts/build.sh 10   # IPA (solo Mac)
```

Pendientes: `GoogleService-Info.plist`, alinear bundle ID, certificados en Xcode. Ver [README.md](README.md#ios--app-store-pendiente).

---

## Enlaces útiles

- [Play Console](https://play.google.com/console)
- [Firebase Console](https://console.firebase.google.com/project/church-register-ce4de)
- [Versionado Android (oficial)](https://developer.android.com/studio/publish/versioning)
- [Despliegue Flutter Android](https://docs.flutter.dev/deployment/android)
