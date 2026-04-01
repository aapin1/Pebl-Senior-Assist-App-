import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../widgets/interactive_learning_card.dart';
import '../services/accessibility_service.dart';

/// DemoScreen provides an offline, pre-populated interactive tutorial
/// so reviewers and first-time users can see the app's core value
/// (step-by-step guidance) without network, sign-in, or permissions.
class DemoScreen extends StatefulWidget {
  const DemoScreen({super.key});

  @override
  State<DemoScreen> createState() => _DemoScreenState();
}

class _DemoScreenState extends State<DemoScreen> {
  // Local TTS engine for reading steps aloud in demo mode
  // We keep this self-contained and stop it on dispose.
  final FlutterTts _flutterTts = FlutterTts();

  // Access to app-wide accessibility settings (text size, audio toggle)
  final AccessibilityService _accessibilityService = AccessibilityService();

  // Simple safety flag to avoid overlapping TTS calls
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  /// Initialize TTS with senior-friendly defaults and basic error handling
  Future<void> _initTts() async {
    try {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.45); // Slower speech for clarity
      await _flutterTts.setVolume(0.9);
      await _flutterTts.setPitch(1.0);

      // Add a simple completion handler to reset state when done speaking
      _flutterTts.setCompletionHandler(() {
        if (mounted) {
          setState(() => _isSpeaking = false);
        }
      });

      // Add an error handler to avoid being stuck in speaking state
      _flutterTts.setErrorHandler((msg) {
        if (mounted) {
          setState(() => _isSpeaking = false);
        }
      });
    } catch (_) {
      // If TTS setup fails in simulator or restricted environments,
      // we fail gracefully and keep the demo fully usable without audio.
    }
  }

  /// Safely speak content with a soft timeout
  /// If audio is disabled in accessibility settings, do nothing
  Future<void> _readStep(String content) async {
    if (!_accessibilityService.isAudioEnabled) return;

    try {
      // Stop any ongoing speech before starting a new phrase
      await _flutterTts.stop();
      setState(() => _isSpeaking = true);

      // Speak the content
      await _flutterTts.speak(content);

      // Soft timeout: if something goes wrong, stop after ~12 seconds
      Future.delayed(const Duration(seconds: 12), () async {
        if (mounted && _isSpeaking) {
          await _flutterTts.stop();
          if (mounted) setState(() => _isSpeaking = false);
        }
      });
    } catch (_) {
      // Any platform or engine error should stop audio gracefully
      await _flutterTts.stop();
      if (mounted) setState(() => _isSpeaking = false);
    }
  }

  /// Build a small, clear set of steps that demonstrates the product
  /// value without network access.
  List<LearningStep> _demoSteps() {
    return [
      LearningStep(
        title: 'Open Settings',
        content:
            'Find the Settings app on your Home Screen. It looks like a grey gear icon. Tap it once to open.',
        requiresConfirmation: true,
      ),
      LearningStep(
        title: 'Find Wi‑Fi',
        content:
            'In Settings, look near the top for Wi‑Fi. Tap Wi‑Fi to view available networks.',
        requiresConfirmation: true,
      ),
      LearningStep(
        title: 'Connect to a Network',
        content:
            'Choose your network from the list. If it has a lock, enter the password, then tap Join.',
        question: 'What do you do after typing the Wi‑Fi password?',
        options: ['Tap Cancel', 'Tap Join', 'Close Settings'],
        correctAnswer: 'Tap Join',
        explanation:
            'Tap Join to connect. If the password is correct, you will see a checkmark next to the network.',
        requiresConfirmation: true,
      ),
      LearningStep(
        title: 'You’re Connected',
        content:
            'Once connected, you will see a checkmark next to your network name. You can press the Home button or swipe up to return to the Home Screen.',
        requiresConfirmation: false,
      ),
    ];
  }

  @override
  void dispose() {
    // Stop any audio when leaving the screen to prevent background playback
    _flutterTts.stop();
    // Note: If you have a shared serviceManager, call serviceManager.stopAudio() here.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade100,
              Colors.blue.shade50,
              Colors.white,
              Colors.green.shade50,
              Colors.green.shade100,
            ],
            stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),

                // Simple header row with back button text for seniors
                Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Back',
                            style: TextStyle(
                              fontSize: (14 * _accessibilityService.textSizeMultiplier)
                                  .clamp(14.0, 26.0),
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: true,
                          ),
                        ),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        'Demo Mode',
                        style: TextStyle(
                          fontSize: 20 * _accessibilityService.textSizeMultiplier,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const Expanded(child: SizedBox()),
                  ],
                ),

                const SizedBox(height: 8),

                // Visible explanation so reviewers and users know what to do
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Text(
                    'In the full app, you tap the microphone and ask your question. The app then gives you clear, step‑by‑step guidance.\n\nThe example below shows what a response looks like, without needing internet or microphone permissions.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16 * _accessibilityService.textSizeMultiplier,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Interactive demo card using local steps
                InteractiveLearningCard(
                  steps: _demoSteps(),
                  accessibilityService: _accessibilityService,
                  onStepRead: (content) => _readStep(content),
                  onComplete: (done) {
                    // When complete, return to Home for a smooth loop
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
