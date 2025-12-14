# Senior Assist Flutter App

A cross-platform Flutter application designed specifically for senior users with accessibility-friendly features.

## Features

- **Large, High-Contrast UI**: All text and buttons are sized for easy visibility
- **Simple Interface**: Clean, uncluttered design with intuitive navigation
- **Voice Interaction**: Large microphone button for easy voice input
- **Cross-Platform**: Runs on both iOS and Android devices
 - **Local Medicine Reminders**: On-device notifications to remind users when to take their medicines

## Project Structure

```
lib/
├── main.dart              # App entry point and theme configuration
├── screens/
│   └── home_screen.dart   # Main home screen with title and microphone
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

- Tap the microphone button to activate "listening" mode
- Visual feedback shows "Listening..." text
- Auto-stops after 3 seconds (placeholder behavior)
- Add, edit, and delete medicines stored locally on the device
- Pick exact reminder times for each medicine and receive daily local notifications at those times

## Future Expansion

The code is organized to easily add:
- Real speech recognition
- Voice command processing
- Additional screens in `/lib/screens`
- More reusable widgets in `/lib/widgets`
