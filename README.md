# Senior Assist Flutter App

A cross-platform Flutter application designed specifically for senior users with accessibility-friendly features.

## Features

- **Large, High-Contrast UI**: All text and buttons are sized for easy visibility
- **Simple Interface**: Clean, uncluttered design with intuitive navigation
- **Voice Interaction**: Large microphone button for easy voice input
- **Typed Questions**: Optionally type questions instead of speaking
- **Optional Screenshot Attachment**: Attach a screenshot to help the AI answer questions about what’s on the screen
- **Cross-Platform**: Runs on both iOS and Android devices

## Recent Work (What Changed)

### Ask a Question Flow

- **Input method choice screen**: Added `InputMethodChoiceScreen` so users can choose:
  - Voice (microphone)
  - Typing (keyboard)
- **Voice-only question screen**: `QuestionScreen` simplified to focus on speaking.
- **Typed question screen**: Added `TypedQuestionScreen` with the same overall layout as the voice screen.

### Screenshot Vision (OpenAI)

- The app can now attach an optional screenshot to OpenAI Chat Completions using a multimodal user message:
  - `content: [{type: "text", ...}, {type: "image_url", image_url: {url: "data:<mime>;base64,..."}}]`
- **HEIC support** (common for iOS screenshots): the screenshot is converted/compressed to **JPEG** on-device using `flutter_image_compress` before being sent.
- **Graceful fallback**: if the screenshot can’t be converted or is too large, the request falls back to text-only (no crashes).
- **Debug logging** (debug builds only) was added so you can confirm whether the screenshot was actually attached:
  - `AIService: screenshot attach path=... supported=... original=... final=... mime=...`
  - `AIService: sending multimodal message (text + image_url)`
  - and other explicit logs for file missing / conversion failure / too-large fallbacks.

### UI: Scroll Reminder

- The “Scroll down to see more” pill was updated on both `QuestionScreen` and `TypedQuestionScreen` to avoid slight overflow at large accessibility text sizes by:
  - Constraining max width
  - Allowing the label to wrap up to 2 lines

### iOS: CocoaPods / Podfile.lock Sync

- If you see: “The sandbox is not in sync with the Podfile.lock”, it usually means iOS pods need to be reinstalled after plugin changes.
- Recommended reset flow:
  - `flutter clean`
  - `flutter pub get`
  - `cd ios && pod install`
- Xcode config was adjusted so the **Profile** configuration uses `Flutter/Profile.xcconfig`.

## Project Structure

```
lib/
├── main.dart              # App entry point and theme configuration
├── screens/
│   ├── home_screen.dart   # Main home screen
│   ├── input_method_choice_screen.dart
│   ├── question_screen.dart
│   └── typed_question_screen.dart
├── services/
│   └── ai_service.dart
└── widgets/
    └── microphone_button.dart  # Reusable microphone button widget
```

## Getting Started

### Prerequisites
- Flutter SDK (3.0.0 or higher)
- Android Studio or Xcode for device testing

### Installation

1. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```

2. Run on your preferred platform:
   ```bash
   # For Android
   flutter run

   # For iOS (macOS only)
   flutter run -d ios
   ```

## Code Overview

### Main Components

- **`main.dart`**: Configures the app theme with accessibility features like large fonts and high contrast colors
- **`HomeScreen`**: Contains the main UI with the app title and microphone button
- **`MicrophoneButton`**: A custom widget that provides visual feedback when tapped

### Accessibility Features

- **Large Text**: All text uses sizes 18px and above
- **High Contrast**: Dark text on light backgrounds
- **Large Touch Targets**: Buttons are minimum 80px tall
- **Visual Feedback**: Button changes color when active
- **Clear Instructions**: Simple, easy-to-read guidance text

## Current Functionality

- Ask a question by voice or typing
- Optionally attach a screenshot
- Receive step-by-step guidance

## Future Expansion

The code is organized to easily add:
- Real speech recognition
- Voice command processing
- Additional screens in `/lib/screens`
- More reusable widgets in `/lib/widgets`
