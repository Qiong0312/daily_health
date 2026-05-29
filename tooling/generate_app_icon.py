#!/usr/bin/env python3
"""Generate Bloom app icons from the in-app 🌸 emoji (macOS) or a vector fallback."""

from __future__ import annotations

import math
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw

ROSE100 = (252, 231, 243)
ROSE200 = (251, 207, 232)
ROSE300 = (249, 168, 212)
ROSE600 = (219, 39, 119)
ROSE700 = (190, 24, 93)
WHITE = (255, 255, 255)

ROOT = Path(__file__).resolve().parent.parent
TOOLING = Path(__file__).resolve().parent
SWIFT_RENDERER = TOOLING / "render_bloom_master.swift"


def _lerp(a: int, b: int, t: float) -> int:
    return int(a + (b - a) * t)


def _pink_backdrop(img: Image.Image) -> None:
    w, h = img.size
    px = img.load()
    for y in range(h):
        t = y / max(h - 1, 1)
        row = (
            _lerp(ROSE100[0], ROSE300[0], t),
            _lerp(ROSE100[1], ROSE300[1], t),
            _lerp(ROSE100[2], ROSE300[2], t),
        )
        for x in range(w):
            px[x, y] = row


def _draw_bloom_vector(draw: ImageDraw.ImageDraw, size: int) -> None:
    """Fallback when Swift emoji rendering is unavailable."""
    cx = cy = size / 2
    scale = size / 1024.0
    petal_rx = 118 * scale
    petal_ry = 72 * scale
    orbit = 108 * scale
    center_r = 52 * scale

    for i in range(5):
        angle = -math.pi / 2 + i * (2 * math.pi / 5)
        px = cx + orbit * math.cos(angle)
        py = cy + orbit * math.sin(angle)
        bbox = (px - petal_rx, py - petal_ry, px + petal_rx, py + petal_ry)
        draw.ellipse(bbox, fill=WHITE)
        stroke = max(1, int(3 * scale))
        draw.ellipse(bbox, outline=ROSE200, width=stroke)

    draw.ellipse(
        (cx - center_r, cy - center_r, cx + center_r, cy + center_r),
        fill=ROSE600,
    )
    inner = center_r * 0.55
    draw.ellipse(
        (cx - inner, cy - inner, cx + inner, cy + inner),
        fill=ROSE700,
    )


def _draw_icon_vector(size: int) -> Image.Image:
    img = Image.new("RGB", (size, size), ROSE100)
    _pink_backdrop(img)
    draw = ImageDraw.Draw(img)
    _draw_bloom_vector(draw, size)
    return img


def _draw_foreground_vector(size: int) -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    _draw_bloom_vector(draw, size)
    return img


def _render_emoji_pngs() -> tuple[Path, Path]:
    master_path = TOOLING / "app_icon_master_1024.png"
    fg_path = TOOLING / "app_icon_foreground_1024.png"
    subprocess.run(
        ["swift", str(SWIFT_RENDERER), "--out", str(master_path)],
        check=True,
        cwd=TOOLING,
    )
    subprocess.run(
        ["swift", str(SWIFT_RENDERER), "--foreground", "--out", str(fg_path)],
        check=True,
        cwd=TOOLING,
    )
    return master_path, fg_path


def load_images() -> tuple[Image.Image, Image.Image]:
    if sys.platform == "darwin" and SWIFT_RENDERER.is_file():
        try:
            master_path, fg_path = _render_emoji_pngs()
            master = Image.open(master_path).convert("RGB")
            foreground = Image.open(fg_path).convert("RGBA")
            return master, foreground
        except (subprocess.CalledProcessError, OSError) as err:
            print(f"emoji render failed ({err}), using vector fallback")
    return _draw_icon_vector(1024), _draw_foreground_vector(1024)


def write_ios_icons(master: Image.Image) -> None:
    ios_dir = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    specs: list[tuple[str, int]] = [
        ("Icon-App-20x20@1x.png", 20),
        ("Icon-App-20x20@2x.png", 40),
        ("Icon-App-20x20@3x.png", 60),
        ("Icon-App-29x29@1x.png", 29),
        ("Icon-App-29x29@2x.png", 58),
        ("Icon-App-29x29@3x.png", 87),
        ("Icon-App-40x40@1x.png", 40),
        ("Icon-App-40x40@2x.png", 80),
        ("Icon-App-40x40@3x.png", 120),
        ("Icon-App-60x60@2x.png", 120),
        ("Icon-App-60x60@3x.png", 180),
        ("Icon-App-76x76@1x.png", 76),
        ("Icon-App-76x76@2x.png", 152),
        ("Icon-App-83.5x83.5@2x.png", 167),
        ("Icon-App-1024x1024@1x.png", 1024),
    ]
    ios_dir.mkdir(parents=True, exist_ok=True)
    for name, px in specs:
        master.resize((px, px), Image.Resampling.LANCZOS).save(ios_dir / name, "PNG")
    print(f"wrote {len(specs)} iOS icons -> {ios_dir}")


def write_macos_icons(master: Image.Image) -> None:
    mac_dir = ROOT / "macos/Runner/Assets.xcassets/AppIcon.appiconset"
    specs: list[tuple[str, int]] = [
        ("app_icon_16.png", 16),
        ("app_icon_32.png", 32),
        ("app_icon_64.png", 64),
        ("app_icon_128.png", 128),
        ("app_icon_256.png", 256),
        ("app_icon_512.png", 512),
        ("app_icon_1024.png", 1024),
    ]
    mac_dir.mkdir(parents=True, exist_ok=True)
    for name, px in specs:
        master.resize((px, px), Image.Resampling.LANCZOS).save(mac_dir / name, "PNG")
    print(f"wrote {len(specs)} macOS icons -> {mac_dir}")


def write_android_icons(master: Image.Image, foreground: Image.Image) -> None:
    res = ROOT / "android/app/src/main/res"
    densities: list[tuple[str, int]] = [
        ("mipmap-mdpi", 48),
        ("mipmap-hdpi", 72),
        ("mipmap-xhdpi", 96),
        ("mipmap-xxhdpi", 144),
        ("mipmap-xxxhdpi", 192),
    ]
    for folder, px in densities:
        out_dir = res / folder
        out_dir.mkdir(parents=True, exist_ok=True)
        master.resize((px, px), Image.Resampling.LANCZOS).save(
            out_dir / "ic_launcher.png", "PNG"
        )
    fg_dir = res / "drawable-nodpi"
    fg_dir.mkdir(parents=True, exist_ok=True)
    foreground.resize((432, 432), Image.Resampling.LANCZOS).save(
        fg_dir / "ic_launcher_foreground.png", "PNG"
    )
    print(f"wrote Android launcher icons -> {res}")


def write_flutter_mark(master: Image.Image) -> None:
    """In-app blossom mark (matches home-screen icon)."""
    assets_dir = ROOT / "assets/icons"
    assets_dir.mkdir(parents=True, exist_ok=True)
    master.resize((256, 256), Image.Resampling.LANCZOS).save(
        assets_dir / "bloom_mark.png", "PNG"
    )
    print(f"wrote Flutter mark -> {assets_dir / 'bloom_mark.png'}")


def main() -> None:
    master, foreground = load_images()
    preview = TOOLING / "app_icon_preview_1024.png"
    master.save(preview, "PNG")
    print(f"preview -> {preview}")
    write_ios_icons(master)
    write_macos_icons(master)
    write_android_icons(master, foreground)
    write_flutter_mark(master)


if __name__ == "__main__":
    main()
