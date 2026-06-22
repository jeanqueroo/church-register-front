# Migración Firestore → PostgreSQL

Copia Firestore a PostgreSQL **sin modificar la app Flutter**.

## Resultado: dos capas de datos

| Capa | Esquema | Qué es |
|------|---------|--------|
| **Espejo JSON** | `firestore_mirror.documents` | Copia exacta de Firestore (JSONB) |
| **Tablas reales** | `public.*` | Columnas relacionales + `raw_data` JSONB |

---

## Migración completa con Docker

### 1. Cuenta de servicio Firebase

```
scripts/firestore-to-postgres/secrets/service-account.json
```

### 2. Ejecutar todo el pipeline

```bash
cd scripts/firestore-to-postgres
docker compose up postgres migrate normalize
```

| Paso | Servicio | Acción |
|------|----------|--------|
| 1 | `postgres` | Levanta PostgreSQL |
| 2 | `migrate` | Lee Firestore → `firestore_mirror.documents` |
| 3 | `normalize` | Crea tablas `public.*` con todos los campos |

### 3. Solo normalizar (si ya migraste antes)

```bash
docker compose run --rm normalize
```

### 4. Verificar conteos Firestore vs espejo

```bash
docker compose --profile verify run --rm verify
```

---

## Tablas en `public` (las que verás en tu cliente SQL)

| Tabla | Contenido |
|-------|-----------|
| `churches` | Iglesias |
| `users` | Usuarios de la app |
| `leaders` | Líderes |
| `members` | Creyentes / integrantes |
| `cells` | Células |
| `cell_helpers` | Ayudantes de célula |
| `member_visits` | Visitas pastorales |
| `member_history_events` | Historial del creyente |
| `baptism_calendar` | Fechas de bautismo |
| `baptism_assigned_members` | Creyentes asignados al bautismo |
| `notifications` | Notificaciones |
| `cell_attendance_sessions` | Asistencia de célula |
| `unassigned_disciples` | Discípulos sin célula (pool) |

Cada tabla incluye **`raw_data`** (JSONB) con el documento original por si falta algún campo en columnas.

---

## Conexión

```
Host:     localhost
Puerto:   5432
Usuario:  church
Password: church
Base:     church_register
Esquema:  public   ← tablas aquí
```

---

## Consultas de ejemplo

```sql
SELECT id, first_name, last_name, phone, assigned_cell_code
FROM public.members
LIMIT 10;

SELECT id, email, church_id FROM public.users;

SELECT c.code, c.leader_name, COUNT(m.id) AS disciples
FROM public.cells c
LEFT JOIN public.members m ON m.assigned_cell_id = c.id
GROUP BY c.id, c.code, c.leader_name
ORDER BY disciples DESC;

-- Campo extra que no está en columnas:
SELECT id, raw_data->>'volunteer' FROM public.members WHERE raw_data ? 'volunteer';
```

---

## Comandos útiles

```bash
docker compose down          # parar
docker compose down -v       # borrar volumen y empezar de cero
docker exec -it church_register_postgres psql -U church -d church_register
```

---

## Sin Docker

```bash
npm install
cp .env.example .env
npm run migrate      # Firestore → espejo
npm run normalize    # espejo → public.*
npm run verify
```

---

## Notas

- La app Flutter **sigue usando Firebase**; esto es copia/backup/analytics.
- No migra Auth, Storage ni FCM.
- `docker compose up migrate normalize` puede repetirse; actualiza datos existentes.
