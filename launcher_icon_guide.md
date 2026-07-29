# PayUni Launcher Icon Generation Guide

## Official PayUni Logo Implementation

The launcher icon should use the official PayUni logo with the red geometric design.

### 1. Icon Design Specifications

**Colors:**
- PayUni Red: #E53E3E
- Text Color: #2D3748 (dark gray)
- Background: #FFFFFF (white)

**Geometric Shapes (based on official SVG):**
- Top left parallelogram: M0 15 L20 0 L35 0 L15 15 Z
- Top right triangle: M35 0 L50 15 L35 30 Z  
- Bottom left parallelogram: M0 15 L15 15 L35 30 L15 45 Z
- Center highlight triangle: M15 15 L35 0 L35 30 Z (white, 30% opacity)

**Typography:**
- Font: Arial, sans-serif
- Weight: Bold (900 for launcher icon)
- Text: "PAYUNI"

### 2. Required Icon Sizes

**Android:**
- 48x48 (mdpi)
- 72x72 (hdpi)
- 96x96 (xhdpi)
- 144x144 (xxhdpi)
- 192x192 (xxxhdpi)

**iOS:**
- 20x20, 29x29, 40x40, 60x60, 76x76, 83.5x83.5, 1024x1024
- Each with @1x, @2x, @3x variants

### 3. Generation Methods

**Option 1: Use Flutter Widget (Recommended)**
1. Run the app with PayUniLauncherIcon widget
2. Take screenshots at different sizes
3. Use image editing software to create final PNGs

**Option 2: Convert SVG to PNG**
1. Use the payuni_official_logo.svg as base
2. Export to PNG at required sizes using:
   - Adobe Illustrator
   - Inkscape (free)
   - Online converters like cloudconvert.com

**Option 3: Use flutter_launcher_icons Package**
1. Create a 1024x1024 PNG of the PayUni logo
2. Place it as assets/images/payuni_launcher_icon.png
3. Run: `flutter pub get`
4. Run: `flutter pub run flutter_launcher_icons:main`

### 4. Implementation Steps

1. Create the base PNG icon (1024x1024)
2. Run `flutter pub get` to install dependencies
3. Run `flutter pub run flutter_launcher_icons:main`
4. Verify icons in:
   - Android: android/app/src/main/res/mipmap-*/
   - iOS: ios/Runner/Assets.xcassets/AppIcon.appiconset/

### 5. Manual Installation (if automated fails)

Replace the default Flutter icons with PayUni icons in:
- Android: android/app/src/main/res/mipmap-*/ic_launcher.png
- iOS: ios/Runner/Assets.xcassets/AppIcon.appiconset/

### 6. Testing

After installation:
1. Clean build: `flutter clean`
2. Rebuild: `flutter build apk` or `flutter build ios`
3. Install on device to verify launcher icon appears correctly