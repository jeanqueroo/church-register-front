"""Genera capturas 1284×2778 para App Store (iPhone 6.5") alineadas con la UI Android."""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

from generate_play_assets import (
    ACCENT,
    BG_WARM,
    ON_SURFACE,
    PRIMARY,
    PRIMARY_LIGHT,
    SURFACE,
    TEXT_SECONDARY,
    load_logo,
)

ROOT = Path(__file__).resolve().parent
OUT_DIR = ROOT / "ios-screenshots" / "6.5-inch"
WIDTH, HEIGHT = 1284, 2778

STAT_MEMBERS = ((227, 242, 253), (21, 101, 192))
STAT_NEW = ((232, 245, 233), (46, 125, 50))
STAT_LEADERS = ((243, 229, 245), (123, 31, 162))
DIVIDER = (228, 224, 216)
ICON_BG = (232, 240, 248)


def _font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    candidates = [
        "C:/Windows/Fonts/segoeuib.ttf" if bold else "C:/Windows/Fonts/segoeui.ttf",
        "C:/Windows/Fonts/arialbd.ttf" if bold else "C:/Windows/Fonts/arial.ttf",
    ]
    for path in candidates:
        try:
            return ImageFont.truetype(path, size)
        except OSError:
            continue
    return ImageFont.load_default()


def _rounded_rect(
    draw: ImageDraw.ImageDraw,
    box: tuple[int, int, int, int],
    radius: int,
    fill: tuple[int, int, int],
    outline: tuple[int, int, int] | None = None,
    width: int = 2,
) -> None:
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width if outline else 0)


def _draw_status_bar(draw: ImageDraw.ImageDraw) -> None:
    draw.rectangle((0, 0, WIDTH, 54), fill=PRIMARY)


