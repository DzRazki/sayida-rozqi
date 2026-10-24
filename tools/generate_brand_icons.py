from pathlib import Path
import xml.etree.ElementTree as ET
from PIL import Image, ImageDraw, ImageOps

root = Path(__file__).resolve().parents[1]
source = root / 'app/src/main/assets/file_000000006aec822f86d7646dc1970fb0.png'
res = root / 'android/app/src/main/res'
manifest = root / 'android/app/src/main/AndroidManifest.xml'
if not source.is_file() or not manifest.is_file():
    raise SystemExit('Logo or generated Flutter Android project is missing')
image = Image.open(source).convert('RGBA')
edge = max(image.size)
square = Image.new('RGBA', (edge, edge), (33, 21, 15, 255))
square.alpha_composite(image, ((edge - image.width) // 2, (edge - image.height) // 2))
mask = Image.new('L', (edge, edge), 0)
ImageDraw.Draw(mask).ellipse((0, 0, edge - 1, edge - 1), fill=255)
square.putalpha(mask)
for density, scale in [('mdpi', 1), ('hdpi', 1.5), ('xhdpi', 2), ('xxhdpi', 3), ('xxxhdpi', 4)]:
    folder = res / f'mipmap-{density}'
    folder.mkdir(parents=True, exist_ok=True)
    size = round(48 * scale)
    icon = square.resize((size, size), Image.Resampling.LANCZOS)
    for name in ['ic_launcher', 'ic_launcher_round']:
        icon.save(folder / f'{name}.png')
    canvas_size = round(108 * scale)
    logo_size = round(66 * scale)
    foreground = Image.new('RGBA', (canvas_size, canvas_size), (0, 0, 0, 0))
    logo = square.resize((logo_size, logo_size), Image.Resampling.LANCZOS)
    offset = (canvas_size - logo_size) // 2
    foreground.alpha_composite(logo, (offset, offset))
    foreground.save(folder / 'ic_launcher_foreground.png')
values = res / 'values'
values.mkdir(parents=True, exist_ok=True)
(values / 'brand_icon_colors.xml').write_text('<?xml version="1.0" encoding="utf-8"?>\n<resources><color name="brand_icon_background">#21150F</color></resources>\n', encoding='utf-8')
adaptive = res / 'mipmap-anydpi-v26'
adaptive.mkdir(parents=True, exist_ok=True)
xml = '<?xml version="1.0" encoding="utf-8"?>\n<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android"><background android:drawable="@color/brand_icon_background"/><foreground android:drawable="@mipmap/ic_launcher_foreground"/></adaptive-icon>\n'
for name in ['ic_launcher', 'ic_launcher_round']:
    (adaptive / f'{name}.xml').write_text(xml, encoding='utf-8')
namespace = 'http://schemas.android.com/apk/res/android'
ET.register_namespace('android', namespace)
tree = ET.parse(manifest)
application = tree.getroot().find('application')
if application is None:
    raise SystemExit('Android application element is missing')
application.set(f'{{{namespace}}}icon', '@mipmap/ic_launcher')
application.set(f'{{{namespace}}}roundIcon', '@mipmap/ic_launcher_round')
tree.write(manifest, encoding='utf-8', xml_declaration=True)
for path in [res / 'mipmap-mdpi/ic_launcher.png', adaptive / 'ic_launcher.xml']:
    if not path.is_file() or path.stat().st_size == 0:
        raise SystemExit(f'Icon generation failed: {path}')
