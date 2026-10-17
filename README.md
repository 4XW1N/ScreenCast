# ScreenCast - Android to iPad Screen Casting

A native screen casting solution that streams your Android phone screen to your iPad in real-time using WebRTC.

## Architecture

```
┌─────────────┐     WebSocket      ┌─────────────┐
│  Android    │ ◄────────────────► │  Signaling  │
│  (Sender)   │     Signaling      │  (Server)   │
└──────┬──────┘                    └──────┬──────┘
       │                                  │
       │ WebRTC Media Stream              │ WebRTC Media Stream
       ▼                                  ▼
┌─────────────┐                    ┌─────────────┐
│             │                    │   iPad      │
│             │                    │  (Receiver) │
└─────────────┘                    └─────────────┘
```

## Components

### 1. Android App (Kotlin) - `Android/`
- Uses `MediaProjection` API for screen capture
- WebRTC for video encoding (H.264) and streaming
- Foreground service for background capture

### 2. iPad App (Swift) - `iOS/`
- WebRTC for video decoding and rendering
- Metal-based video rendering via `RTCMTLVideoView`
- Auto-reconnection handling

### 3. Signaling Server (Node.js) - `server/`
- WebSocket server for WebRTC signaling (offer/answer/ICE)
- Pairs senders (Android) with receivers (iPad)
- Runs on port 8888 (WebSocket) and 8889 (health check)

## Prerequisites

### Android
- Android Studio Hedgehog+
- Android device with API 24+ (Android 7.0+)
- Physical device (emulator doesn't support MediaProjection well)

### iOS
- Xcode 15+
- iPad with iOS 15+
- Apple Developer account (for device testing)

### Server
- Node.js 18+
- Public IP or same Wi-Fi network

## Quick Start

### 1. Start the Signaling Server
```bash
cd server
npm install
npm start
# Server runs on ws://YOUR_IP:8888
```

### 2. Build Android App
```bash
cd Android
# Open in Android Studio and build/run
# Or: ./gradlew installDebug
```

### 3. Build iPad App
```bash
cd iOS
# Open Package.swift in Xcode 15+
# Resolve package dependencies (WebRTC)
# Build and run on iPad
```

### 4. Connect
1. Find your computer's IP: `ifconfig | grep inet` (macOS/Linux) or `ipconfig` (Windows)
2. On iPad app: Enter the IP and tap "Start Receiving"
3. On Android app: Enter the same IP, tap "Start Casting"
4. Grant screen capture permission on Android
5. Screen appears on iPad!

## Network Setup

### Same Wi-Fi (Easiest)
- Connect both devices to same Wi-Fi
- Use computer's local IP (e.g., `192.168.1.100`)

### Different Networks (Requires Port Forwarding)
1. Forward port 8888 on your router to the signaling server
2. Use your public IP
3. Or use a cloud VM (DigitalOcean, AWS, etc.)

### USB Tethering (No Wi-Fi)
1. Enable USB tethering on Android
2. Connect iPad via USB-C to USB adapter (or same Mac)
3. Use computer's IP on the tethered interface

## Configuration

### Android (`app/src/main/res/values/strings.xml`)
```xml
<string name="default_port">8888</string>
```

### iOS (ViewController.swift)
```swift
let port = 8888  // Default port
```

### Server (`server.js`)
```javascript
const PORT = process.env.PORT || 8888;
```

## Features

- ✅ Real-time screen mirroring (30fps target)
- ✅ Low latency (~100-200ms on LAN)
- ✅ H.264 hardware encoding on Android
- ✅ Metal-accelerated decoding on iPad
- ✅ Auto-reconnection on network changes
- ✅ Landscape/portrait orientation support
- ✅ Foreground service for background capture

## Troubleshooting

### "Waiting for receiver..." on Android
- Ensure iPad app is running and shows "Ready to receive"
- Check both devices can reach the signaling server IP
- Verify firewall allows port 8888

### Black screen on iPad
- Check WebRTC connection state in logs
- Verify Android granted screen capture permission
- Try restarting both apps

### High latency
- Use 5GHz Wi-Fi
- Reduce bitrate in `ScreenCaptureManager.kt` (default 8Mbps)
- Lower resolution in `MediaProjection` intent

### Audio not working
- Audio streaming requires additional implementation
- Android: Add `AudioRecord` + Opus encoding
- iOS: Add audio track to peer connection

## Project Structure

```
ScreenCast/
├── Android/                 # Kotlin Android app
│   ├── app/
│   │   ├── src/main/
│   │   │   ├── java/com/screencast/
│   │   │   │   ├── MainActivity.kt
│   │   │   │   ├── CaptureService.kt
│   │   │   │   ├── ScreenCaptureManager.kt
│   │   │   │   ├── PeerConnectionManager.kt
│   │   │   │   ├── SignalingClient.kt
│   │   │   │   └── SignalingMessage.kt
│   │   │   ├── res/
│   │   │   └── AndroidManifest.xml
│   │   └── build.gradle.kts
│   └── settings.gradle.kts
├── iOS/                     # Swift iPad app
│   ├── ScreenCast/
│   │   ├── AppDelegate.swift
│   │   ├── SceneDelegate.swift
│   │   ├── ViewController.swift
│   │   ├── Network/
│   │   │   ├── SignalingClient.swift
│   │   │   └── SignalingMessage.swift
│   │   ├── WebRTC/
│   │   │   └── WebRTCManager.swift
│   │   └── UI/
│   │       └── VideoRenderView.swift
│   ├── Package.swift
│   └── ScreenCast-Bridging-Header.h
├── server/                  # Node.js signaling server
│   ├── package.json
│   └── server.js
└── README.md
```

## CI/CD with GitHub Actions

### Unsigned IPA (for testing)
Automatically builds on every push to main/develop and on tags.

**Workflow:** `.github/workflows/build-ios.yml`

**Artifacts:** Download IPA from Actions → Artifacts

### Signed IPA (for TestFlight/App Store)
Requires code signing certificates. Manual trigger only.

**Workflow:** `.github/workflows/build-ios-signed.yml`

**Required Secrets:**
| Secret | Description |
|--------|-------------|
| `DEVELOPMENT_TEAM` | Your Apple Team ID (10 chars) |
| `APP_STORE_CONNECT_ISSUER_ID` | App Store Connect API Issuer ID |
| `APP_STORE_CONNECT_API_KEY_ID` | App Store Connect API Key ID |
| `APP_STORE_CONNECT_API_PRIVATE_KEY` | App Store Connect API Private Key (base64) |
| `BUNDLE_ID` | (Optional) Bundle identifier |
| `MATCH_GIT_URL` | (Optional) Git repo for fastlane match certificates |
| `MATCH_PASSWORD` | (Optional) Match encryption password |

**For manual certificates (without match):**
| Secret | Description |
|--------|-------------|
| `P12_CERTIFICATE` | Base64-encoded .p12 certificate |
| `P12_PASSWORD` | Certificate password |
| `PROVISIONING_PROFILE` | Base64-encoded .mobileprovision |
| `PROVISIONING_PROFILE_NAME` | Profile name in Xcode |

### Local Build (macOS)
```bash
cd iOS
./build_local.sh
# IPA at ./build/ipa/ScreenCast.ipa
```

### Generate Xcode Project (for Xcode IDE)
```bash
cd iOS
./generate_xcodeproj.sh
open ScreenCast.xcodeproj
```

## Contributing

PRs welcome! Areas for improvement:
- Audio support
- Touch input forwarding (iPad → Android)
- Recording capability
- Discovery via mDNS/Bonjour
- Multiple receiver support
