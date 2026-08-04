#!/usr/bin/env python3
"""Build deterministic web and social derivatives for the Inverts Living Poster."""

from __future__ import annotations

import hashlib
import shutil
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "docs/assets/inverts-living-poster-v2.png"
DOCS_ASSETS = ROOT / "docs/assets"
WWW_ASSETS = ROOT / "www/assets"
EXPECTED_SIZE = (1672, 941)
EXPECTED_SHA256 = "28f7d4cf1e7b323b265d22a00cf9e23b9f0cf0614ebe0c1376a04d4c4c500547"


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def load_font(path: str, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(path, size=size, layout_engine=ImageFont.Layout.BASIC)


def build_web_derivatives(source: Image.Image) -> list[Path]:
    full = DOCS_ASSETS / "inverts-living-poster-v2.webp"
    compact = DOCS_ASSETS / "inverts-living-poster-v2-840.webp"

    source.save(full, "WEBP", quality=82, method=6)
    source.resize((840, 473), Image.Resampling.LANCZOS).save(
        compact, "WEBP", quality=80, method=6
    )

    WWW_ASSETS.mkdir(parents=True, exist_ok=True)
    outputs = [full, compact]
    for path in [SOURCE, full, compact]:
        target = WWW_ASSETS / path.name
        shutil.copyfile(path, target)
        outputs.append(target)
    return outputs


def build_social_card(source: Image.Image) -> Path:
    # Cover-crop the 16:9 art to 1200x630 while preserving its quiet left field.
    scaled = source.resize((1200, 675), Image.Resampling.LANCZOS)
    card = scaled.crop((0, 22, 1200, 652)).convert("RGB")

    # Deepen the copy field without obscuring the benthic organisms on the right.
    overlay = Image.new("RGBA", card.size, (0, 0, 0, 0))
    pixels = overlay.load()
    for x in range(card.width):
        stop = 650
        alpha = 205 if x <= 290 else max(0, round(205 * (stop - x) / (stop - 290)))
        for y in range(card.height):
            pixels[x, y] = (4, 24, 29, alpha)
    card = Image.alpha_composite(card.convert("RGBA"), overlay)

    draw = ImageDraw.Draw(card)
    sans = load_font("/System/Library/Fonts/Supplemental/Arial Bold.ttf", 23)
    serif = load_font("/System/Library/Fonts/Supplemental/Georgia Bold.ttf", 76)
    cream = "#f4ead2"
    amber = "#e2a448"

    draw.text((72, 67), "NEON MY LITTLE INVERTS  ·  UNOFFICIAL", font=sans, fill=amber)
    draw.text((68, 151), "What lives", font=serif, fill=cream, stroke_width=1)
    draw.text((68, 238), "below the", font=serif, fill=cream, stroke_width=1)
    draw.text((68, 325), "surface?", font=serif, fill=amber, stroke_width=1)

    # Screenprint artwork quantizes cleanly and keeps the social card well below
    # the suite's 1.5 MB hard ceiling without changing its dimensions.
    quantized = card.convert("RGB").quantize(
        colors=256, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.FLOYDSTEINBERG
    )
    output = ROOT / "docs/og-image-v2.png"
    quantized.save(output, "PNG", optimize=True)
    return output


def main() -> None:
    if not SOURCE.is_file():
        raise SystemExit(f"missing canonical poster source: {SOURCE}")
    if sha256(SOURCE) != EXPECTED_SHA256:
        raise SystemExit("canonical poster source SHA-256 changed")

    source = Image.open(SOURCE).convert("RGB")
    if source.size != EXPECTED_SIZE:
        raise SystemExit(f"poster is {source.size}; expected {EXPECTED_SIZE}")

    outputs = build_web_derivatives(source)
    outputs.append(build_social_card(source))
    for output in outputs:
        print(f"{output.relative_to(ROOT)}\t{output.stat().st_size}\t{sha256(output)}")


if __name__ == "__main__":
    main()