def _draw_app_bar(
    draw: ImageDraw.ImageDraw,
    title: str,
    *,
    back: bool = False,
    menu: bool = False,
    notifications: int = 0,
) -> None:
    top = 54
    height = 112
    draw.rectangle((0, top, WIDTH, top + height), fill=PRIMARY)
    if back:
        draw.text((36, top + 34), "←", fill="white", font=_font(42))
    elif menu:
        draw.rectangle((40, top + 38, 76, top + 46), fill="white")
        draw.rectangle((40, top + 54, 76, top + 62), fill="white")
        draw.rectangle((40, top + 70, 76, top + 78), fill="white")
    title_font = _font(34, bold=True)
    bbox = draw.textbbox((0, 0), title, font=title_font)
    tw = bbox[2] - bbox[0]
    draw.text(((WIDTH - tw) // 2, top + 36), title, fill="white", font=title_font)
    if notifications > 0:
        draw.ellipse((WIDTH - 150, top + 30, WIDTH - 102, top + 78), outline="white", width=3)
        draw.text((WIDTH - 138, top + 40), "🔔", fill="white", font=_font(24))
        draw.ellipse((WIDTH - 112, top + 24, WIDTH - 84, top + 52), fill=(220, 38, 38))
        draw.text((WIDTH - 104, top + 28), str(notifications), fill="white", font=_font(18, bold=True))
    draw.ellipse((WIDTH - 88, top + 28, WIDTH - 40, top + 76), outline=ACCENT, width=4)
    draw.ellipse((WIDTH - 76, top + 40, WIDTH - 52, top + 64), fill=(200, 220, 235))


def _draw_bottom_nav(draw: ImageDraw.ImageDraw, active: int = 0) -> None:
    y = HEIGHT - 132
    draw.rectangle((0, y, WIDTH, HEIGHT), fill=SURFACE)
    draw.line([(0, y), (WIDTH, y)], fill=DIVIDER, width=2)
    labels = ["Inicio", "Creyentes", "Líderes", "Células", "Más"]
    icons = ["⌂", "👥", "★", "⌂", "•••"]
    slot = WIDTH // 5
    for i, (icon, label) in enumerate(zip(icons, labels)):
        cx = slot * i + slot // 2
        color = PRIMARY if i == active else TEXT_SECONDARY
        draw.text((cx - 14, y + 18), icon, fill=color, font=_font(30))
        bbox = draw.textbbox((0, 0), label, font=_font(22))
        tw = bbox[2] - bbox[0]
        draw.text((cx - tw // 2, y + 58), label, fill=color, font=_font(22, bold=(i == active)))


def _draw_welcome_header(
    canvas: Image.Image,
    draw: ImageDraw.ImageDraw,
    y: int,
    title: str,
    subtitle: str,
    badge: str | None = None,
) -> int:
    _rounded_rect(draw, (32, y, WIDTH - 32, y + 170), 18, SURFACE, DIVIDER)
    logo = load_logo(96)
    canvas.paste(logo, (56, y + 36), logo)
    draw.text((176, y + 40), title, fill=PRIMARY, font=_font(34, bold=True))
    draw.text((176, y + 88), subtitle, fill=TEXT_SECONDARY, font=_font(26))
    if badge:
        bbox = draw.textbbox((0, 0), badge, font=_font(22, bold=True))
        bw = bbox[2] - bbox[0] + 28
        _rounded_rect(draw, (176, y + 124, 176 + bw, y + 162), 20, (227, 242, 253))
        draw.text((190, y + 130), badge, fill=PRIMARY_LIGHT, font=_font(22, bold=True))
    return y + 190


def _draw_section_title(draw: ImageDraw.ImageDraw, y: int, title: str) -> None:
    draw.text((40, y), title, fill=PRIMARY, font=_font(34, bold=True))


def _draw_stat_card(
    draw: ImageDraw.ImageDraw,
    x: int,
    y: int,
    value: str,
    title: str,
    subtitle: str,
    colors: tuple[tuple[int, int, int], tuple[int, int, int]],
) -> None:
    bg, fg = colors
    w, h = 300, 260
    _rounded_rect(draw, (x, y, x + w, y + h), 18, bg)
    draw.text((x + 24, y + 110), value, fill=fg, font=_font(52, bold=True))
    draw.text((x + 24, y + 176), title, fill=fg, font=_font(28, bold=True))
    draw.text((x + 24, y + 214), subtitle, fill=fg, font=_font(22))


def _draw_menu_tile(
    draw: ImageDraw.ImageDraw,
    y: int,
    title: str,
    subtitle: str,
    glyph: str,
) -> None:
    draw.ellipse((48, y + 18, 116, y + 86), fill=ICON_BG)
    draw.text((68, y + 34), glyph, fill=PRIMARY_LIGHT, font=_font(30))
    draw.text((140, y + 24), title, fill=PRIMARY, font=_font(32, bold=True))
    draw.text((140, y + 68), subtitle, fill=TEXT_SECONDARY, font=_font(24))
    draw.line([(40, y + 112), (WIDTH - 40, y + 112)], fill=DIVIDER, width=1)


def _draw_quick_action(
    draw: ImageDraw.ImageDraw,
    y: int,
    title: str,
    subtitle: str,
) -> None:
    _rounded_rect(draw, (32, y, WIDTH - 32, y + 118), 16, SURFACE, DIVIDER)
    draw.ellipse((52, y + 28, 108, y + 84), fill=(220, 245, 228))
    _rounded_rect(draw, (58, y + 34, 102, y + 78), 22, (220, 245, 228))
    draw.text((72, y + 42), "+", fill=ACCENT, font=_font(28, bold=True))
    draw.text((128, y + 28), title, fill=PRIMARY, font=_font(30, bold=True))
    draw.text((128, y + 68), subtitle, fill=TEXT_SECONDARY, font=_font(24))
    draw.text((WIDTH - 72, y + 46), "›", fill=TEXT_SECONDARY, font=_font(36))


def _draw_outline_field(
    draw: ImageDraw.ImageDraw,
    y: int,
    label: str,
    value: str = "",
    icon: str = "",
    required: bool = False,
) -> int:
    label_text = f"{label} *" if required else label
    draw.text((48, y), label_text, fill=TEXT_SECONDARY, font=_font(24))
    field_y = y + 34
    _rounded_rect(draw, (40, field_y, WIDTH - 40, field_y + 84), 12, SURFACE, DIVIDER)
    if icon:
        draw.text((64, field_y + 24), icon, fill=TEXT_SECONDARY, font=_font(28))
    if value:
        draw.text((108 if icon else 64, field_y + 26), value, fill=ON_SURFACE, font=_font(30))
    return field_y + 110


def _draw_chip_row(
    draw: ImageDraw.ImageDraw,
    y: int,
    label: str,
    chips: list[str],
    selected: int = 0,
) -> int:
    draw.text((48, y), label, fill=TEXT_SECONDARY, font=_font(24))
    x = 48
    cy = y + 40
    for i, chip in enumerate(chips):
        bbox = draw.textbbox((0, 0), chip, font=_font(24))
        cw = bbox[2] - bbox[0] + 36
        if x + cw > WIDTH - 48:
            x = 48
            cy += 64
        fill = PRIMARY if i == selected else SURFACE
        text_color = "white" if i == selected else ON_SURFACE
        outline = None if i == selected else DIVIDER
        _rounded_rect(draw, (x, cy, x + cw, cy + 52), 26, fill, outline)
        draw.text((x + 18, cy + 12), chip, fill=text_color, font=_font(24))
        x += cw + 12
    return cy + 80


def screenshot_super_admin_home() -> Image.Image:
    canvas = Image.new("RGB", (WIDTH, HEIGHT), BG_WARM)
    draw = ImageDraw.Draw(canvas)
    _draw_status_bar(draw)
    _draw_app_bar(draw, "Manantial de Bendiciones", menu=True)

    y = _draw_welcome_header(
        canvas,
        draw,
        178,
        "Welcome",
        "jeanquero@gmail.com",
        badge="Super administrator",
    )

    items = [
        ("Dashboard de visitas", "Gráficas por día, mes y año", "▤"),
        ("Dashboard pastoral", "Seguimiento, nuevos y oración", "♥"),
        ("Iglesias", "Ver, editar y registrar sedes", "⛪"),
        ("Administradores", "Ver, editar y bloquear cuentas", "🛡"),
        ("Nuevo administrador", "Asignar iglesia al administrador", "＋"),
    ]
    y_item = y + 8
    for title, subtitle, glyph in items:
        _draw_menu_tile(draw, y_item, title, subtitle, glyph)
        y_item += 124

    return canvas


def screenshot_leader_home() -> Image.Image:
    canvas = Image.new("RGB", (WIDTH, HEIGHT), BG_WARM)
    draw = ImageDraw.Draw(canvas)
    _draw_status_bar(draw)
    _draw_app_bar(draw, "Manantial De Bendiciones Central", notifications=3)

    y = _draw_welcome_header(
        canvas,
        draw,
        178,
        "👋 Bienvenido, Miguel Lopez",
        "Gracias por liderar con propósito",
    )

    _draw_section_title(draw, y + 12, "Resumen")
    card_y = y + 64
    _draw_stat_card(
        draw, 40, card_y, "288", "Miembros", "Total de miembros activos", STAT_MEMBERS
    )
    _draw_stat_card(
        draw, 360, card_y, "185", "Nuevo creyentes", "Nuevos creyentes registrados", STAT_NEW
    )
    _draw_stat_card(
        draw, 680, card_y, "16", "Líderes", "Líderes activos", STAT_LEADERS
    )

    _draw_section_title(draw, card_y + 300, "Acciones rápidas")
    actions = [
        ("Registro de nuevo creyente", "Formulario de nuevo creyente"),
        ("Ver nuevos creyentes", "Lista de nuevos creyentes registrados"),
        ("Registro de líderes", "Datos del liderazgo"),
        ("Ver líderes", "Lista de líderes registrados"),
        ("Registro de células", "Datos de la célula"),
    ]
    ay = card_y + 352
    for title, subtitle in actions:
        _draw_quick_action(draw, ay, title, subtitle)
        ay += 132

    _draw_bottom_nav(draw, active=0)
    return canvas


def screenshot_register_member() -> Image.Image:
    canvas = Image.new("RGB", (WIDTH, HEIGHT), BG_WARM)
    draw = ImageDraw.Draw(canvas)
    _draw_status_bar(draw)
    _draw_app_bar(draw, "Registro de nuevo creyente", back=True)

    draw.text((48, 182), "Manantial De Bendiciones Central", fill=PRIMARY, font=_font(30, bold=True))

    y = 250
    y = _draw_outline_field(draw, y, "Fecha", "27/06/2026", "📅")
    y = _draw_chip_row(
        draw,
        y,
        "¿Dónde entró el creyente? *",
        ["Célula", "Campaña fuera de la iglesia", "Hospital", "Evangelismo", "Iglesia madre"],
        selected=0,
    )

    draw.text((48, y), "DATOS PERSONALES", fill=PRIMARY, font=_font(28, bold=True))
    y += 48
    y = _draw_outline_field(draw, y, "Nombre", "", "👤", required=True)
    y = _draw_outline_field(draw, y, "Apellidos", "", "👤", required=True)

    y = _draw_chip_row(draw, y, "Documento", ["DNI", "Pasaporte", "Otro"], selected=0)
    y = _draw_outline_field(draw, y, "Número de documento", "", "🪪")
    y = _draw_chip_row(draw, y, "Género *", ["Hombre (H)", "Mujer (M)"], selected=0)

    _rounded_rect(draw, (40, y, WIDTH - 40, y + 110), 16, SURFACE, DIVIDER)
    draw.text((64, y + 24), "📍", fill=ACCENT, font=_font(28))
    draw.text((120, y + 22), "Incluir dirección", fill=ON_SURFACE, font=_font(30, bold=True))
    draw.text(
        (120, y + 62),
        "Requerida para asignar un líder automático",
        fill=TEXT_SECONDARY,
        font=_font(24),
    )
    _rounded_rect(draw, (WIDTH - 120, y + 36, WIDTH - 64, y + 72), 18, ACCENT)
    draw.ellipse((WIDTH - 98, y + 44, WIDTH - 72, y + 64), fill="white")

    return canvas


def screenshot_members_list() -> Image.Image:
    canvas = Image.new("RGB", (WIDTH, HEIGHT), BG_WARM)
    draw = ImageDraw.Draw(canvas)
    _draw_status_bar(draw)
    _draw_app_bar(draw, "Nuevos creyentes", back=True)

    _rounded_rect(draw, (32, 178, WIDTH - 32, 258), 14, SURFACE, DIVIDER)
    draw.text((72, 204), "🔍  Buscar por nombre o teléfono", fill=TEXT_SECONDARY, font=_font(28))

    rows = [
        ("Laura Martínez", "Célula Centro · Registrada hoy"),
        ("Juan Fernández", "Célula Norte · Ayer"),
        ("Sofía López", "Sin célula · Esta semana"),
        ("Diego Ramírez", "Célula Sur · 24/06/2026"),
        ("Valentina Díaz", "Célula Este · 23/06/2026"),
        ("Mateo Herrera", "Célula Oeste · 22/06/2026"),
        ("Camila Torres", "Célula Centro · 21/06/2026"),
    ]
    y = 286
    for title, subtitle in rows:
        _draw_quick_action(draw, y, title, subtitle)
        y += 132

    _draw_bottom_nav(draw, active=1)
    return canvas


def screenshot_visits_dashboard() -> Image.Image:
    canvas = Image.new("RGB", (WIDTH, HEIGHT), BG_WARM)
    draw = ImageDraw.Draw(canvas)
    _draw_status_bar(draw)
    _draw_app_bar(draw, "Dashboard de visitas", back=True)

    _draw_section_title(draw, 186, "Visitas este mes")
    _rounded_rect(draw, (32, 244, WIDTH - 32, 394), 18, SURFACE, DIVIDER)
    draw.text((56, 276), "47", fill=PRIMARY, font=_font(64, bold=True))
    draw.text((56, 348), "Visitas registradas", fill=TEXT_SECONDARY, font=_font(28))

    chart_top = 430
    _rounded_rect(draw, (32, chart_top, WIDTH - 32, 1180), 22, SURFACE, DIVIDER)
    draw.text((56, chart_top + 24), "Por semana", fill=PRIMARY, font=_font(32, bold=True))
    bars = [90, 150, 70, 180, 130, 110, 160]
    bar_w = 100
    gap = (WIDTH - 64 - len(bars) * bar_w) // (len(bars) + 1)
    x = 56 + gap
    base = 1120
    for h in bars:
        top = base - h * 3
        _rounded_rect(draw, (x, top, x + bar_w, base), 14, ACCENT)
        x += bar_w + gap

    _draw_section_title(draw, 1220, "Líderes con más visitas")
    leaders = [
        ("Pedro Sánchez", "14 visitas este mes"),
        ("Rosa Méndez", "11 visitas este mes"),
        ("Luis Morales", "9 visitas este mes"),
    ]
    y = 1280
    for title, subtitle in leaders:
        _draw_quick_action(draw, y, title, subtitle)
        y += 132

    return canvas


def generate_all() -> list[Path]:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    screens = [
        ("01-super-admin-home.png", screenshot_super_admin_home),
        ("02-leader-home.png", screenshot_leader_home),
        ("03-register-member.png", screenshot_register_member),
        ("04-members-list.png", screenshot_members_list),
        ("05-visits-dashboard.png", screenshot_visits_dashboard),
    ]
    paths: list[Path] = []
    for name, builder in screens:
        out = OUT_DIR / name
        builder().save(out, "PNG", optimize=True)
        paths.append(out)
    return paths


if __name__ == "__main__":
    for path in generate_all():
        print(path)
