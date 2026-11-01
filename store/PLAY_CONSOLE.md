# Ficha de Google Play Console — Manantial de Bendiciones

> Sustituye el correo y la URL de privacidad si usas otros datos reales de la iglesia.

## Nombre de la aplicación (máx. 30 caracteres)

```
Manantial de Bendiciones
```

Alternativa más descriptiva (29 caracteres):

```
Registro Manantial Iglesia
```

---

## Descripción corta (máx. 80 caracteres)

```
Gestión pastoral: integrantes, líderes, visitas, mapas y reportes de iglesia.
```

(77 caracteres)

---

## Descripción completa (máx. 4000 caracteres)

```
Manantial de Bendiciones es la aplicación oficial de gestión pastoral de la iglesia. Está diseñada para el equipo autorizado — administradores, registradores, supervisores y líderes de célula — que necesitan organizar el cuidado de las personas, el seguimiento de visitas y la coordinación entre sedes.

¿PARA QUIÉN ES ESTA APP?

No es una aplicación para el público general. El acceso está restringido mediante cuenta y contraseña. Cada usuario ve únicamente la información permitida por su rol dentro de su iglesia o sede asignada.

¿QUÉ PUEDES HACER?

INTEGRANTES (CREYENTES)
• Registrar y consultar integrantes con datos personales, contacto, documento de identidad, célula y dirección.
• Buscar y filtrar listados; ver detalle completo de cada persona.
• Consultar integrantes por líder o los asignados a tu propia célula.
• Visualizar ubicaciones en mapa e iniciar ruta hacia la dirección con Google Maps.
• Exportar listados a Excel cuando tu rol lo permita.

LÍDERES Y SUPERVISORES
• Registrar y administrar líderes de célula con datos de contacto, zona y ubicación.
• Asignar integrantes a líderes; sugerencia automática por proximidad geográfica cuando hay dirección.
• Gestionar la relación entre supervisores y los líderes bajo su cuidado.
• Ver líderes en lista o en mapa interactivo, con identificación visual por género.

VISITAS PASTORALES
• Registrar visitas: lugar, duración, oración, peticiones y seguimiento espiritual.
• Llevar un historial ordenado del acompañamiento pastoral a cada integrante.
• Dar continuidad al cuidado pastoral con registros claros y accesibles.

DASHBOARDS Y REPORTES
• Dashboard de visitas con gráficas por día, mes y año.
• Dashboard pastoral con métricas de seguimiento y actividad del equipo.
• Visualiza tendencias y avances del trabajo pastoral en distintos periodos.
• Toma de decisiones basada en datos reales de la congregación.

NOTIFICACIONES
• Recibe avisos dentro de la app cuando se te asignen nuevos integrantes.
• Notificaciones push en el dispositivo para no perder asignaciones importantes.
• Mantente informado aunque no tengas la aplicación abierta.

ADMINISTRACIÓN Y MULTI-IGLESIA
• Gestión de iglesias y sedes para organizaciones con varias congregaciones.
• Registro de administradores y configuración de accesos por sede.
• Administración de cuentas y roles: superadministrador, administrador de iglesia, registrador, supervisor y líder.
• Interfaz disponible en español e inglés.

ROLES Y PERMISOS

Cada función respeta permisos definidos por rol. Un líder consulta y atiende a sus integrantes; un supervisor coordina a sus líderes asignados; un registrador puede dar de alta creyentes; un administrador configura su iglesia y usuarios. Así se protege la privacidad de cada persona y se mantiene el orden pastoral en el ministerio.

SEGURIDAD Y PRIVACIDAD

Los datos se almacenan de forma segura en la nube (Google Firebase) con autenticación, comunicación cifrada (HTTPS) y reglas de acceso por usuario y rol. La política de privacidad está disponible en nuestra web oficial. No vendemos ni compartimos datos con terceros con fines comerciales.

EXPERIENCIA DE USO

Interfaz clara pensada para el trabajo diario del equipo pastoral: menú lateral con accesos rápidos, búsquedas, mapas integrados y formularios organizados por secciones. Ideal para registrar visitas en el terreno, consultar datos antes de una reunión de célula o revisar el avance del mes desde el dashboard.

REQUISITOS

• Conexión a internet para sincronizar información.
• Cuenta autorizada proporcionada por la administración de la iglesia.
• Dispositivo Android compatible con Google Play.

SOPORTE

Para consultas, soporte técnico o privacidad: contacto@manantialdebendiciones.org

Descarga Manantial de Bendiciones y lleva el registro pastoral de tu iglesia con claridad, orden y cuidado por cada integrante de la congregación.
```

