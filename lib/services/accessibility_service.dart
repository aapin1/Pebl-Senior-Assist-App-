import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage accessibility settings and user preferences
/// Handles text size, contrast settings, and audio preferences
class AccessibilityService extends ChangeNotifier {
  static final AccessibilityService _instance = AccessibilityService._internal();
  factory AccessibilityService() => _instance;
  AccessibilityService._internal();

  // Default values
  double _textSizeMultiplier = 1.4; // Default to Large for seniors
  bool _audioPlayback = true;
  bool _hasCompletedOnboarding = false;
  bool _hasCompletedAccessibilitySetup = false;
  SharedPreferences? _prefs;

  // Getters
  double get textSizeMultiplier => _textSizeMultiplier;
  bool get audioPlayback => _audioPlayback;
  bool get isAudioEnabled => _audioPlayback; // Alias for consistency
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
  static const String _audioPlaybackKey = 'audio_playback';
  static const String _onboardingKey = 'completed_onboarding';
  static const String _accessibilitySetupKey = 'completed_accessibility_setup';

  /// Initialize the service and load saved preferences
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    
    _textSizeMultiplier = _prefs!.getDouble(_textSizeKey) ?? 1.4;
    _audioPlayback = _prefs!.getBool(_audioPlaybackKey) ?? true;
    _hasCompletedOnboarding = _prefs!.getBool(_onboardingKey) ?? false;
    _hasCompletedAccessibilitySetup = _prefs!.getBool(_accessibilitySetupKey) ?? false;
    
    notifyListeners();
  }

  /// Set text size multiplier (1.2 = large, 1.4 = extra large, 1.6 = extra extra large)
  Future<void> setTextSizeMultiplier(double multiplier) async {
    _textSizeMultiplier = multiplier;
    await _prefs?.setDouble(_textSizeKey, multiplier);
    notifyListeners();
  }


  /// Toggle audio playback
  Future<void> setAudioPlayback(bool enabled) async {
    _audioPlayback = enabled;
    await _prefs?.setBool(_audioPlaybackKey, enabled);
    notifyListeners();
  }

  /// Mark onboarding as completed
  Future<void> completeOnboarding() async {
    _hasCompletedOnboarding = true;
    await _prefs?.setBool(_onboardingKey, true);
    notifyListeners();
  }

  /// Mark accessibility setup as completed
  Future<void> completeAccessibilitySetup() async {
    _hasCompletedAccessibilitySetup = true;
    await _prefs?.setBool(_accessibilitySetupKey, true);
    notifyListeners();
  }

  /// Reset onboarding status (for testing or help replay)
  Future<void> resetOnboarding() async {
    _hasCompletedOnboarding = false;
    await _prefs?.setBool(_onboardingKey, false);
    notifyListeners();
  }

  /// Get theme colors based on accessibility settings
  ColorScheme getColorScheme(Brightness brightness) {
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

  /// Get text theme with accessibility adjustments
  TextTheme getTextTheme() {
    return TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32 * _textSizeMultiplier,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
      headlineMedium: TextStyle(
        fontSize: 28 * _textSizeMultiplier,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
      bodyLarge: TextStyle(
        fontSize: 20 * _textSizeMultiplier,
        color: Colors.black87,
      ),
      bodyMedium: TextStyle(
        fontSize: 18 * _textSizeMultiplier,
        color: Colors.black87,
      ),
      labelLarge: TextStyle(
        fontSize: 16 * _textSizeMultiplier,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
      ),
    );
  }
}
