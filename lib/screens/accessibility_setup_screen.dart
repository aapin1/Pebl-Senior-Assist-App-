import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/accessibility_service.dart';
import 'tutorial_prompt_screen.dart';

/// First-time accessibility setup survey screen
/// Asks users about vision, hearing, and preference needs
class AccessibilitySetupScreen extends StatefulWidget {
  const AccessibilitySetupScreen({super.key});

  @override
  State<AccessibilitySetupScreen> createState() => _AccessibilitySetupScreenState();
}

class _AccessibilitySetupScreenState extends State<AccessibilitySetupScreen> {
  final PageController _pageController = PageController();
  final FlutterTts _flutterTts = FlutterTts();
  final AccessibilityService _accessibilityService = AccessibilityService();
  
  int _currentPage = 0;
  bool _isPlaying = false;
  
  // User responses
  double _selectedTextSize = 1.0;
  bool _wantsAudioPlayback = true;

  final List<SetupStep> _steps = [
    SetupStep(
      title: "Let's Set Up Your Preferences",
      description: "I'll ask you a few quick questions to make this app work better for you. This will only take a minute.",
      audioText: "Let's set up your preferences. I'll ask you a few quick questions to make this app work better for you. This will only take a minute.",
    ),
    SetupStep(
      title: "Text Size",
      description: "What text size is most comfortable for you to read?",
      audioText: "What text size is most comfortable for you to read?",
    ),
    SetupStep(
      title: "Audio Preferences",
      description: "Would you like me to read my responses out loud to you?",
      audioText: "Would you like me to read my responses out loud to you?",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  void _initTts() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.4);
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
      _completeSetup();
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

  void _completeSetup() async {
    // Stop any ongoing TTS before navigating
    await _flutterTts.stop();
    
    // Save all preferences
    await _accessibilityService.setTextSizeMultiplier(_selectedTextSize);
    await _accessibilityService.setAudioPlayback(_wantsAudioPlayback);
    await _accessibilityService.completeAccessibilitySetup();

    // Navigate to tutorial prompt screen
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const TutorialPromptScreen(),
        ),
      );
    }
  }


  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.settings_accessibility,
            size: 80,
            color: Colors.blue.shade600,
          ),
          const SizedBox(height: 40),
          Text(
            _steps[0].title,
            style: TextStyle(
              fontSize: 28 * _accessibilityService.textSizeMultiplier,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            _steps[0].description,
            style: TextStyle(
              fontSize: 20 * _accessibilityService.textSizeMultiplier,
              color: Colors.black87,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTextSizePage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Text Size',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 30),
            
            const Text(
              'Choose your preferred text size:',
              style: TextStyle(fontSize: 18, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            
            // Sample text that changes size
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300, width: 2),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade50,
              ),
              child: Text(
                'Sample text to show size',
                style: TextStyle(
                  fontSize: 18 * _selectedTextSize,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 30),
            
            // Text size options
            Column(
              children: [
                _buildTextSizeOption('Medium', 1.0),
                const SizedBox(height: 12),
                _buildTextSizeOption('Large', 1.25),
                const SizedBox(height: 12),
                _buildTextSizeOption('Extra Large', 1.5),
              ],
            ),
            
            const SizedBox(height: 40),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTextSizeOption(String label, double multiplier) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _selectedTextSize = multiplier;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: _selectedTextSize == multiplier ? Colors.blue.shade600 : Colors.grey.shade200,
          foregroundColor: _selectedTextSize == multiplier ? Colors.white : Colors.black87,
          minimumSize: const Size(0, 60), // Fixed button size
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 18), // Fixed button text size
        ),
      ),
    );
  }

  Widget _buildYesNoPage(int pageIndex, bool currentValue, Function(bool) onChanged, IconData icon, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 60,
            color: iconColor,
          ),
          const SizedBox(height: 40),
          Text(
            _steps[pageIndex].title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            _steps[pageIndex].description,
            style: const TextStyle(
              fontSize: 20,
              color: Colors.black87,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 50),
          
          // Yes/No buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => onChanged(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: currentValue ? Colors.green.shade600 : Colors.grey.shade200,
                    foregroundColor: currentValue ? Colors.white : Colors.black87,
                    minimumSize: const Size(0, 80),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Yes',
                    style: TextStyle(fontSize: 22),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => onChanged(false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: !currentValue ? Colors.red.shade600 : Colors.grey.shade200,
                    foregroundColor: !currentValue ? Colors.white : Colors.black87,
                    minimumSize: const Size(0, 80),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'No',
                    style: TextStyle(fontSize: 22),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
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
                    'Setup ${_currentPage + 1} of ${_steps.length}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  // Add play audio button only in setup portion
                  ElevatedButton.icon(
                    onPressed: () => _playAudio(_steps[_currentPage].audioText),
                    icon: Icon(_isPlaying ? Icons.stop : Icons.volume_up, size: 16),
                    label: Text(
                      _isPlaying ? 'Stop' : 'Audio',
                      style: const TextStyle(fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(80, 35),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: () async {
                        // Stop any ongoing TTS before navigating
                        await _flutterTts.stop();
                        _accessibilityService.completeOnboarding();
                        _accessibilityService.completeAccessibilitySetup();
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (context) => const TutorialPromptScreen()),
                        );
                      },
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          fontSize: 16,
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
                  switch (index) {
                    case 0:
                      return _buildWelcomePage();
                    case 1:
                      return _buildTextSizePage();
                    case 2:
                      return _buildYesNoPage(
                        2,
                        _wantsAudioPlayback,
                        (value) => setState(() => _wantsAudioPlayback = value),
                        Icons.volume_up,
                        Colors.teal.shade600,
                      );
                    default:
                      return Container();
                  }
                },
              ),
            ),
            
            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  // Previous button
                  if (_currentPage > 0)
                    ElevatedButton(
                      onPressed: _previousPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade600,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(100, 50),
                      ),
                      child: Text('Back'),
                    ),
                  
                  const Spacer(),
                  
                  // Next/Finish button
                  ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(120, 50),
                    ),
                    child: Text(
                      _currentPage == _steps.length - 1 ? 'Finish Setup' : 'Next',
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

/// Data class for setup steps
class SetupStep {
  final String title;
  final String description;
  final String audioText;

  SetupStep({
    required this.title,
    required this.description,
    required this.audioText,
  });
}
