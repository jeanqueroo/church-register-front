"""Escala capturas Android reales a 1284×2778 para App Store (6.5")."""
from __future__ import annotations

from pathlib import Path

from PIL import Image

TARGET = (1284, 2778)
SOURCE_DIR = Path(__file__).resolve().parent / "android-screenshots-source"
OUT_DIR = Path(__file__).resolve().parent / "ios-screenshots" / "6.5-inch"
BG = (245, 243, 239)


def fit_for_app_store(image: Image.Image) -> Image.Image:
    canvas = Image.new("RGB", TARGET, BG)
    scale = min(TARGET[0] / image.width, TARGET[1] / image.height)
    resized = image.resize(
        (int(image.width * scale), int(image.height * scale)),
        Image.Resampling.LANCZOS,
    )
    x = (TARGET[0] - resized.width) // 2
    y = (TARGET[1] - resized.height) // 2
    canvas.paste(resized, (x, y))
    return canvas


def main() -> None:
    if not SOURCE_DIR.exists():
        SOURCE_DIR.mkdir(parents=True)
        print(f"Crea capturas Android en: {SOURCE_DIR}")
        return

    files = sorted(SOURCE_DIR.glob("*.png"))
    if not files:
        print(f"No hay PNG en {SOURCE_DIR}")
        return

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for index, path in enumerate(files, start=1):
        image = Image.open(path).convert("RGB")
        out = OUT_DIR / f"{index:02d}-{path.stem}.png"
        fit_for_app_store(image).save(out, "PNG", optimize=True)
        print(out)


if __name__ == "__main__":
    main()
