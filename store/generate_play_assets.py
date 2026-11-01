"""Genera icono 512x512 y banner 1024x500 para Google Play Console."""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
LOGO = ROOT / "assets" / "images" / "logo_iglesia.png"
OUT = Path(__file__).resolve().parent
BRAND_RGB = (27, 58, 92)

# Tema Manantial (lib/core/theme/theme_templates.dart)
PRIMARY = (27, 58, 92)          # #1B3A5C
PRIMARY_DARK = (15, 36, 56)     # #0F2438
PRIMARY_LIGHT = (46, 90, 135)   # #2E5A87
ACCENT = (22, 163, 74)          # #16A34A
BG_WARM = (245, 243, 239)       # #F5F3EF
SURFACE = (255, 255, 255)
ON_SURFACE = (26, 35, 50)        # #1A2332
TEXT_SECONDARY = (92, 107, 122)  # #5C6B7A

# Zona segura Play Store: keyline 75 % → ~384 px en canvas 512 px.
PLAY_ICON_SAFE_PX = 384


def load_logo(max_size: int) -> Image.Image:
    logo = Image.open(LOGO).convert("RGBA")
    logo.thumbnail((max_size, max_size), Image.Resampling.LANCZOS)
    return logo


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


def _vertical_gradient(
    size: tuple[int, int],
    top: tuple[int, int, int],
    bottom: tuple[int, int, int],
) -> Image.Image:
    width, height = size
    gradient = Image.new("RGB", size)
    draw = ImageDraw.Draw(gradient)
    for y in range(height):
        ratio = y / max(height - 1, 1)
        color = tuple(
            int(top[i] + (bottom[i] - top[i]) * ratio) for i in range(3)
        )
        draw.line([(0, y), (width, y)], fill=color)
    return gradient


def _paste_center(base: Image.Image, overlay: Image.Image) -> None:
    x = (base.width - overlay.width) // 2
    y = (base.height - overlay.height) // 2
    base.paste(overlay, (x, y), overlay)


def generate_icon() -> Path:
    """Icono 512×512 para Play Console (zona segura 384 px)."""
    size = 512
    canvas = _vertical_gradient((size, size), PRIMARY, PRIMARY_LIGHT).convert("RGBA")

    logo = load_logo(PLAY_ICON_SAFE_PX - 24)
    _paste_center(canvas, logo)

    out = OUT / "play-store-icon-512.png"
    canvas.save(out, "PNG", optimize=True)
    return out


def _paste_at(base: Image.Image, overlay: Image.Image, x: int, y: int) -> None:
    base.paste(overlay, (x, y), overlay)


def _draw_ui_preview(canvas: Image.Image, origin: tuple[int, int]) -> None:
    ox, oy = origin
    preview_w, preview_h = 280, 340
    draw = ImageDraw.Draw(canvas)

    draw.rounded_rectangle(
        (ox, oy, ox + preview_w, oy + preview_h),
        radius=22,
        fill=SURFACE,
        outline=(228, 224, 216),
        width=2,
    )

    logo = load_logo(150)
    logo_x = ox + (preview_w - logo.width) // 2
    logo_y = oy + (preview_h - logo.height) // 2
    _paste_at(canvas, logo, logo_x, logo_y)


def generate_banner() -> Path:
    """Banner 1024×500 alineado con el home actual de la app."""
    width, height = 1024, 500
    canvas = Image.new("RGB", (width, height), BG_WARM)
    draw = ImageDraw.Draw(canvas)

    # Barra superior como el AppBar.
    draw.rectangle((0, 0, width, 58), fill=PRIMARY)
    draw.text((32, 16), "Manantial de Bendiciones", fill="white", font=_font(22, bold=True))

    _draw_ui_preview(canvas, (36, 78))

    text_x = 430
    draw.text((text_x, 98), "Gestión pastoral", fill=PRIMARY, font=_font(46, bold=True))
    draw.text((text_x, 154), "para tu iglesia", fill=PRIMARY, font=_font(46, bold=True))
    draw.text(
        (text_x, 218),
        "Integrantes, líderes, células, visitas,\nbautismos y reportes en un solo lugar.",
        fill=TEXT_SECONDARY,
        font=_font(20),
    )

    features = [
        "Dashboard con resumen en tiempo real",
        "Mapas, notificaciones y roles",
        "Interfaz clara para el equipo de líderes",
    ]
    y = 310
    for line in features:
        draw.rounded_rectangle((text_x, y + 6, text_x + 10, y + 16), radius=5, fill=ACCENT)
        draw.text((text_x + 20, y), line, fill=ON_SURFACE, font=_font(18))
        y += 36

    badge_font = _font(16, bold=True)
    badge_text = "Disponible en Android"
    bbox = draw.textbbox((0, 0), badge_text, font=badge_font)
    badge_w = bbox[2] - bbox[0] + 24
    badge_h = bbox[3] - bbox[1] + 14
    badge_x = text_x
    badge_y = height - badge_h - 42
    draw.rounded_rectangle(
        (badge_x, badge_y, badge_x + badge_w, badge_y + badge_h),
        radius=12,
        fill=ACCENT,
    )
    draw.text((badge_x + 12, badge_y + 5), badge_text, fill="white", font=badge_font)

    out = OUT / "play-store-feature-graphic-1024x500.png"
    canvas.save(out, "PNG", optimize=True)
    return out


if __name__ == "__main__":
    icon = generate_icon()
    banner = generate_banner()
    print(f"Icono: {icon}")
    print(f"Banner: {banner}")
