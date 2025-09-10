import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage accessibility settings and user preferences
/// Handles text size, contrast settings, and audio preferences
class AccessibilityService extends ChangeNotifier {
  static final AccessibilityService _instance = AccessibilityService._internal();
  factory AccessibilityService() => _instance;
  AccessibilityService._internal();

  // Default values
  double _textSizeMultiplier = 1.0;
  bool _highContrast = false;
  bool _colorBlindFriendly = false;
  bool _audioPlayback = true;
  bool _hasCompletedOnboarding = false;
  bool _hasCompletedAccessibilitySetup = false;
  SharedPreferences? _prefs;

  // Getters
  double get textSizeMultiplier => _textSizeMultiplier;
  bool get highContrast => _highContrast;
  bool get colorBlindFriendly => _colorBlindFriendly;
  bool get audioPlayback => _audioPlayback;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  bool get hasCompletedAccessibilitySetup => _hasCompletedAccessibilitySetup;

  /// Reset accessibility setup (for testing or re-setup)
  Future<void> resetAccessibilitySetup() async {
    _hasCompletedAccessibilitySetup = false;
    await _prefs?.setBool(_accessibilitySetupKey, false);
    notifyListeners();
  }

  // Keys for SharedPreferences
  static const String _textSizeKey = 'text_size_multiplier';
  static const String _highContrastKey = 'high_contrast';
  static const String _colorBlindKey = 'color_blind_friendly';
  static const String _audioPlaybackKey = 'audio_playback';
  static const String _onboardingKey = 'completed_onboarding';
  static const String _accessibilitySetupKey = 'completed_accessibility_setup';

  /// Initialize the service and load saved preferences
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    
    _textSizeMultiplier = prefs.getDouble(_textSizeKey) ?? 1.0;
    _highContrast = prefs.getBool(_highContrastKey) ?? false;
    _colorBlindFriendly = prefs.getBool(_colorBlindKey) ?? false;
    _audioPlayback = prefs.getBool(_audioPlaybackKey) ?? true;
    _hasCompletedOnboarding = prefs.getBool(_onboardingKey) ?? false;
    _hasCompletedAccessibilitySetup = prefs.getBool(_accessibilitySetupKey) ?? false;
    
    notifyListeners();
  }

  /// Set text size multiplier (0.8 = small, 1.0 = normal, 1.2 = large, 1.5 = extra large)
  Future<void> setTextSizeMultiplier(double multiplier) async {
    _textSizeMultiplier = multiplier;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_textSizeKey, multiplier);
    notifyListeners();
  }

  /// Toggle high contrast mode
  Future<void> setHighContrast(bool enabled) async {
    _highContrast = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_highContrastKey, enabled);
    notifyListeners();
  }

  /// Toggle color blind friendly mode
  Future<void> setColorBlindFriendly(bool enabled) async {
    _colorBlindFriendly = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_colorBlindKey, enabled);
    notifyListeners();
  }

  /// Toggle audio playback
  Future<void> setAudioPlayback(bool enabled) async {
    _audioPlayback = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_audioPlaybackKey, enabled);
    notifyListeners();
  }

  /// Mark onboarding as completed
  Future<void> completeOnboarding() async {
    _hasCompletedOnboarding = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
    notifyListeners();
  }

  /// Mark accessibility setup as completed
  Future<void> completeAccessibilitySetup() async {
    _hasCompletedAccessibilitySetup = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_accessibilitySetupKey, true);
    notifyListeners();
  }

  /// Reset onboarding status (for testing or help replay)
  Future<void> resetOnboarding() async {
    _hasCompletedOnboarding = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, false);
    notifyListeners();
  }

  /// Get theme colors based on accessibility settings
  ColorScheme getColorScheme(Brightness brightness) {
    if (_colorBlindFriendly) {
      // Use color blind friendly palette
      return ColorScheme.fromSeed(
        seedColor: const Color(0xFF2E7D32), // Green that works for most color blindness
        brightness: brightness,
      ).copyWith(
        primary: _highContrast ? Colors.black : const Color(0xFF2E7D32),
        onPrimary: _highContrast ? Colors.white : Colors.white,
        surface: _highContrast ? Colors.white : Colors.grey.shade50,
        onSurface: _highContrast ? Colors.black : Colors.black87,
        secondary: const Color(0xFF1976D2), // Blue that works for color blindness
      );
    } else if (_highContrast) {
      // High contrast black and white
      return ColorScheme.fromSeed(
        seedColor: Colors.black,
        brightness: brightness,
      ).copyWith(
        primary: Colors.black,
        onPrimary: Colors.white,
        surface: Colors.white,
        onSurface: Colors.black,
        secondary: Colors.grey.shade800,
      );
    } else {
      // Default theme
      return ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: brightness,
      ).copyWith(
        primary: Colors.blue.shade700,
        onPrimary: Colors.white,
        surface: Colors.white,
        onSurface: Colors.black87,
      );
    }
  }

  /// Get text theme with accessibility adjustments
  TextTheme getTextTheme() {
    return TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32 * _textSizeMultiplier,
        fontWeight: FontWeight.bold,
        color: _highContrast ? Colors.black : Colors.black87,
      ),
      headlineMedium: TextStyle(
        fontSize: 28 * _textSizeMultiplier,
        fontWeight: FontWeight.bold,
        color: _highContrast ? Colors.black : Colors.black87,
      ),
      bodyLarge: TextStyle(
        fontSize: 20 * _textSizeMultiplier,
        color: _highContrast ? Colors.black : Colors.black87,
      ),
      bodyMedium: TextStyle(
        fontSize: 18 * _textSizeMultiplier,
        color: _highContrast ? Colors.black : Colors.black87,
      ),
      labelLarge: TextStyle(
        fontSize: 16 * _textSizeMultiplier,
        fontWeight: FontWeight.w500,
        color: _highContrast ? Colors.black : Colors.black87,
      ),
    );
  }
}
