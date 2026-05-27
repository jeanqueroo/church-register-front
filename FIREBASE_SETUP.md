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
  }
}
```

4. Publica las reglas.

Los integrantes se guardan en `members`. Los líderes se guardan en `leaders`. Los perfiles de acceso en `users` con campo **`roles`** (array).

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
  "roles": ["admin", "leader"],
  "leaderId": "abc123",
  "fullName": "Nombre Apellido"
}
```

- **Administrador:** crea el usuario en Authentication y añade el documento en `users` con `"roles": ["admin"]`.
- **Registrador:** `"roles": ["registrador"]` (puede combinarse con otros roles).
- **Líder:** se asigna automáticamente al registrar un líder desde la app (`"roles": ["leader"]` + `leaderId`).

Si un usuario autenticado **no tiene documento** en `users`, la app lo trata como **administrador** (compatibilidad con cuentas creadas solo en Console).

## Mi cuenta (datos y contraseña)

Todos los usuarios autenticados pueden abrir **Mi cuenta** desde el menú:

- **Datos personales:** formulario para actualizar el nombre (`fullName` en Firestore).
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
