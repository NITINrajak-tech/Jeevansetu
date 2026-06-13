# JeevanSetu — Flutter MVP Implementation Plan

## Overview

Build a **hackathon-ready Flutter mobile app** for a smart accident detection system. The app demonstrates the full flow: **Accident → Detection → SOS → Tracking → Hospital Recommendation**. No backend — all data is mocked.

## Environment Note

> [!IMPORTANT]
> Flutter SDK is installed at `C:\src\flutter\flutter\bin` but the sandboxed terminal cannot execute it. I will **manually create all project files** (pubspec.yaml, Dart source files, configs) so you can run `flutter pub get` and `flutter run` from your own terminal or VS Code.

---

## Architecture

```
d:\jeevansetu\jeevansetu_app\
├── pubspec.yaml
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── core/
│   │   ├── theme/
│   │   │   ├── app_theme.dart          # Material 3 light + dark themes
│   │   │   ├── app_colors.dart         # Color palette
│   │   │   └── app_text_styles.dart    # Typography
│   │   ├── router/
│   │   │   └── app_router.dart         # GoRouter config
│   │   ├── constants/
│   │   │   └── app_constants.dart
│   │   └── widgets/                    # Shared widgets
│   │       ├── gradient_card.dart
│   │       ├── sos_button.dart
│   │       └── status_badge.dart
│   ├── features/
│   │   ├── auth/
│   │   │   ├── presentation/
│   │   │   │   ├── screens/
│   │   │   │   │   ├── splash_screen.dart
│   │   │   │   │   ├── login_screen.dart
│   │   │   │   │   ├── signup_screen.dart
│   │   │   │   │   └── permissions_screen.dart
│   │   │   │   └── widgets/
│   │   │   │       └── otp_input_field.dart
│   │   │   └── providers/
│   │   │       └── auth_provider.dart
│   │   ├── home/
│   │   │   ├── presentation/
│   │   │   │   ├── screens/
│   │   │   │   │   └── home_screen.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── monitoring_status_card.dart
│   │   │   │       ├── location_preview_card.dart
│   │   │   │       └── recent_activity_card.dart
│   │   │   └── providers/
│   │   │       └── home_provider.dart
│   │   ├── emergency/
│   │   │   ├── presentation/
│   │   │   │   ├── screens/
│   │   │   │   │   ├── accident_alert_screen.dart
│   │   │   │   │   ├── severity_result_screen.dart
│   │   │   │   │   └── emergency_contacts_screen.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── countdown_timer.dart
│   │   │   │       └── severity_gauge.dart
│   │   │   └── providers/
│   │   │       └── emergency_provider.dart
│   │   ├── tracking/
│   │   │   ├── presentation/
│   │   │   │   ├── screens/
│   │   │   │   │   └── live_tracking_screen.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── map_placeholder.dart
│   │   │   │       └── tracking_bottom_sheet.dart
│   │   │   └── providers/
│   │   │       └── tracking_provider.dart
│   │   ├── hospital/
│   │   │   ├── presentation/
│   │   │   │   ├── screens/
│   │   │   │   │   └── hospital_recommendation_screen.dart
│   │   │   │   └── widgets/
│   │   │   │       └── hospital_card.dart
│   │   │   └── providers/
│   │   │       └── hospital_provider.dart
│   │   └── profile/
│   │       ├── presentation/
│   │       │   ├── screens/
│   │       │   │   └── profile_screen.dart
│   │       │   └── widgets/
│   │       └── providers/
│   │           └── profile_provider.dart
│   └── data/
│       ├── models/
│       │   ├── user_model.dart
│       │   ├── contact_model.dart
│       │   ├── hospital_model.dart
│       │   └── activity_model.dart
│       └── mock/
│           └── mock_data.dart
├── android/                            # Standard Flutter Android config
├── ios/                                # Standard Flutter iOS config
└── test/
```

---

## Proposed Changes

### Phase 1: Project Scaffold & Core

#### [NEW] pubspec.yaml
- Flutter SDK, dependencies: `flutter_riverpod`, `go_router`, `google_fonts`, `animate_do`, `flutter_animate`, `percent_indicator`, `shimmer`
- Dev dependencies: `flutter_lints`

#### [NEW] lib/main.dart
- Entry point, `ProviderScope` wrapper

#### [NEW] lib/app.dart
- `MaterialApp.router` with GoRouter, theme switching

#### [NEW] lib/core/theme/app_colors.dart
- Curated color palette: deep navy, vibrant red (SOS), emerald green (safe), amber (warning)
- Both light and dark variants

#### [NEW] lib/core/theme/app_theme.dart
- Material 3 `ThemeData` for light and dark modes
- Custom color scheme, card themes, button themes, input decoration themes

#### [NEW] lib/core/theme/app_text_styles.dart
- Typography scale using Google Fonts (Inter / Outfit)

#### [NEW] lib/core/router/app_router.dart
- GoRouter with all routes, redirect logic for auth state
- Routes: `/splash`, `/login`, `/signup`, `/permissions`, `/home`, `/accident-alert`, `/severity`, `/tracking`, `/hospitals`, `/contacts`, `/profile`

