"""Importa las capturas WhatsApp del usuario y las escala para App Store."""
from pathlib import Path

from resize_ios_screenshots_for_app_store import import_from_paths

ASSETS = Path(
    r"C:\Users\34658\.cursor\projects\c-workspace-church-register-front\assets"
)

FILES = [
    ("*a1ec730f-4494-4e29-8970-342ae64b6c6d.png", "sign-in"),
    ("*9abdc6c5-9cf6-4c87-97f7-187a8769f5de.png", "home"),
    ("*66f1f714-db5d-49a2-a2b5-9f294813bcc4.png", "visits-dashboard"),
]

paths = []
names = []
for pattern, name in FILES:
    match = next(ASSETS.glob(pattern))
    paths.append(match)
    names.append(name)

if __name__ == "__main__":
    for out in import_from_paths(paths, names):
        print(out)
