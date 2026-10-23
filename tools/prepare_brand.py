import base64, io, json
from pathlib import Path
from PIL import Image, ImageDraw, ImageOps

root = Path(__file__).resolve().parents[1]
data = json.loads((root / 'tools/brand-images.json').read_text())
assets = root / 'app/src/main/assets'
assets.mkdir(parents=True, exist_ok=True)

def open_brand(names, fallback):
    for name in names:
        path = assets / name
        if path.is_file():
            with Image.open(path) as image:
                return ImageOps.exif_transpose(image).convert('RGB')
    with Image.open(io.BytesIO(base64.b64decode(data[fallback]))) as image:
        return image.convert('RGB')

banner = open_brand(['banner-original.jpg', 'banner.jpg'], 'banner_webp')
banner.save(assets / 'banner.jpg', quality=98, subsampling=0)
logo = open_brand(['logo-original.png', 'logo.png'], 'logo_webp')
logo.save(assets / 'logo.png')
if banner.width < 800:
    print('WARNING: low-resolution banner source; upload the original as app/src/main/assets/banner-original.jpg')
for density, size in {'mdpi':48,'hdpi':72,'xhdpi':96,'xxhdpi':144,'xxxhdpi':192}.items():
    folder = root / 'app/src/main/res' / ('mipmap-' + density)
    folder.mkdir(parents=True, exist_ok=True)
    icon = logo.resize((size*4,size*4),Image.Resampling.LANCZOS).convert('RGBA')
    mask = Image.new('L',icon.size,0)
    ImageDraw.Draw(mask).ellipse((0,0,size*4-1,size*4-1),fill=255)
    icon.putalpha(mask)
    icon = icon.resize((size,size),Image.Resampling.LANCZOS)
    icon.save(folder / 'ic_launcher.png')
    icon.save(folder / 'ic_launcher_round.png')
print('Brand assets prepared without resizing source images:', banner.size, logo.size)
