"""Bakes the native-splash mark from the brand logo.

Run from the repo root:  python tools/generate_splash_mark.py

Writes:
  assets/icons/splash_mark.png          full mark (glow + engineered frames + card),
                                        for the iOS / Android <12 static splash
  assets/icons/splash_mark_android12.png card-only mark that fits the Android 12
                                        splash circle safe zone

The in-app splash draws the same composition dynamically; this PNG exists because
the native window cannot run animation code. Keep the geometry here in sync with
lib/app/splash_screen.dart (ring ratio 1.23x card, card radius ~23%, logo 64%).
"""

from pathlib import Path
from PIL import Image, ImageChops, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
ICONS = ROOT / "assets" / "icons"

GOLD = (227, 165, 62)
GLOW = (255, 224, 136)
CARD = (4, 44, 37, 255)  # #042C25 — matches the logo artwork background


def radial_glow(size: int, max_alpha: int, power: float = 1.5) -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    center = size / 2
    radius = size / 2
    step = max(2, int(radius / 120))
    for r in range(int(radius), 0, -step):
        alpha = int(max_alpha * (1 - r / radius) ** power)
        draw.ellipse(
            [center - r, center - r, center + r, center + r],
            fill=(*GLOW, alpha),
        )
    return img


def rotated_ring(size: int, box: int, radius: int, stroke: int, color: tuple[int, int, int, int], angle: float) -> Image.Image:
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    half = box / 2
    center = size / 2
    draw.rounded_rectangle(
        [center - half, center - half, center + half, center + half],
        radius=radius,
        outline=color,
        width=stroke,
    )
    return layer.rotate(angle, resample=Image.BICUBIC, center=(size / 2, size / 2))


def trimmed_logo() -> Image.Image:
    """The calligraphy glyph without the dark margin baked into logo_2.

    The artwork carries a faint grunge texture across the whole canvas, so a
    plain difference bounding box never shrinks. Threshold on a strong delta
    instead: the cream strokes separate cleanly from the dark ground.
    """
    logo = Image.open(ICONS / "logo_2.png").convert("RGBA")
    background = Image.new("RGBA", logo.size, (*CARD[:3], 255))
    diff = ImageChops.difference(logo.convert("RGB"), background.convert("RGB"))
    mask = diff.convert("L").point(lambda p: 255 if p > 40 else 0)
    bbox = mask.getbbox()
    return logo.crop(bbox) if bbox else logo


def card_with_logo(size: int, card: int, radius: int, logo_ratio: float, shadow: bool) -> Image.Image:
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))

    if shadow:
        shadow_layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        sdraw = ImageDraw.Draw(shadow_layer)
        offset, blur = 22, 44
        half = card / 2
        c = size / 2 + offset
        sdraw.rounded_rectangle(
            [c - half, c - half, c + half, c + half], radius=radius, fill=(0, 0, 0, 70)
        )
        layer.alpha_composite(shadow_layer.filter(ImageFilter.GaussianBlur(blur)))

    c = size / 2
    half = card / 2
    draw = ImageDraw.Draw(layer)
    draw.rounded_rectangle(
        [c - half, c - half, c + half, c + half], radius=radius, fill=CARD
    )

    glyph = trimmed_logo()
    glyph_width = int(card * logo_ratio)
    glyph_height = int(glyph.height * glyph_width / glyph.width)
    glyph = glyph.resize((glyph_width, glyph_height), Image.LANCZOS)
    layer.paste(glyph, (int(c - glyph_width / 2), int(c - glyph_height / 2)), glyph)
    return layer


def main() -> None:
    # Light mark: subtler gold strokes on the ivory background (approved mock).
    light = Image.new("RGBA", (1080, 1080), (0, 0, 0, 0))
    light.alpha_composite(radial_glow(1080, max_alpha=64))
    light.alpha_composite(rotated_ring(1080, box=690, radius=62, stroke=9, color=(*GOLD, 56), angle=45))
    light.alpha_composite(rotated_ring(1080, box=690, radius=62, stroke=9, color=(*GOLD, 28), angle=22.5))
    light.alpha_composite(card_with_logo(1080, card=560, radius=132, logo_ratio=0.80, shadow=True))
    light.save(ICONS / "splash_mark.png")

    # Dark mark: stronger gold strokes that hold up on #101410.
    dark = Image.new("RGBA", (1080, 1080), (0, 0, 0, 0))
    dark.alpha_composite(radial_glow(1080, max_alpha=40))
    dark.alpha_composite(rotated_ring(1080, box=690, radius=62, stroke=9, color=(*GOLD, 90), angle=45))
    dark.alpha_composite(rotated_ring(1080, box=690, radius=62, stroke=9, color=(*GOLD, 46), angle=22.5))
    dark.alpha_composite(card_with_logo(1080, card=560, radius=132, logo_ratio=0.80, shadow=True))
    dark.save(ICONS / "splash_mark_dark.png")

    android12 = Image.new("RGBA", (960, 960), (0, 0, 0, 0))
    android12.alpha_composite(card_with_logo(960, card=620, radius=142, logo_ratio=0.80, shadow=False))
    android12.save(ICONS / "splash_mark_android12.png")

    trimmed_logo().save(ICONS / "logo_glyph.png")

    print("splash_mark.png + splash_mark_dark.png + splash_mark_android12.png + logo_glyph.png written")


if __name__ == "__main__":
    main()
