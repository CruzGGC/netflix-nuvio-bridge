# Netflix → Nuvio bridge

Make the **Netflix button** on your Google TV remote open **[Nuvio](https://github.com/NuvioMedia/NuvioTV)** instead of Netflix. No root.

It's a tiny Android app (about 12 KB) that uses Netflix's package name, `com.netflix.ninja`. When you press the button, it opens Nuvio and closes itself right away.

- **No permissions**, nothing runs in the background, no network access.
- **Hidden:** it doesn't appear in the apps list, and only the button opens it.
- Tested on the **Google TV Streamer 4K** (Android 14). It should work on other Google TV devices whose Netflix button works the same way (see [How it works](#how-it-works)).

> Not affiliated with Netflix, Google or Nuvio. Installing it **replaces the Netflix app** on that device.

## Install

You need a computer with [adb](https://developer.android.com/tools/releases/platform-tools) and Nuvio already installed on the TV.

1. **On the TV**, turn on developer mode and network debugging:
   - Settings → System → About → press **Android TV OS build** 7 times.
   - Settings → System → Developer options → turn on **Network debugging** (or **USB debugging**).
   - Note the TV's IP address (Settings → Network & Internet).
2. **Connect** from your computer and accept the prompt on the TV:
   ```sh
   adb connect <TV-IP>:5555
   ```
3. **Remove Netflix completely.** The bridge can't be installed while anything is registered under Netflix's package name, including a copy that was only "uninstalled for the user":
   ```sh
   adb shell pm uninstall com.netflix.ninja
   ```
4. **Install the bridge.** Download `netflix-nuvio-bridge.apk` from [Releases](../../releases), then:
   ```sh
   adb install netflix-nuvio-bridge.apk
   ```
5. **Press the Netflix button.** Nuvio should open.

To test without the remote:
```sh
adb shell am start -a com.netflix.action.NETFLIX_KEY_START -p com.netflix.ninja
```

### Undo

```sh
adb uninstall com.netflix.ninja
```
Then install Netflix from the Play Store again.

## Troubleshooting

| Problem | Fix |
|---|---|
| `INSTALL_FAILED_UPDATE_INCOMPATIBLE` | Something is still registered as `com.netflix.ninja`. Run step 3 again. If Netflix is a built-in **system** app on your device, it can't be replaced without root. |
| The button opens the Play Store | The bridge isn't installed. Check with `adb shell pm list packages com.netflix.ninja`. |
| "Nuvio is not installed" message | Install Nuvio (Android TV version, package `com.nuvio.app`). |
| The Play Store offers a Netflix "update" | Ignore it. It can't install over the bridge because the signatures differ. |

## How it works

On the Google TV Streamer, the Netflix button doesn't open Netflix like a normal app launch. The launcher sends a Netflix-specific action to whatever is installed as `com.netflix.ninja`:

```
act=com.netflix.action.NETFLIX_KEY_START pkg=com.netflix.ninja
```

The bridge's only activity listens for that action and opens Nuvio's TV launch screen. It has no `LAUNCHER`/`LEANBACK_LAUNCHER` entry, which is why it stays out of the apps list.

> The **YouTube** button is different: it does a normal TV launch of `com.google.android.youtube.tv`. So a YouTube bridge (for example [TizenTube Bridge](https://github.com/TobiPeterG/tizentube-bridge)) needs a visible launch entry and **can't** be hidden the same way.

## Open a different app

Change the package name in two places, then rebuild:

- `src/com/netflix/ninja/BridgeActivity.java`: `TARGET = "com.nuvio.app"`
- `AndroidManifest.xml`: `<package android:name="com.nuvio.app" />` inside `<queries>`

To find an app's package name: `adb shell pm list packages -3`

## Build from source

No Gradle. `build.sh` calls the Android build tools directly.

**You need:**
- **JDK 17+** (`javac`, `keytool`)
- **Python 3**
- **Android SDK command-line tools** with build-tools and the Android 14 platform:
  ```sh
  sdkmanager "build-tools;35.0.0" "platforms;android-34"
  ```
- **Bash**: Git Bash on Windows, or any shell on Linux/macOS.

**Build:**
```sh
export ANDROID_HOME=/path/to/Android/Sdk
./build.sh
```

The output is `netflix-nuvio-bridge.apk`.

On the first build, the script creates your own signing key (`bridge.keystore` plus `keystore-password.txt`). **Keep both.** Android only accepts updates signed with the same key, so if you lose them you'll have to uninstall and reinstall instead of updating. They're in `.gitignore`, so they never end up in the repo.

## Files

| File | What it is |
|---|---|
| `AndroidManifest.xml` | Package name, the `NETFLIX_KEY_START` filter, the Nuvio visibility query |
| `src/com/netflix/ninja/BridgeActivity.java` | Opens Nuvio, then closes |
| `make_banner.py` | Generates a plain placeholder banner at build time |
| `build.sh` | Compiles, packages, aligns and signs the APK |
