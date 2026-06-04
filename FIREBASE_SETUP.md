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

Copia el contenido de **`firestore.rules`** en la raíz del proyecto (o publica con Firebase CLI):

```powershell
firebase deploy --only firestore:rules
```

4. Pulsa **Publicar**.

Los nuevos creyentes se guardan en `members`. Los líderes en `leaders`. Los perfiles en `users`. Las notificaciones del líder en **`users/{uid}/notifications`** (subcolección).

### Error `PERMISSION_DENIED` en «Líderes por supervisor»

Si un administrador o supervisor ve *No tienes permiso* al entrar:

1. Publica las reglas: `firebase deploy --only firestore:rules`
2. En Firestore → `users` → documento con el **UID** del usuario (no el correo), campo **`roles`** debe ser un **array** con strings exactos, por ejemplo: `["admin", "supervisor"]` (no «Administrador» ni un solo texto).
3. Cierra sesión en la app y vuelve a entrar.

Los roles se leen solo desde Firestore (`users.roles`), no desde la consola de Authentication.

### Error `PERMISSION_DENIED` en notificaciones

Si ves `Listen for Query(...)` con `PERMISSION_DENIED`:

1. Publica **`firestore.rules`** del repo (`firebase deploy --only firestore:rules`).
2. Las notificaciones deben estar en **`users/{uid}/notifications`**, no en la colección raíz `notifications` (versión antigua).
3. Vuelve a desplegar la Cloud Function (`firebase deploy --only functions`) para el nuevo path.

## Notificaciones al líder

Al asignar un nuevo creyente, la app escribe en `users/{uid del líder}/notifications`. El líder solo escucha su propio buzón (sin consultas que fallen por permisos).

Al iniciar sesión, se sincronizan avisos de nuevos creyentes ya asignados.

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
4. Desde otra cuenta, registra un nuevo creyente asignado a ese líder.
5. Deberías ver el aviso en el teléfono y en **Notificaciones** dentro de la app.

Si no llega el push pero sí el aviso en la app, revisa que la función esté desplegada y que exista `fcmToken` en el perfil del líder.

## Roles de usuario

Un usuario puede tener **varios roles** a la vez. Valores válidos en `roles`:

| Valor en Firestore | Etiqueta        | Permisos en la app                                      |
|--------------------|-----------------|---------------------------------------------------------|
| `admin`            | Administrador   | Ve y gestiona todo (solo desde Firebase Console)        |
| `registrador`      | Registrador     | Solo registrar nuevos creyentes (sin listas ni líderes)  |
| `supervisor`       | Supervisor      | Registrar creyentes y ver listas; ver líderes que le asignó el admin |
| `leader`           | Líder           | Ver sus nuevos creyentes asignados (solo lectura)       |

Al **registrar un líder** en la app puedes asignar `leader`, `registrador` y/o `supervisor` (nunca `admin`).

### Líderes por supervisor

En `users/{uid del supervisor}` guarda el campo **`supervisedLeaderIds`**: array de IDs de documentos de la colección `leaders`.

- **Administrador:** menú **Líderes por supervisor** → elige supervisor y marca los líderes → Guardar.
- **Supervisor:** mismo menú → solo lectura de los líderes que le asignaron.

Publica las reglas de Firestore tras actualizar (`firebase deploy --only firestore:rules`).

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

## Direcciones y mapas (Google Maps)

La app usa **Google Maps**, **Places API** y **Geocoding API**.

Configuración detallada: ver **[GOOGLE_MAPS_SETUP.md](GOOGLE_MAPS_SETUP.md)**.

## iOS (opcional)

1. Añade app iOS en Firebase con bundle ID `com.church.register.churchRegister`.
2. Descarga `GoogleService-Info.plist` en `ios/Runner/`.
3. Vuelve a ejecutar `flutterfire configure`.
