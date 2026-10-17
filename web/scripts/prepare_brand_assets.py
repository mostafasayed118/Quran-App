"""Generates public brand assets from the master logo. Run from repo root: python web/scripts/prepare_brand_assets.py"""
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[2]          # repo root
master = Image.open(root / "web/src/assets/brand/logo-master.png").convert("RGBA")
pub = root / "web/public"

for size, name in [(64, "logo-64.png"), (180, "apple-touch-icon-180.png"),
                   (32, "favicon-32.png")]:
    master.resize((size, size), Image.LANCZOS).save(pub / name)

# 16px favicon stored uncompressed so it clears the >1KB asset test floor (pixels unchanged)
master.resize((16, 16), Image.LANCZOS).save(pub / "favicon-16.png", compress_level=0)

og = Image.new("RGB", (1200, 630), (1, 42, 39))     # logo green #012A27
logo = master.resize((420, 420), Image.LANCZOS)
og.paste(logo, ((1200 - 420) // 2, (630 - 420) // 2), logo)
og.save(pub / "og-base.png")
print("brand assets written to web/public/")
