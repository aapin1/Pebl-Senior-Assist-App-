import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/accessibility_service.dart';
import 'accessibility_setup_screen.dart';
import 'home_screen.dart';

/// Onboarding tutorial screen with visual walkthrough
/// Shows users how to use the app with step-by-step instructions
class OnboardingScreen extends StatefulWidget {
  final bool returnToHome;
  
  const OnboardingScreen({super.key, this.returnToHome = false});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final FlutterTts _flutterTts = FlutterTts();
  final AccessibilityService _accessibilityService = AccessibilityService();
  
  int _currentPage = 0;
  bool _isPlaying = false;

  final List<OnboardingStep> _steps = [
    OnboardingStep(
      title: 'Welcome to Pebl',
      description: 'Your friendly voice assistant for Apple devices. Let me show you how to use this app.',
      icon: Icons.mic,
      iconColor: Colors.blue,
      audioText: 'Welcome to Pebl! Your friendly voice assistant for Apple devices. Let me show you how to use this app.',
    ),
    OnboardingStep(
      title: 'Step 1: Tap the Microphone',
      description: 'Look for the large blue microphone button at the bottom of the screen. Tap it once to start speaking.',
      icon: Icons.touch_app,
      iconColor: Colors.green,
      audioText: 'Step 1: Tap the Microphone. Look for the large blue microphone button at the bottom of the screen. Tap it once to start speaking.',
    ),
    OnboardingStep(
      title: 'Step 2: Ask Your Question',
      description: 'Speak clearly and ask any question about your iPhone, iPad, or Mac. For example: "How do I make text bigger?" or "How do I connect to WiFi?"',
      icon: Icons.record_voice_over,
      iconColor: Colors.orange,
      audioText: 'Step 2: Ask Your Question. Speak clearly and ask any question about your iPhone, iPad, or Mac. For example: How do I make text bigger? or How do I connect to WiFi?',
    ),
    OnboardingStep(
      title: 'Step 3: Read the Answer',
      description: 'I will show the answer on your screen with large, easy-to-read text. You can also enable audio to have it read aloud.',
      icon: Icons.visibility,
      iconColor: Colors.purple,
      audioText: 'Step 3: Read the Answer. I will show the answer on your screen with large, easy-to-read text. You can also enable audio to have it read aloud.',
    ),
    OnboardingStep(
      title: 'Step 4: Get More Help',
      description: 'If you need to see this tutorial again, tap the Help button at the top of the screen. You are ready to start!',
      icon: Icons.help_outline,
      iconColor: Colors.teal,
      audioText: 'Step 4: Get More Help. If you need to see this tutorial again, tap the Help button at the top of the screen. You are ready to start!',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  void _initTts() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.4); // Slower for seniors
    await _flutterTts.setVolume(0.9);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _safeSpeak(String text) async {
    if (text.trim().isEmpty) return;

    try {
      await Future.any([
        _flutterTts.speak(text),
        Future.delayed(const Duration(seconds: 8)),
      ]);
    } catch (e) {
      // Ignore TTS errors so onboarding stays usable
    }
  }

  void _playAudio(String text) async {
    if (_isPlaying) {
      await _flutterTts.stop();
      setState(() {
        _isPlaying = false;
      });
    } else {
      setState(() {
        _isPlaying = true;
      });
      await _safeSpeak(text);
      setState(() {
        _isPlaying = false;
      });
    }
  }

  void _nextPage() async {
    // Stop any ongoing TTS when navigating
    await _flutterTts.stop();
    setState(() {
      _isPlaying = false;
    });
    
    if (_currentPage < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() async {
    // Stop any ongoing TTS when navigating
    await _flutterTts.stop();
    setState(() {
      _isPlaying = false;
    });
    
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _completeOnboarding() async {
    // Stop any ongoing TTS before navigating
    await _flutterTts.stop();
    
    if (widget.returnToHome) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
      );
    }
  }

  void _skipOnboarding() async {
    // Stop any ongoing TTS before navigating
    await _flutterTts.stop();
    
    _accessibilityService.completeOnboarding();
    if (widget.returnToHome) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const AccessibilitySetupScreen(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
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
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              children: [
                // Progress indicator
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: const SizedBox.shrink(),
                ),
                // Progress bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: LinearProgressIndicator(
                    value: (_currentPage + 1) / _steps.length,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                    minHeight: 4,
                  ),
                ),
                // Main content
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) async {
                      // Stop any ongoing TTS when page changes
                      await _flutterTts.stop();
                      setState(() {
                        _currentPage = index;
                        _isPlaying = false;
                      });
                    },
                    itemCount: _steps.length,
                    itemBuilder: (context, index) {
                      final step = _steps[index];
                      return SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40),
                            // Icon with glow effect
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    _steps[_currentPage].iconColor.withAlpha(30),
                                    _steps[_currentPage].iconColor.withAlpha(10),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                              child: Icon(
                                _steps[_currentPage].icon,
                                size: 60,
                                color: _steps[_currentPage].iconColor,
                              ),
                            ),
                            const SizedBox(height: 40),
                            // Title
                            Text(
                              _steps[_currentPage].title,
                              style: TextStyle(
                                fontSize: 28 * _accessibilityService.textSizeMultiplier,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            // Description
                            Text(
                              _steps[_currentPage].description,
                              style: TextStyle(
                                fontSize: 18 * _accessibilityService.textSizeMultiplier,
                                color: Colors.grey.shade600,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 36),
                            // Audio play button
                            ElevatedButton.icon(
                              onPressed: () => _playAudio(step.audioText),
                              icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
                              label: Text(
                                _isPlaying ? 'Stop Audio' : 'Play Audio',
                                style: TextStyle(
                                  fontSize: 16 * _accessibilityService.textSizeMultiplier,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade600,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(180, 56),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                // Navigation buttons
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      if (_currentPage > 0)
                        Flexible(
                          child: ElevatedButton(
                            onPressed: _previousPage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade300,
                              foregroundColor: Colors.grey.shade700,
                              minimumSize: const Size.fromHeight(56),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Previous',
                              style: TextStyle(
                                fontSize: 14 * _accessibilityService.textSizeMultiplier,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      if (_currentPage > 0) const SizedBox(width: 12),
                      Flexible(
                        child: ElevatedButton(
                          onPressed: _currentPage == _steps.length - 1 ? _completeOnboarding : _nextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(56),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _currentPage == _steps.length - 1 ? 'Finish' : 'Next',
                            style: TextStyle(
                              fontSize: 14 * _accessibilityService.textSizeMultiplier,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Data class for onboarding steps
class OnboardingStep {
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final String audioText;

  OnboardingStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.audioText,
  });
}
