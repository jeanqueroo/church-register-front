# Configuración de Firebase

Guía para configurar un **proyecto Firebase nuevo** con esta app. El login usa **Firebase Authentication** (correo y contraseña).

Los mapas usan **OpenStreetMap** (Nominatim + flutter_map). **No** hace falta API key de Google Maps.

---

## Checklist rápido (orden recomendado)

1. Crear proyecto en [Firebase Console](https://console.firebase.google.com/).
2. Habilitar **Authentication → Correo/Contraseña**.
3. Crear **Firestore Database** y **Storage** (misma región si es posible).
4. Registrar app **Android** con package `com.church.register.manantial`.
5. Ejecutar `flutterfire configure` (actualiza `lib/firebase_options.dart` y `google-services.json`).
6. Actualizar `.firebaserc` con el nuevo `projectId`.
7. Publicar reglas e índices: `firebase deploy --only firestore:rules,firestore:indexes,storage`.
8. Activar plan **Blaze** y desplegar functions: `firebase deploy --only functions` (luego `firebase functions:artifacts:setpolicy --location us-central1` si aparece el aviso de cleanup).
9. Configurar **App Check** (token debug en desarrollo).
10. Crear usuario en Authentication y probar login.
11. Crear iglesia, administrador y flujo completo (creyente, líder, célula).

---

## 1. Firebase Console

### Authentication

1. **Build → Authentication → Sign-in method**.
2. Habilita **Correo electrónico/Contraseña**.
3. Crea el primer usuario en **Users → Add user**.

### Firestore

1. **Build → Firestore Database → Create database**.
2. Modo **producción** (las reglas del repo limitan el acceso por roles).
3. Elige ubicación (p. ej. `us-central1` o la más cercana a tus usuarios).

### Storage

1. **Build → Storage → Get started**.
2. Usa la misma región que Firestore si puedes.
3. Sirve para logos de iglesia: `church_profiles/{churchId}/logo.jpg`.

### Cloud Messaging

1. **Build → Cloud Messaging** — suele activarse al registrar la app Android.
2. **iOS (opcional):** sube la clave APNs en *Project settings → Cloud Messaging → Apple app configuration*.

### App Check

Necesario para subir el logo de la iglesia si Storage tiene enforcement activo.

1. **Build → App Check** → registra la app Android.
2. **Desarrollo:** proveedor **Debug** → genera token (ver sección [App Check](#app-check)).
3. **Producción:** **Play Integrity** (app firmada; idealmente desde Play Console).

---

## 2. Registrar las apps

| Plataforma | Identificador |
|------------|---------------|
| **Android** | `com.church.register.manantial` |
| **iOS** (opcional) | `com.church.register.churchRegister` |

### Android

1. En configuración del proyecto Firebase, añade una app **Android**.
2. **Package name:** `com.church.register.manantial` (debe coincidir exactamente con `android/app/build.gradle.kts`).
3. Descarga `google-services.json` → `android/app/google-services.json`.
4. (Recomendado) Añade **SHA-1** y **SHA-256** del keystore de debug/release en *Project settings → Your apps* (útil para App Check / Play Integrity).

### iOS (opcional)

1. Añade app iOS con bundle ID `com.church.register.churchRegister`.
2. Descarga `GoogleService-Info.plist` → `ios/Runner/`.
3. Vuelve a ejecutar `flutterfire configure`.

---

## 3. Configuración en el proyecto Flutter

### FlutterFire (recomendado)

En la raíz del repositorio:

```powershell
dart pub global activate flutterfire_cli
firebase login
dart pub global run flutterfire_cli:flutterfire configure --project=TU_PROJECT_ID
```

Esto actualiza automáticamente:

- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist` (si configuras iOS)

### Vincular Firebase CLI

Edita `.firebaserc`:

```json
{
  "projects": {
    "default": "TU_PROJECT_ID"
  }
}
```

### Publicar reglas, índices y Storage

Las reglas **reales** del proyecto están en el repositorio (no uses reglas mínimas de ejemplo):

| Archivo | Contenido |
|---------|-----------|
| `firestore.rules` | Permisos por roles (superadmin, admin, líder, supervisor, etc.) |
| `firestore.indexes.json` | Índices para consultas de creyentes, líderes y visitas |
| `storage.rules` | Lectura/escritura de logos para usuarios autenticados |

```powershell
firebase use TU_PROJECT_ID
firebase deploy --only firestore:rules,firestore:indexes,storage
```

Si la app muestra un enlace para crear un índice al consultar datos, créalo desde el enlace o vuelve a desplegar `firestore.indexes.json`.

### Cloud Functions (notificaciones push)

Requiere plan **Blaze** (facturación por uso; en desarrollo suele costar $0).

```powershell
npm install -g firebase-tools
firebase login
firebase use TU_PROJECT_ID
cd functions
npm install
cd ..
firebase deploy --only functions
```

La función `notifyLeaderOnMemberAssigned` envía push al crear un documento en `notifications` (tipo `member_assigned`).

#### Política de limpieza de imágenes (Artifact Registry)

En Firebase CLI 14+, al desplegar por primera vez puede aparecer:

```
Functions successfully deployed but could not set up cleanup policy in location us-central1.
Pass the --force option to automatically set up a cleanup policy or run
'firebase functions:artifacts:setpolicy' to manually set up a cleanup policy.
```

**La función sí se desplegó.** El aviso solo indica que falta configurar la limpieza automática de imágenes de contenedor en Artifact Registry (evita costos pequeños de almacenamiento).

Configúralo **una vez** en tu máquina (modo interactivo):

```powershell
firebase functions:artifacts:setpolicy --location us-central1 --days 7
```

- `--days 7` borra imágenes de más de 7 días (puedes usar `1` o `30`).
- En el próximo deploy también puedes usar: `firebase deploy --only functions --force`.
- Si despliegas desde CI/CD, ejecuta `artifacts:setpolicy` en local primero o añade `--force` al pipeline.
- Para no borrar imágenes automáticamente: `firebase functions:artifacts:setpolicy --location us-central1 --none` (no recomendado).

### Ejecutar la app

```powershell
flutter pub get
flutter run
```

Con App Check en desarrollo:

```powershell
flutter run --dart-define=APP_CHECK_DEBUG_TOKEN=TU-TOKEN-DEBUG
```

---

## 4. Google Cloud (vinculado automáticamente)

Al crear el proyecto Firebase se crea un proyecto en Google Cloud. Revisa:

| Elemento | Para qué |
|----------|----------|
| **Plan Blaze** | Desplegar Cloud Functions |
| **APIs** | Firestore, Storage, FCM y Functions se activan al usarlas |
| **Play Integrity** | App Check en producción Android (vía Play Console) |

**No** necesitas configurar Google Maps API: la app usa OpenStreetMap.

---

## 5. Colecciones de Firestore

| Colección | Uso |
|-----------|-----|
| `churches` | Datos de cada iglesia |
| `users` | Perfiles, `roles`, `churchId`, `leaderId`, `fcmToken` |
| `members` | Creyentes (+ subcolecciones `history`, `visits`) |
| `leaders` | Líderes |
| `cells` | Células (+ subcolecciones `disciples`, `sessions`) |
| `disciples` | Discípulos sin célula asignada |
| `notifications` | Avisos en la app y trigger de push |
| `baptismCalendar` | Fechas de bautismo programadas |

---

## 6. Roles de usuario

Un usuario puede tener **varios roles**. Valores válidos en `roles`:

| Valor en Firestore | Etiqueta | Permisos principales |
|--------------------|----------|----------------------|
| `superadmin` | Super administrador | Crear iglesias y administradores |
| `admin` | Administrador de iglesia | Gestiona su sede (`churchId`) |
| `registrador` | Registrador | Registrar creyentes y líderes |
| `supervisor` | Supervisor | Supervisa líderes asignados |
| `leader` | Líder | Su célula, asistencia, creyentes asignados |

### Super administrador

Si un usuario autenticado **no tiene documento** en `users`, la app lo trata como **super administrador** (primera cuenta de Firebase Console).

Opcional en `users/{uid}`:

```json
{
  "email": "admin@tudominio.com",
  "roles": ["superadmin"],
  "fullName": "Administrador"
}
```

### Administrador de iglesia

```json
{
  "email": "admin@iglesia.com",
  "roles": ["admin"],
  "churchId": "ID_DE_LA_IGLESIA",
  "fullName": "María García"
}
```

### Líder

El nombre va en `leaders/{leaderId}`; en `users` solo `roles`, `leaderId` y `email`:

```json
{
  "email": "lider@ejemplo.com",
  "roles": ["leader"],
  "leaderId": "abc123"
}
```

---

## 7. Notificaciones al líder

Al registrar o reasignar un creyente con líder, la app crea un documento en `notifications` con `leaderId`. El líder lo ve en **Notificaciones** si su `users/{uid}.leaderId` coincide.

Al iniciar sesión, la app sincroniza avisos pendientes para creyentes ya asignados.

### Push en el teléfono (FCM)

1. **App:** al iniciar sesión como líder, pide permiso y guarda `fcmToken` en `users/{uid}`.
2. **Cloud Function:** desplegada con `firebase deploy --only functions`.
3. **Probar:** teléfono físico, login como líder, registrar creyente asignado desde otra cuenta.

Si el aviso aparece en la app pero no en la bandeja del sistema, revisa `fcmToken` en Firestore y que la función esté desplegada.

---

## 8. Datos de la iglesia y Storage

- **Super admin:** menú **Iglesias** y **Nuevo administrador**.
- **Admin:** menú **Datos de la iglesia** (su `churchId`).

Logo opcional en Storage: `church_profiles/{churchId}/logo.jpg`.

---

## App Check

La app llama a `activateFirebaseAppCheck()` al iniciar (`lib/core/firebase/app_check_bootstrap.dart`).

### Desarrollo (debug)

El token **no aparece** en la consola de `flutter run`.

#### Método A — Generar token en Firebase (recomendado)

1. Firebase Console → **App Check** → app **Android** → **Manage debug tokens**.
2. **Add debug token** → **Generate token** → copia el UUID.
3. Ejecuta:

```powershell
flutter run --dart-define=APP_CHECK_DEBUG_TOKEN=PEGAR-TOKEN-AQUI
```

4. Cierra y vuelve a abrir la app si ya estaba corriendo.
5. Prueba subir el logo de la iglesia.

#### Método B — Logcat (Android)

```powershell
adb logcat -s DebugAppCheckProvider
```

En otra terminal: `flutter run`. Registra el token que aparezca en Firebase Console → App Check → **Manage debug tokens**.

### Producción (Play Store)

- Builds `release` usan **Play Integrity**.
- Registra el proveedor en App Check para Android.
- Para pruebas reales de Integrity, instala desde Play (internal testing) o usa dispositivo con licencia Play.

### Errores frecuentes

| Síntoma | Solución |
|---------|----------|
| `Error getting App Check token` | Registra debug token o desactiva enforcement en Storage (solo pruebas) |
| `Too many attempts` | Cierra la app 15–30 min, registra token, reintenta una vez |
| Error 404 al subir logo | Activa Storage en Console y `firebase deploy --only storage` |
| `permission-denied` en Firestore | `firebase deploy --only firestore:rules` |

### Solo pruebas (menos seguro)

Firebase Console → App Check → **Storage** → desactiva **Enforcement**. No recomendado en producción.

---

## 9. Mi cuenta

Todos los usuarios autenticados pueden abrir **Mi cuenta**:

- **Datos personales:** admins actualizan `fullName` en `users`; líderes editan nombre en `leaders`.
- **Cambiar contraseña:** formulario aparte (Firebase Authentication).

---

## 10. Verificación final

Comprueba que todo funciona:

- [ ] Login con correo/contraseña
- [ ] Crear iglesia (superadmin)
- [ ] Crear administrador con `churchId`
- [ ] Registrar creyente, líder y célula
- [ ] Subir logo de iglesia (App Check + Storage)
- [ ] Asignar creyente a líder → notificación en app
- [ ] Push al líder (functions + `fcmToken` en dispositivo físico)
- [ ] Dashboards de bautismo y células sin `permission-denied`

---

## Direcciones y mapas (OpenStreetMap)

- **Autocompletado:** [Nominatim](https://nominatim.openstreetmap.org/)
- **Mapa:** [flutter_map](https://pub.dev/packages/flutter_map) con tiles OSM
- **Asignación de líderes:** geocodificación Nominatim + distancia en km

Uso moderado en producción (máx. ~1 petición/segundo recomendado para Nominatim).

---

## Referencia: proyecto actual en el repo

El `.firebaserc` del repositorio apunta por defecto a `church-register-qa`.