#### [NEW] lib/core/widgets/
- `gradient_card.dart` — Reusable glassmorphism card
- `sos_button.dart` — Large animated emergency button
- `status_badge.dart` — Color-coded status indicator

---

### Phase 2: Data Models & Mock Services

#### [NEW] lib/data/models/
- `user_model.dart` — name, phone, avatar, monitoring status
- `contact_model.dart` — name, phone, relationship, priority
- `hospital_model.dart` — name, distance, ETA, trauma level, coordinates
- `activity_model.dart` — type, timestamp, description

#### [NEW] lib/data/mock/mock_data.dart
- Fake users, contacts, hospitals, recent activities
- Simulated accident detection trigger
- Simulated severity scores

---

### Phase 3: Authentication Feature

#### [NEW] Splash Screen
- App logo with fade-in animation, auto-navigate to login after 2.5s

#### [NEW] Login Screen
- Phone number input with country code
- OTP input (4/6 digit boxes)
- Gradient background, modern card UI

#### [NEW] Signup Screen
- Name, phone, emergency contact fields
- Clean form layout

#### [NEW] Permissions Screen
- Cards for GPS, Sensors, Notifications with toggle/allow buttons
- Progress indicator, "Continue" CTA

#### [NEW] Auth Provider
- Riverpod `StateNotifier` for auth state (logged in/out, user data)

---

### Phase 4: Home & Emergency Features

#### [NEW] Home Dashboard
- Welcome greeting with user name
- "Monitoring Active" animated status card (pulsing green dot)
- Location preview card (static map placeholder with gradient overlay)
- Big red SOS button (animated, pulsing shadow)
- Recent activity list

#### [NEW] Accident Alert Screen
- Fullscreen red/orange gradient alert
- Large "⚠ Accident Detected" text
- 15-second animated circular countdown timer
- Two buttons: "I am Safe" (green) / "Send SOS" (red)
- Urgent pulsing animation, vibration-feel UI

#### [NEW] Severity Result Screen
- Circular gauge showing risk score (0–100)
- Color-coded: Red (Critical ≥70), Yellow (Moderate 40–69), Green (Safe <40)
- Severity label with icon
- "View Hospitals" CTA

#### [NEW] Emergency Contacts Screen
- Contact cards with avatar, name, phone, priority tag
- Add/Edit/Delete contacts
- FAB for adding new contact
- Swipe-to-delete

#### [NEW] Emergency Provider
- Countdown state, severity result state, contact list state

---

### Phase 5: Tracking & Hospital Features

#### [NEW] Live Tracking Screen
- Fullscreen map placeholder (styled container with grid/dots pattern)
- Simulated location marker (animated pin)
- Route path visualization (dashed line)
- "Help on the way" status badge (animated)
- Draggable bottom sheet with: ETA, selected hospital, contacted emergency contacts

#### [NEW] Hospital Recommendation Screen
- List of hospital cards showing: name, ETA, distance, trauma level badge
- "Best Choice" highlighted card with glow effect
- "Navigate" CTA button per card
- Sort/filter chips

#### [NEW] Tracking & Hospital Providers
- Location state, tracking status, hospital list state

---

### Phase 6: Profile & Settings

#### [NEW] Profile Screen
- User avatar and info section
- Monitoring ON/OFF toggle with animated switch
- Language selection dropdown
- Emergency preferences section
- App version info

---

## UI/UX Design Principles

| Aspect | Implementation |
|--------|---------------|
| **Colors** | Deep navy (#0A1628), SOS Red (#FF2D55), Safe Green (#34C759), Warning Amber (#FF9500) |
| **Typography** | Google Fonts — Inter for body, Outfit for headings |
| **Cards** | Glassmorphism with subtle blur, rounded corners (16px), gradient borders |
| **Animations** | Pulsing SOS button, countdown timer, fade-in transitions, slide-up sheets |
| **Shadows** | Layered box shadows for depth, colored shadows for emphasis |
| **Dark Mode** | True dark (#0A0E1A) backgrounds, elevated surfaces with subtle borders |

---

## Verification Plan

### Manual Verification
1. After all files are created, you'll run in your terminal:
   ```
   cd d:\jeevansetu\jeevansetu_app
   flutter pub get
   flutter run
   ```
2. Navigate through all screens to verify UI rendering
3. Test the accident detection flow: Home → SOS → Alert → Countdown → Severity → Hospital
4. Verify dark/light theme toggle
5. Verify animations (countdown timer, pulsing SOS button)

### Code Quality
- I will use the Dart MCP `analyze_files` tool to check for compile errors after writing all files

---

## Open Questions

> [!IMPORTANT]
> **Flutter project creation**: Since I can't run `flutter create` from the sandbox, I will manually write all project files including `pubspec.yaml`, the `android/` and `ios/` scaffolding, and all Dart source. You'll need to run `flutter pub get` once from your terminal. **Is this approach acceptable?**

> [!NOTE]
> **Alternative**: If you prefer, you can run `flutter create jeevansetu_app` in `d:\jeevansetu\` yourself, and then I'll just write the `lib/` source files and update `pubspec.yaml`. This would be simpler. **Which do you prefer?**
