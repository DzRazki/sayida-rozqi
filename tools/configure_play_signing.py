import base64
import os
from pathlib import Path

path = Path('android/app/build.gradle.kts')
if not path.exists():
    raise SystemExit('Expected generated Kotlin Gradle configuration; refusing an unsafe signing change.')
text = path.read_text()
old = 'signingConfig = signingConfigs.getByName("debug")'
if text.count(old) != 1 or text.count('    buildTypes {') != 1:
    raise SystemExit('Unexpected Gradle layout; no changes made.')
key = Path(os.environ['RUNNER_TEMP']) / 'sayida-play-upload.jks'
key.write_bytes(base64.b64decode(os.environ['ANDROID_KEYSTORE_BASE64'], validate=True))
key.chmod(0o600)
os.environ['PLAY_UPLOAD_KEYSTORE'] = str(key)
with open(os.environ['GITHUB_ENV'], 'a') as env:
    env.write(f'PLAY_UPLOAD_KEYSTORE={key}\n')
config = '''    signingConfigs {
        create("playUpload") {
            storeFile = file(System.getenv("PLAY_UPLOAD_KEYSTORE"))
            storePassword = System.getenv("ANDROID_KEYSTORE_PASSWORD")
            keyAlias = System.getenv("ANDROID_KEY_ALIAS")
            keyPassword = System.getenv("ANDROID_KEY_PASSWORD")
        }
    }

'''
text = text.replace('    buildTypes {', config + '    buildTypes {', 1)
text = text.replace(old, 'signingConfig = signingConfigs.getByName("playUpload")', 1)
path.write_text(text)
