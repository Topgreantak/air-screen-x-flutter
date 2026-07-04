# iDisplay — iOS Client

Flutter + native Swift app that makes an iPad/iPhone act as a **wireless secondary display** for a Windows PC over the local network. It receives an H.264 stream, decodes it with VideoToolbox, renders with Metal (letterboxed, never stretched), and sends touches back as input.

Pairs with the [iDisplay Windows host](../windows-host). The iOS app **initiates** the connection; the Windows PC must **approve** it. **LAN-only**, no App Store — installed via sideload.

---

## Features

- Low-latency H.264 receive + VideoToolbox decode + Metal render.
- Aspect-correct display: letterbox / pillarbox, never stretch.
- Touches mapped to the content area → UDP input to Windows.
- **Energy saving**: the display pauses when the stream is static and wakes on activity (idle-stop).
- Minimal settings — everything else is controlled on the Windows host.

---

## Settings scope

Per design, **display settings live on the Windows host**. The iOS app exposes only:

- **Host IP** — the Windows PC's LAN address.
- **FPS** — preferred frame rate (the host may clamp).
- **Letterbox** — keep aspect ratio (recommended).

Mode (mirror/extend), aspect ratio and resolution are set on the Windows app.

---

## Requirements

| Tool | Version | Notes |
|------|---------|-------|
| Flutter | 3.44+ | Dart 3.12+ |
| Dart-side dev | any OS | `flutter pub get`, `flutter test`, `flutter analyze` run on Windows/macOS/Linux |
| **iOS build** | **macOS + Xcode 16+** | required to compile the Swift layer and produce an IPA |
| CocoaPods | latest | iOS native deps |

> The Swift native layer (`ios/Runner/NativeDisplay/`) and the IPA can only be built on **macOS** (or CI). On Windows you can still develop and test the Dart side.

---

## Build & test (any OS — Dart side)

```bash
# from ios-client/
flutter pub get
flutter analyze          # → No issues found
flutter test             # → all tests pass
```

## Build for iOS (macOS only)

```bash
flutter pub get
cd ios && pod install && cd ..

# Development build (no code signing) → for sideloading
flutter build ios --release --no-codesign

# Package the .app into a sideloadable .ipa
cd build/ios/iphoneos
mkdir Payload
cp -r Runner.app Payload/
zip -r iDisplay.ipa Payload/
rm -rf Payload
```

> The Xcode project (`ios/Runner.xcodeproj`), `Podfile`, and `GeneratedPluginRegistrant` are produced by `flutter create` / `pod install` on macOS and are intentionally not committed.

### CI (cloud macOS)

Build the IPA on a `macos-14` GitHub Actions runner with `subosito/flutter-action@v2` (Flutter 3.44.4), then `flutter build ios --release --no-codesign` and upload the artifact. See the host repo's spec for a sample workflow.

---

## Install (sideload — no App Store)

Use one of:

- **AltStore** — add the `.ipa` via AltServer.
- **Sideloadly** — drag the `.ipa`, sign with your Apple ID.
- **Apple Developer / Enterprise** — sign in Xcode and export.

Trust the developer profile on the device (Settings → General → VPN & Device Management) after install.

---

## Usage

1. Launch the Windows host (it sits in the tray).
2. On iOS, open **Settings**, enter the Windows PC's **LAN IP**, pick FPS / letterbox.
3. Back on the home screen, press **Connect**.
4. **Approve** the request on the Windows PC (Accept). The screen appears; tap to control.

---

## Project layout

```
ios-client/
├── pubspec.yaml            # deps (provider, shared_preferences, cupertino_icons)
├── analysis_options.yaml   # flutter_lints
├── lib/                    # Flutter / Dart
│   ├── main.dart, app.dart
│   ├── models/             # prefs, stream info, connection state
│   ├── services/           # config persist, platform channel, connection controller
│   ├── screens/            # home, settings (FPS + display only)
│   ├── widgets/            # connection badge, display surface
│   └── utils/              # resolution/letterbox math
├── test/                   # Dart unit tests
└── ios/Runner/
    ├── AppDelegate.swift
    └── NativeDisplay/      # Swift: CtrlClient, StreamClient, InputTransmitter,
                            #        VideoDecoder, MetalRenderer, Shaders.metal,
                            #        TouchHandler, DisplaySession, MetalViewFactory, DisplayPlugin
```

---

## Status

- ✅ Dart side: unit tests pass, `flutter analyze` clean.
- ⚠️ Swift native layer: written, **not yet built** — requires a macOS/Xcode build to compile and verify decode → render → touch end-to-end.
- Distribution: sideload only (no App Store signing).