(3872 caracteres)

---

## Categoría

| Campo | Valor recomendado |
|-------|-------------------|
| **Categoría principal** | Productividad |
| **Categoría secundaria** (opcional) | Estilo de vida |

Motivo: es una herramienta interna de organización y seguimiento pastoral, no un juego ni red social pública.

---

## Correo de contacto del desarrollador

```
contacto@manantialdebendiciones.org
```

> Debe ser un correo real que revises. Google lo muestra en la ficha de la app.

---

## Política de privacidad (URL obligatoria)

1. Edita el HTML en `hosting/public/privacy-policy.html`.
2. Despliega en Firebase Hosting:

```powershell
scripts\build.bat 15
```

3. Usa esta URL en Play Console (tras el primer deploy):

```
https://church-register-ce4de.web.app/privacy-policy
```

Vista previa local: `scripts\build.bat 16`

4. Antes de publicar, **cambia el correo** en `hosting/public/privacy-policy.html` si no es el definitivo.

---

## Gráficos generados

| Archivo | Uso en Play Console |
|---------|---------------------|
| `store/play-store-icon-512.png` | Icono de la aplicación (512 × 512 px, PNG 32-bit, &lt; 1 MB) |
| `store/play-store-feature-graphic-1024x500.png` | Gráfico de funciones / banner (1024 × 500 px) |

**Icono Play Store:** sube `store/play-store-icon-512.png` en *Presencia en la tienda → Icono de la aplicación*. Debe ser cuadrado 512×512, PNG o JPEG &lt; 1 MB, sin esquinas redondeadas ni sombras (Google las aplica solo). No incluir texto promocional, precios ni badges.

Regenerar:

```powershell
python store/generate_play_assets.py
```

---

## Capturas de pantalla (obligatorias)

Mínimo **2 capturas** de teléfono; se recomiendan **4–8**. Resolución típica: **1080 × 1920 px** (vertical) o la de tu dispositivo.

### Pantallas sugeridas

1. **Inicio / menú** — Muestra el logo y opciones del menú lateral.
2. **Lista de integrantes** — Lista con búsqueda.
3. **Registro de visita** — Formulario de visita pastoral.
4. **Mapa** — Integrantes o líderes en mapa.
5. **Dashboard de visitas** — Gráficas por periodo.
6. **Dashboard pastoral** — Seguimiento y métricas.

### Cómo obtenerlas

```powershell
# Con emulador o dispositivo conectado
flutter run

# O captura manual: Power + Volumen abajo (Android)
```

Guarda las capturas en `store/screenshots/` antes de subirlas a Play Console.

---

## Clasificación de contenido

- **Público objetivo:** Mayores de 18 años (herramienta institucional) o “No dirigida a niños”.
- **Anuncios:** No contiene anuncios.
- **Compras dentro de la app:** No.

---

## Datos de seguridad (formulario “Seguridad de los datos”)

Indica aproximadamente:

| Tipo de dato | ¿Se recopila? | ¿Se comparte? | ¿Cifrado en tránsito? |
|--------------|---------------|---------------|------------------------|
| Nombre, correo, teléfono | Sí | No (solo Firebase como procesador) | Sí |
| Ubicación aproximada | Sí (opcional, direcciones/mapas) | No | Sí |
| Fotos | Opcional | No | Sí |
| Identificadores del dispositivo (token FCM) | Sí | No | Sí |

Finalidad: **Funcionalidad de la app** / gestión pastoral interna.  
Los datos **no se venden** a terceros.

---

## Checklist antes de enviar a revisión

- [ ] Nombre, descripciones y categoría completados
- [ ] Correo de contacto verificado en Play Console
- [ ] URL de política de privacidad publicada y accesible
- [ ] Icono 512×512 subido
- [ ] Banner 1024×500 subido
- [ ] Al menos 2 capturas de pantalla
- [ ] APK o AAB firmado (`flutter build appbundle --release`)
- [ ] Formulario “Seguridad de los datos” completado
- [ ] Clasificación de contenido completada
