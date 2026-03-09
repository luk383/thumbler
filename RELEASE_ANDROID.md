# Android Release — Play Console (WAJE)

## Prerequisites

- Flutter SDK installed and on `$PATH`
- Java / `keytool` available (`keytool -version` should work)
- A Google Play Console project with app ID `com.waje.app`

---

## Step 1 — Generate an upload keystore

Run once. Store the keystore **outside** the repo (or in a secrets manager).

```bash
keytool -genkey -v \
  -keystore ~/keys/waje-upload.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias upload \
  -dname "CN=WAJE, OU=Mobile, O=WAJE, L=Milan, ST=MI, C=IT"
```

You will be prompted to set **store password** and **key password**. Keep them safe.

---

## Step 2 — Create `android/key.properties`

Copy the example file and fill in real values:

```bash
cp android/key.properties.example android/key.properties
```

Edit `android/key.properties`:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=../../keys/waje-upload.jks
```

> `storeFile` is resolved relative to `android/app/`, so `../../keys/waje-upload.jks`
> points to `~/keys/waje-upload.jks` if you place the keystore there.
> Adjust the path to wherever you stored the `.jks` file.

`android/key.properties` is listed in `.gitignore` and will never be committed.

---

## Step 3 — Build the release AAB (Play Console)

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

Upload this file to Play Console → Internal testing (or any track).

---

## Step 4 — (Optional) Build a release APK

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

Useful for direct device installation or Firebase App Distribution.
For split APKs by ABI:

```bash
flutter build apk --split-per-abi --release
```

Outputs:
- `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`
- `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk`
- `build/app/outputs/flutter-apk/app-x86_64-release.apk`

---

## Versioning

Version is controlled entirely from `pubspec.yaml`:

```yaml
version: 0.1.0+1
#        ^^^^^  versionName  (shown to users)
#              ^ versionCode (integer, must increment each Play Console upload)
```

Bump `versionCode` (the `+N` part) before every upload to Play Console.

---

## CI/CD notes

Store `key.properties` content and the `.jks` file as **encrypted secrets**
(GitHub Actions secrets, Fastlane environment variables, etc.).
Never print or log these values in CI output.
