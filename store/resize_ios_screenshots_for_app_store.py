"""Escala capturas iOS/Android a tamaños válidos para App Store (6.5")."""
from __future__ import annotations

import hashlib
import shutil
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent
SOURCE_DIR = ROOT / "ios-screenshots-source"
OUT_IPHONE_DIR = ROOT / "ios-screenshots" / "6.5-inch"
OUT_IPAD_DIR = ROOT / "ios-screenshots" / "13-inch-iPad"
BG = (245, 243, 239)

# Portrait sizes accepted by App Store Connect.
IPHONE_PORTRAIT = (1284, 2778)
IPHONE_PORTRAIT_ALT = (1242, 2688)
IPAD_PORTRAIT = (2064, 2752)
IPAD_PORTRAIT_ALT = (2048, 2732)


def _fit_portrait(image: Image.Image, target: tuple[int, int]) -> Image.Image:
    tw, th = target
    canvas = Image.new("RGB", target, BG)
    scale = min(tw / image.width, th / image.height)
    resized = image.resize(
        (max(1, int(image.width * scale)), max(1, int(image.height * scale))),
        Image.Resampling.LANCZOS,
    )
    x = (tw - resized.width) // 2
    y = (th - resized.height) // 2
    canvas.paste(resized, (x, y))
    return canvas


def _file_hash(path: Path) -> str:
    return hashlib.md5(path.read_bytes()).hexdigest()


def process_sources(
    sources: list[Path],
    names: list[str] | None = None,
    *,
    out_dir: Path = OUT_IPHONE_DIR,
    target: tuple[int, int] = IPHONE_PORTRAIT,
) -> list[Path]:
    out_dir.mkdir(parents=True, exist_ok=True)
    seen: set[str] = set()
    outputs: list[Path] = []
    index = 1

    for source in sources:
        digest = _file_hash(source)
        if digest in seen:
            continue
        seen.add(digest)

        image = Image.open(source).convert("RGB")
        label = names[index - 1] if names and index - 1 < len(names) else source.stem
        safe = "".join(c if c.isalnum() or c in "-_" else "-" for c in label).strip("-")
        fitted = _fit_portrait(image, target)
        out = out_dir / f"{index:02d}-{safe}.png"
        fitted.save(out, "PNG", optimize=True)
        outputs.append(out)
        index += 1

    return outputs


def process_iphone_screenshots_for_ipad(
    iphone_dir: Path = OUT_IPHONE_DIR,
    out_dir: Path = OUT_IPAD_DIR,
    target: tuple[int, int] = IPAD_PORTRAIT,
) -> list[Path]:
    """Convierte capturas iPhone ya generadas a tamaño iPad 13\"."""
    files = sorted(iphone_dir.glob("*.png"))
    if not files:
        return []

    out_dir.mkdir(parents=True, exist_ok=True)
    outputs: list[Path] = []
    for source in files:
        image = Image.open(source).convert("RGB")
        fitted = _fit_portrait(image, target)
        out = out_dir / source.name
        fitted.save(out, "PNG", optimize=True)
        outputs.append(out)
    return outputs


def main() -> None:
    if not SOURCE_DIR.exists():
        SOURCE_DIR.mkdir(parents=True)

    files = sorted(SOURCE_DIR.glob("*.png"))
    if not files:
        print(f"Coloca capturas PNG en: {SOURCE_DIR}")
        return

    for path in process_sources(files):
        with Image.open(path) as img:
            print(f"{path} -> {img.size}")


def import_from_paths(paths: list[Path], names: list[str]) -> list[Path]:
    SOURCE_DIR.mkdir(parents=True, exist_ok=True)
    copied: list[Path] = []
    for src, name in zip(paths, names, strict=True):
        dest = SOURCE_DIR / f"{name}.png"
        shutil.copy2(src, dest)
        copied.append(dest)
    return process_sources(copied, names=names)


if __name__ == "__main__":
    ipad = process_iphone_screenshots_for_ipad()
    if ipad:
        for path in ipad:
            with Image.open(path) as img:
                print(f"iPad: {path} -> {img.size}")
    else:
        main()
