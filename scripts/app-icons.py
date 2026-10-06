import json
import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / 'Green Passport' / 'Assets.xcassets'
MASCOT = Image.open(ASSETS / 'mascot.imageset' / 'mascot.png').convert('RGBA')
SIZE = 1024
PREVIEW_SIZE = 180
MASCOT_HEIGHT = 800
MASCOT_CENTER_Y = 540
SHADOW_OFFSET = 18
SHADOW_BLUR = 24
SHADOW_ALPHA = 90
STAR_COUNT = 70
STAR_SEED = 7


def rgba(hex_color, alpha=255):
    value = int(hex_color.lstrip('#'), 16)
    return ((value >> 16) & 255, (value >> 8) & 255, value & 255, alpha)


def vertical_gradient(top, bottom):
    strip = Image.new('RGBA', (1, 2))
    strip.putpixel((0, 0), rgba(top))
    strip.putpixel((0, 1), rgba(bottom))
    return strip.resize((SIZE, SIZE), Image.BICUBIC)


def radial_gradient(center, edge):
    inner, outer = rgba(center), rgba(edge)
    image = Image.new('RGBA', (SIZE, SIZE))
    pixels = image.load()
    half = SIZE / 2
    max_distance = math.hypot(half, half)
    for y in range(SIZE):
        for x in range(SIZE):
            t = min(math.hypot(x - half, y - half * 0.9) / max_distance, 1) ** 1.4
            pixels[x, y] = tuple(round(a + (b - a) * t) for a, b in zip(inner, outer))
    return image


def glow(image, box, color, blur):
    layer = Image.new('RGBA', image.size, (0, 0, 0, 0))
    ImageDraw.Draw(layer).ellipse(box, fill=color)
    image.alpha_composite(layer.filter(ImageFilter.GaussianBlur(blur)))


def sunset():
    image = vertical_gradient('#FFC27A', '#E85A7A')
    glow(image, (212, 160, 812, 760), rgba('#FFF1C2', 170), 30)
    glow(image, (292, 240, 732, 680), rgba('#FFE7A0', 230), 4)
    return image


def night():
    image = vertical_gradient('#0D1A36', '#24426E')
    draw = ImageDraw.Draw(image)
    rng = random.Random(STAR_SEED)
    for _ in range(STAR_COUNT):
        x, y = rng.randint(0, SIZE), rng.randint(0, SIZE)
        radius = rng.choice((2, 2, 3, 4))
        draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=rgba('#FFFFFF', rng.randint(140, 255)))
    moon = Image.new('L', (SIZE, SIZE), 0)
    moon_draw = ImageDraw.Draw(moon)
    moon_draw.ellipse((720, 90, 900, 270), fill=255)
    moon_draw.ellipse((770, 70, 950, 250), fill=0)
    glow(image, (690, 60, 930, 300), rgba('#F6EDC4', 60), 30)
    image.paste(rgba('#F6EDC4'), (0, 0), moon)
    return image


def ocean():
    image = vertical_gradient('#4FD2C6', '#0B4F82')
    for offset, color in ((690, rgba('#7FE3D8', 90)), (790, rgba('#0A3F6B', 140))):
        layer = Image.new('RGBA', image.size, (0, 0, 0, 0))
        points = [(x, offset + 34 * math.sin(x / SIZE * math.tau * 1.5 + offset)) for x in range(0, SIZE + 8, 8)]
        ImageDraw.Draw(layer).polygon(points + [(SIZE, SIZE), (0, SIZE)], fill=color)
        image.alpha_composite(layer)
    return image


def lime():
    return radial_gradient('#F3FCC0', '#9DCC32')


def compose(background):
    canvas = background.copy()
    scale = MASCOT_HEIGHT / MASCOT.height
    mascot = MASCOT.resize((round(MASCOT.width * scale), MASCOT_HEIGHT), Image.LANCZOS)
    left = (SIZE - mascot.width) // 2
    top = MASCOT_CENTER_Y - MASCOT_HEIGHT // 2
    shadow = Image.new('RGBA', canvas.size, (0, 0, 0, 0))
    shadow.paste((0, 0, 0, SHADOW_ALPHA), (left, top + SHADOW_OFFSET), mascot.split()[3])
    canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(SHADOW_BLUR)))
    canvas.alpha_composite(mascot, (left, top))
    return canvas.convert('RGB')


def write_icon_set(name, icon):
    folder = ASSETS / f'AppIcon{name}.appiconset'
    folder.mkdir(exist_ok=True)
    icon.save(folder / 'icon.png', optimize=True)
    contents = {
        'images': [{'filename': 'icon.png', 'idiom': 'universal', 'platform': 'ios', 'size': '1024x1024'}],
        'info': {'author': 'xcode', 'version': 1},
    }
    (folder / 'Contents.json').write_text(json.dumps(contents, indent=2) + '\n')


def write_preview(name, icon):
    folder = ASSETS / f'AppIconPreview{name}.imageset'
    folder.mkdir(exist_ok=True)
    icon.convert('RGB').resize((PREVIEW_SIZE, PREVIEW_SIZE), Image.LANCZOS).save(folder / 'preview.png', optimize=True)
    contents = {
        'images': [{'filename': 'preview.png', 'idiom': 'universal'}],
        'info': {'author': 'xcode', 'version': 1},
    }
    (folder / 'Contents.json').write_text(json.dumps(contents, indent=2) + '\n')


def main():
    write_preview('Standard', Image.open(ASSETS / 'AppIcon.appiconset' / 'icon1.png'))
    write_preview('Dark', Image.open(ASSETS / 'AppIconDark.appiconset' / 'icon2.png'))
    for name, scene in (('Sunset', sunset), ('Night', night), ('Ocean', ocean), ('Lime', lime)):
        icon = compose(scene())
        write_icon_set(name, icon)
        write_preview(name, icon)


if __name__ == '__main__':
    main()
