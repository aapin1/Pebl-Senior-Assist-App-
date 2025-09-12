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
      title: 'Welcome to Senior Assist',
      description: 'Your friendly voice assistant for Apple devices. Let me show you how to use this app.',
      icon: Icons.mic,
      iconColor: Colors.blue,
      audioText: 'Welcome to Senior Assist! Your friendly voice assistant for Apple devices. Let me show you how to use this app.',
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
      title: 'Step 3: Listen to the Answer',
      description: 'I will speak the answer out loud and also show it on your screen. The text will be large and easy to read.',
      icon: Icons.hearing,
      iconColor: Colors.purple,
      audioText: 'Step 3: Listen to the Answer. I will speak the answer out loud and also show it on your screen. The text will be large and easy to read.',
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
      await _flutterTts.speak(text);
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
          builder: (context) => const AccessibilitySetupScreen(),
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Text(
                    'Step ${_currentPage + 1} of ${_steps.length}',
                    style: TextStyle(
                      fontSize: 16 * _accessibilityService.textSizeMultiplier,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _skipOnboarding,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 16 * _accessibilityService.textSizeMultiplier,
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ),
                ],
              ),
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
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                        // Icon
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: step.iconColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            step.icon,
                            size: 60,
                            color: step.iconColor,
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                        
                        // Title
                        Text(
                          step.title,
                          style: TextStyle(
                            fontSize: 24 * _accessibilityService.textSizeMultiplier,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Description
                        Text(
                          step.description,
                          style: TextStyle(
                            fontSize: 18 * _accessibilityService.textSizeMultiplier,
                            color: Colors.black87,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 30),
                        
                        // Audio play button
                        ElevatedButton.icon(
                          onPressed: () => _playAudio(step.audioText),
                          icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
                          label: Text(
                            _isPlaying ? 'Stop Audio' : 'Play Audio',
                            style: TextStyle(
                              fontSize: 16 * _accessibilityService.textSizeMultiplier,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(150, 45),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                  );
                },
              ),
            ),
            
            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Previous button
                  if (_currentPage > 0)
                    ElevatedButton(
                      onPressed: _previousPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade600,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(100, 45),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Back',
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ),
                  
                  const Spacer(),
                  
                  // Next/Finish button
                  ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(120, 45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _currentPage == _steps.length - 1 ? 'Finish' : 'Next',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
