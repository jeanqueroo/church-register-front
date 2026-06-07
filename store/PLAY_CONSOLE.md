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
Gestión pastoral: integrantes, líderes, visitas y reportes para la iglesia.
```

(79 caracteres)

---

## Descripción completa

```
Manantial de Bendiciones es la aplicación oficial de gestión pastoral de la iglesia. Está pensada para el equipo autorizado: administradores, registradores, supervisores y líderes de célula.

¿QUÉ PUEDES HACER?

• Registrar y consultar integrantes (creyentes) con datos de contacto, célula y dirección.
• Gestionar líderes y asignaciones entre supervisores y líderes.
• Registrar visitas pastorales: lugar, duración, oración, peticiones y seguimiento.
• Ver mapas de integrantes y líderes, con opción de abrir la ruta en Google Maps.
• Consultar dashboards de visitas y seguimiento pastoral (por día, mes o año).
• Recibir notificaciones cuando se te asignen nuevos integrantes.
• Exportar listados de líderes cuando tu rol lo permita.

ROLES Y ACCESO

Cada usuario accede con su cuenta y ve solo la información permitida por su rol: superadministrador, administrador de iglesia, registrador, supervisor o líder. La app no está destinada al público general.

SEGURIDAD

Los datos se almacenan de forma segura en la nube (Firebase) con acceso restringido por autenticación y reglas de permisos.

Para soporte o consultas sobre privacidad, escribe a contacto@manantialdebendiciones.org
```

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

1. Publica el archivo `store/privacy-policy.html` en un sitio accesible (GitHub Pages, Firebase Hosting, web de la iglesia, etc.).
2. Usa la URL pública en Play Console, por ejemplo:

```
https://manantialdebendiciones.org/privacy-policy.html
```

3. Antes de publicar, **cambia el correo** en `privacy-policy.html` si no es el definitivo.

---

## Gráficos generados

| Archivo | Uso en Play Console |
|---------|---------------------|
| `store/play-store-icon-512.png` | Icono de la aplicación (512 × 512 px) |
| `store/play-store-feature-graphic-1024x500.png` | Gráfico de funciones / banner (1024 × 500 px) |

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
