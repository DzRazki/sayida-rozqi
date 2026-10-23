import base64, io, json
from pathlib import Path
from PIL import Image, ImageDraw
root = Path(__file__).resolve().parents[1]
data = json.loads((root / 'tools/brand-images.json').read_text())
assets = root / 'app/src/main/assets'
assets.mkdir(parents=True, exist_ok=True)
banner = Image.open(io.BytesIO(base64.b64decode(data['banner_webp']))).convert('RGB')
banner.save(assets / 'banner.jpg', quality=95)
logo = Image.open(io.BytesIO(base64.b64decode(data['logo_webp']))).convert('RGB')
logo.save(assets / 'logo.png')
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
print('Brand assets prepared:', banner.size, logo.size)
