"""Genera icono 512x512 y banner 1024x500 para Google Play Console."""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
LOGO = ROOT / "assets" / "images" / "logo_iglesia.png"
OUT = Path(__file__).resolve().parent
BRAND = "#1B3A5C"
BRAND_RGB = (27, 58, 92)
# Zona segura Play Store: keyline 75 % → ~384 px en canvas 512 px.
PLAY_ICON_SAFE_PX = 384


def load_logo(max_size: int) -> Image.Image:
    logo = Image.open(LOGO).convert("RGBA")
    logo.thumbnail((max_size, max_size), Image.Resampling.LANCZOS)
    return logo


def paste_center(base: Image.Image, overlay: Image.Image) -> None:
    x = (base.width - overlay.width) // 2
    y = (base.height - overlay.height) // 2
    base.paste(overlay, (x, y), overlay)


def generate_icon() -> Path:
    """Icono 512×512 para Play Console (32-bit PNG, < 1 MB, zona segura 384 px)."""
    size = 512
    canvas = Image.new("RGBA", (size, size), BRAND_RGB + (255,))
    logo = load_logo(PLAY_ICON_SAFE_PX - 24)
    paste_center(canvas, logo)
    out = OUT / "play-store-icon-512.png"
    canvas.save(out, "PNG", optimize=True)
    return out


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


def generate_banner() -> Path:
    width, height = 1024, 500
    canvas = Image.new("RGB", (width, height), BRAND_RGB)
    draw = ImageDraw.Draw(canvas)

    # Acento dorado (plantilla Manantial).
    accent = (201, 162, 39)
    draw.ellipse((760, 220, 1120, 580), fill=accent)

    logo = load_logo(260)
    canvas.paste(logo, (72, (height - logo.height) // 2), logo)

    title = "Manantial de Bendiciones"
    subtitle = "Registro pastoral y seguimiento de integrantes"
    title_font = _font(52, bold=True)
    subtitle_font = _font(28)

    text_x = 380
    draw.text((text_x, 170), title, fill="white", font=title_font)
    draw.text((text_x, 245), subtitle, fill=(232, 236, 242), font=subtitle_font)

    features = [
        "Integrantes y líderes",
        "Visitas y dashboards",
        "Mapas y notificaciones",
    ]
    feature_font = _font(22)
    y = 310
    for line in features:
        draw.ellipse((text_x, y + 8, text_x + 10, y + 18), fill=(212, 175, 55))
        draw.text((text_x + 22, y), line, fill="white", font=feature_font)
        y += 38

    out = OUT / "play-store-feature-graphic-1024x500.png"
    canvas.save(out, "PNG", optimize=True)
    return out


if __name__ == "__main__":
    icon = generate_icon()
    banner = generate_banner()
    print(f"Icono: {icon}")
    print(f"Banner: {banner}")
