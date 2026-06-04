# Configuración de Firebase

El login usa **Firebase Authentication** (correo y contraseña). Sigue estos pasos una sola vez.

## 1. Crear proyecto en Firebase

1. Entra en [Firebase Console](https://console.firebase.google.com/).
2. Crea un proyecto (o usa uno existente).
3. Ve a **Build → Authentication → Sign-in method**.
4. Habilita **Correo electrónico/Contraseña**.

## 2. Registrar la app Android

1. En la configuración del proyecto, añade una app **Android**.
2. **Package name:** `com.church.register.church_registe` (debe coincidir exactamente con Firebase)
3. Descarga `google-services.json` y colócalo en:

   ```
   android/app/google-services.json
   ```

## 3. Generar configuración Flutter (recomendado)

En la raíz del proyecto:

```powershell
dart pub global activate flutterfire_cli
dart pub global run flutterfire_cli:flutterfire configure --project=TU_PROJECT_ID
```

Esto actualiza `lib/firebase_options.dart` automáticamente.

## 4. Activar Firestore (registro de miembros)

1. Ve a **Build → Firestore Database** → **Create database**.
2. Elige modo **producción** (o prueba para desarrollo).
3. En **Rules**, usa reglas que solo permitan lectura/escritura a usuarios autenticados:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /members/{memberId} {
      allow read, write: if request.auth != null;
    }
    match /leaders/{leaderId} {
      allow read, write: if request.auth != null;
    }
    match /users/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow create, update: if request.auth != null;
    }
    match /notifications/{notificationId} {
      allow create: if request.auth != null;
      allow read, update: if request.auth != null && (
        resource.data.recipientUserId == request.auth.uid ||
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.leaderId
          == resource.data.leaderId
      );
    }
  }
}
```

4. Publica las reglas.

Los integrantes se guardan en `members`. Los líderes se guardan en `leaders`. Los perfiles de acceso en `users` con campo **`roles`** (array). Las notificaciones para líderes (nuevo integrante asignado) en `notifications`.

## Notificaciones al líder

Cuando se registra o reasigna un integrante con un líder, la app crea un documento en `notifications` con el campo **`leaderId`** (id del documento en `leaders`). El líder las ve en **Notificaciones** si su perfil en `users` tiene el mismo `leaderId`.

Al iniciar sesión, la app sincroniza avisos para integrantes ya asignados que aún no tenían notificación.

**Importante:** publica las reglas de `notifications` de arriba. Si solo permites lectura por `recipientUserId`, el líder no verá los avisos aunque existan en la base de datos.

## Notificaciones push en el teléfono (FCM)

Para que el líder reciba un aviso en la **bandeja del sistema** (app cerrada o en segundo plano), además de la notificación dentro de la app:

### 1. App (automático al iniciar sesión como líder)

- Pide permiso de notificaciones (Android 13+ / iOS).
- Guarda el token en `users/{uid}.fcmToken`.

### 2. Cloud Function (obligatorio)

En la raíz del proyecto:

```powershell
npm install -g firebase-tools
firebase login
firebase use TU_PROJECT_ID
cd functions
npm install
cd ..
firebase deploy --only functions
```

La función `notifyLeaderOnMemberAssigned` se ejecuta al crear un documento en `notifications` y envía el push al `fcmToken` del líder.

### 3. Firebase Console

1. **Build → Cloud Messaging** — asegúrate de que esté habilitado.
2. **Android:** con `google-services.json` suele bastar.
3. **iOS:** sube la clave APNs en *Project settings → Cloud Messaging → Apple app configuration*.

### 4. Probar

1. Instala la app en un teléfono físico (el emulador a veces no recibe push).
2. Inicia sesión como **líder** y acepta notificaciones.
3. En Firestore, comprueba que `users/{uid}` tenga `fcmToken`.
4. Desde otra cuenta, registra un integrante asignado a ese líder.
5. Deberías ver el aviso en el teléfono y en **Notificaciones** dentro de la app.

Si no llega el push pero sí el aviso en la app, revisa que la función esté desplegada y que exista `fcmToken` en el perfil del líder.

## Roles de usuario

Un usuario puede tener **varios roles** a la vez. Valores válidos en `roles`:

| Valor en Firestore | Etiqueta        | Permisos en la app                                      |
|--------------------|-----------------|---------------------------------------------------------|
| `admin`            | Administrador   | Ve y gestiona todo                                      |
| `registrador`      | Registrador     | Solo registrar integrantes y líderes (sin listas)       |
| `leader`           | Líder           | Ver sus integrantes asignados (solo lectura)            |

Ejemplo de documento en `users/{uid}`:

```json
{
  "email": "usuario@ejemplo.com",
  "roles": ["admin"],
  "fullName": "Nombre Apellido"
}
```

Ejemplo de **líder** (sin `fullName`; el nombre está en `leaders`):

```json
{
  "email": "lider@ejemplo.com",
  "roles": ["leader"],
  "leaderId": "abc123"
}
```

- **Administrador / registrador:** pueden usar `fullName` en `users` si lo necesitas.
- **Líder:** al registrarse desde la app solo se guardan `roles`, `leaderId` y `email` en `users`; `firstName` y `lastName` van en `leaders/{leaderId}`.

Si un usuario autenticado **no tiene documento** en `users`, la app lo trata como **administrador** (compatibilidad con cuentas creadas solo en Console).

## Mi cuenta (datos y contraseña)

Todos los usuarios autenticados pueden abrir **Mi cuenta** desde el menú:

- **Datos personales:** administradores actualizan `fullName` en `users`; líderes editan nombre y apellido en `leaders`.
- **Cambiar contraseña:** formulario aparte que pide la contraseña actual y la nueva (Firebase Authentication).

Los formularios están separados a propósito; cambiar la clave no se hace desde «Datos personales».

## 5. Crear usuarios de prueba

En Firebase Console → **Authentication → Users** → **Add user**, crea un correo y contraseña para probar el login.

## 6. Ejecutar la app

```powershell
flutter run
```

## Direcciones y mapas (OpenStreetMap)

La app usa **OpenStreetMap** sin API key de Google:

- **Autocompletado:** [Nominatim](https://nominatim.openstreetmap.org/) (búsqueda de direcciones)
- **Mapa:** [flutter_map](https://pub.dev/packages/flutter_map) con tiles de OSM
- **Asignación de líderes:** geocodificación con Nominatim + distancia en km

No requiere configuración en Google Cloud. Nominatim pide uso moderado (máx. ~1 petición/segundo en producción).

## iOS (opcional)

1. Añade app iOS en Firebase con bundle ID `com.church.register.churchRegister`.
2. Descarga `GoogleService-Info.plist` en `ios/Runner/`.
3. Vuelve a ejecutar `flutterfire configure`.
