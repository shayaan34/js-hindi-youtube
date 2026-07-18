# DisplayVision 📺

**AI-powered digital signage mockup studio** for sales teams at digital
advertising companies. Visit a restaurant, coffee shop, office, mall or
retail store, photograph the space, and show the client exactly how LED
screens, digital menu boards, posters, vinyl stickers and banners will look
— *before* installation.

Built with **Flutter** (mobile, tablet & web) in a premium
**black / white / orange** Material 3 dark theme with glassmorphism cards
and smooth animations.

---

## ✨ Features

| Area | What it does |
|---|---|
| **Authentication** | Login, register, Google Sign-In (mock in demo mode, Firebase Auth when enabled) |
| **Client management** | Add/edit/delete clients — business name, contact, phone, email, category, address, notes, project status; instant search & status filters |
| **Client visits** | Capture photos with the camera or upload multiple images; all stored in the client profile |
| **AI wall detection** | Detects walls, windows, counters, entrances, pillars & display areas; suggests the best advertising locations; estimates perspective & room dimensions |
| **Digital screen placement** | Drag-and-drop virtual LED screens onto walls; resize (pinch or handle), rotate, perspective tilt; automatic shadows, screen glow, sheen & floor reflections |
| **Poster & sticker placement** | Posters, vinyl stickers, banners, standees, acrylic boards, roll-up banners, menu boards — with the same transform tools |
| **Animation preview** | Upload a GIF or Lottie JSON and it plays *inside* the virtual LED screen with realistic glow; built-in animated demo content; brightness slider |
| **AR preview** | Opens the phone camera, scans for a wall, tap to place a virtual display, walk around with parallax perspective tracking (ARCore/ARKit plugin-ready) |
| **Before & After** | Draggable slider comparison between the original photo and the mockup |
| **AI suggestions** | Best wall, best screen size (32"–75"), poster size, installation location, visibility score, customer-attention score, cost estimate |
| **Proposal generator** | Professional PDF: client details, mockup images, dimensions, quantities, pricing, GST, company logo & signature section |
| **Project gallery** | All mockups saved per client, folder filters, image export |
| **Sharing** | WhatsApp, email, native share sheet, PDF download |
| **Admin dashboard** | Total clients, projects, revenue, pending quotes, completed installations, animated pipeline chart |
| **Cloud & offline** | Offline-first with a visible cloud-sync queue; Firebase Firestore + Storage when enabled |
| **Day / Night preview** | One-tap relighting of the scene — screens glow brighter at night |

## 🚀 Getting started

The repo ships platform-agnostic source; generate the platform folders once:

```bash
cd displayvision
flutter create . --project-name displayvision   # generates android/ios/web/...
flutter pub get
flutter run                                     # or: flutter run -d chrome
```

The app runs **fully offline in demo mode** — mock login (any email +
6-char password, or the Google button), seeded sample clients, and a
deterministic on-device AI engine, so every workflow is demoable with zero
configuration.

### Permissions

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.INTERNET" />
```

And to `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Capture site photos and AR previews of advertising displays.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Upload site photos and advertising artwork.</string>
```

## 🔥 Enabling Firebase (production mode)

1. `dart pub global activate flutterfire_cli`
2. `flutterfire configure` — generates `lib/firebase_options.dart`
3. In `lib/core/app_config.dart` set `useFirebase = true`
4. Uncomment the `Firebase.initializeApp` block in `lib/main.dart`
5. Enable **Auth** (email/password + Google), **Firestore** and **Storage**
   in the Firebase console.

Data layout: `companies/{uid}/clients/{clientId}` documents, with photos and
mockups under `companies/{uid}/clients/{clientId}/...` in Storage. Multi-user
sales teams share a company workspace keyed by the account.

## 🤖 Real AI vision

Demo mode uses a deterministic heuristic engine (same photo → same result).
To connect a real model, pass an API key and wire the call in
`lib/services/ai_service.dart` (`_callVisionApi`):

```bash
flutter run --dart-define=AI_API_KEY=your_key
```

The prompt + JSON schema for **OpenAI Vision (gpt-4o)** or **Gemini Vision**
is documented in that file; responses map straight onto `AiAnalysis`.
For pixel-accurate plane detection, an OpenCV pipeline can be added on-device
(e.g. `opencv_dart`) feeding the same `DetectedZone` model.

## 🕶 Full AR

`ARPreviewScreen` ships a live-camera AR simulation (scan → tap-to-place →
walk-around parallax). To upgrade to true world tracking, add
`ar_flutter_plugin` (ARCore on Android / ARKit on iOS) and map the screen's
placement model (position / scale / tilt) onto an AR anchor.

## 🗂 Project structure

```
lib/
├── main.dart / app.dart        # bootstrap + routing shell
├── core/                       # config, theme, shared glass widgets
├── models/                     # clients, mockups, AI analysis, proposals
├── services/                   # auth, data (Firestore), AI vision, PDF
├── state/                      # AppState (provider ChangeNotifier)
└── screens/                    # login, dashboard, clients, editor, AR,
                                # before/after, suggestions, proposal,
                                # gallery, admin
```

## 🧭 Roadmap

- MP4 playback inside virtual screens (`video_player`) and video export
- OpenCV-based wall-plane segmentation + auto perspective snap
- AI-generated sales presentation deck
- Team roles & permissions, quote approval flow
