#!/usr/bin/env bash
# Builds netflix-nuvio-bridge.apk with the Android SDK command-line tools (no Gradle).
# Works in Git Bash on Windows, and on Linux/macOS.
# The signing key (bridge.keystore) must be kept: updates must be signed with the same key.
set -euo pipefail
cd "$(dirname "$0")"

SDK="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
[ -n "$SDK" ] && [ -d "$SDK" ] || { echo "Set ANDROID_HOME to your Android SDK folder" >&2; exit 1; }
BT="$(ls -d "$SDK"/build-tools/* | sort -V | tail -1)"
JAR="$SDK/platforms/android-34/android.jar"
[ -f "$JAR" ] || { echo "Missing $JAR: install it with: sdkmanager \"platforms;android-34\"" >&2; exit 1; }
PY="$(command -v python3 || command -v python)"

# Windows ships .exe/.bat wrappers; other platforms ship plain binaries/scripts.
if [ -f "$BT/aapt2.exe" ]; then
  win() { cygpath -w "$1"; }
  AAPT2="$BT/aapt2.exe"; ZIPALIGN="$BT/zipalign.exe"
  d8() { cmd //c "$(win "$BT/d8.bat")" "$@"; }
  apksigner() { cmd //c "$(win "$BT/apksigner.bat")" "$@"; }
else
  win() { echo "$1"; }
  AAPT2="$BT/aapt2"; ZIPALIGN="$BT/zipalign"
  d8() { "$BT/d8" "$@"; }
  apksigner() { "$BT/apksigner" "$@"; }
fi

OUT=build
rm -rf "$OUT" && mkdir -p "$OUT/classes" "$OUT/dex"

"$PY" -I make_banner.py
"$AAPT2" compile --dir res -o "$OUT/res.zip"
"$AAPT2" link -I "$JAR" --manifest AndroidManifest.xml -o "$OUT/unsigned.apk" "$OUT/res.zip"

javac -source 11 -target 11 -Xlint:-options -classpath "$JAR" -d "$OUT/classes" $(find src -name '*.java')
classes=(); while IFS= read -r f; do classes+=("$(win "$f")"); done < <(find "$OUT/classes" -name '*.class')
d8 --release --min-api 23 --lib "$(win "$JAR")" --output "$(win "$OUT/dex")" "${classes[@]}"
"$PY" -I -c "import zipfile,sys; zipfile.ZipFile(sys.argv[1],'a',zipfile.ZIP_DEFLATED).write(sys.argv[2],'classes.dex')" "$OUT/unsigned.apk" "$OUT/dex/classes.dex"

"$ZIPALIGN" -f -p 4 "$OUT/unsigned.apk" "$OUT/aligned.apk"

if [ ! -f bridge.keystore ]; then
  # First build: create your own signing key. The random password is saved next to it.
  "$PY" -I -c "import secrets; print(secrets.token_urlsafe(18))" > keystore-password.txt
  keytool -genkeypair -keystore bridge.keystore -alias bridge -keyalg RSA -keysize 3072 -validity 10000 \
    -storepass "$(cat keystore-password.txt)" -dname "CN=Netflix Nuvio Bridge" >/dev/null 2>&1
fi
PASS="$(cat keystore-password.txt)"
apksigner sign --ks "$(win "$PWD/bridge.keystore")" --ks-pass "pass:$PASS" \
  --out "$(win "$PWD/netflix-nuvio-bridge.apk")" "$(win "$PWD/$OUT/aligned.apk")"
apksigner verify --print-certs "$(win "$PWD/netflix-nuvio-bridge.apk")"
echo "built: $PWD/netflix-nuvio-bridge.apk"
