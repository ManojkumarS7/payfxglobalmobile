# PayUni - Manual Android Launcher Icon Setup

**Status:** Plugin-free, direct Android resource management ✅

## Overview
Launcher icons are now set up manually without the flutter_launcher_icons plugin. All icon files go directly into Android resource folders.

## Android Folder Structure

```
android/app/src/main/res/
├── mipmap-ldpi/          → 36x36px
├── mipmap-mdpi/          → 48x48px
├── mipmap-hdpi/          → 72x72px
├── mipmap-xhdpi/         → 96x96px
├── mipmap-xxhdpi/        → 144x144px
├── mipmap-xxxhdpi/       → 192x192px
└── mipmap-anydpi-v26/    → Adaptive icon XML (Android 8.0+)
```

## Setup Steps

### Step 1: Generate Icon Files

**Option A: Online Generator** (Recommended)
- Visit: https://romannurik.github.io/AndroidAssetStudio/
- Upload your icon (1024x1024 PNG recommended)
- Download the generated icon set

**Option B: Android Studio Image Asset**
1. Open Android Studio
2. Go to: `File → New → Image Asset`
3. Select your base icon (192x192 minimum)
4. Choose "Legacy only"
5. Android Studio generates all sizes automatically

**Option C: Manual Scaling**
- Start with a 192x192 PNG
- Scale to: 36x36, 48x48, 72x72, 96x96, 144x144, 192x192

### Step 2: Place Icons in Folders

Example with icon name `ic_launcher.png`:

```
android/app/src/main/res/
├── mipmap-ldpi/ic_launcher.png         (36x36)
├── mipmap-mdpi/ic_launcher.png         (48x48)
├── mipmap-hdpi/ic_launcher.png         (72x72)
├── mipmap-xhdpi/ic_launcher.png        (96x96)
├── mipmap-xxhdpi/ic_launcher.png       (144x144)
└── mipmap-xxxhdpi/ic_launcher.png      (192x192)
```

### Step 3: Update AndroidManifest.xml

Location: `android/app/src/main/AndroidManifest.xml`

Find the `<application>` tag and verify:

```xml
<application
    android:label="@string/app_name"
    android:icon="@mipmap/ic_launcher"
    android:roundIcon="@mipmap/ic_launcher"
    android:debuggable="false"
    android:usesCleartextTraffic="false">
```

**Note:** Replace `ic_launcher` with your icon name if different.

### Step 4: Create Adaptive Icon (Android 8.0+)

Create: `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
```

### Step 5: Create Background Color

Create/Update: `android/app/src/main/res/values/colors.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#FFFFFF</color>
</resources>
```

## Icon Size Reference

| DPI Category | Multiplier | Size    |
|-------------|-----------|---------|
| ldpi        | 0.75x     | 36x36   |
| mdpi        | 1x        | 48x48   |
| hdpi        | 1.5x      | 72x72   |
| xhdpi       | 2x        | 96x96   |
| xxhdpi      | 3x        | 144x144 |
| xxxhdpi     | 4x        | 192x192 |

## Build & Test

```bash
flutter pub get
flutter clean
flutter build apk
```

Then check the app launcher - your icon should appear!

## Troubleshooting

**Icon still shows default?**
- Verify icon name matches in AndroidManifest.xml
- Check all mipmap folders have the file
- Run `flutter clean` before rebuilding

**Icon appears blurry?**
- Ensure correct size for each DPI folder
- Don't scale same image into different folders
- Start with high-resolution source

**Adaptive icon not working?**
- Verify `mipmap-anydpi-v26/ic_launcher.xml` exists
- Check `colors.xml` has `ic_launcher_background` color
- Test on Android 8.0+ device

## Benefits of Manual Setup

✅ No external plugin dependencies
✅ Full control over icon resources
✅ Faster build times
✅ Works directly with Android toolchain
✅ Easy to update icons anytime

## Current Status
- ✅ flutter_launcher_icons package added
- ✅ Configuration added to pubspec.yaml
- ✅ Icon generator widget created
- ❌ Need to create the actual PNG file (assets/images/payuni_launcher_icon.png)

## Alternative: Manual Icon Replacement
If automatic generation doesn't work, manually replace icons in:
- `android/app/src/main/res/mipmap-*/ic_launcher.png`
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/`