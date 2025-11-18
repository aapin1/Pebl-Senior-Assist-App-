import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/accessibility_service.dart';
import 'home_screen.dart';

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
  bool _wantsAudioPlayback = true;
  bool _isAudioEnabled = true;
  double _selectedTextSize = 1.0;

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
    await _flutterTts.stop();
    if (_currentPage < _steps.length - 1) {
      setState(() {
        _currentPage++;
      });
    } else {
      _completeSetup();
    }
  }

  void _previousPage() async {
    await _flutterTts.stop();
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
    }
  }

  void _completeSetup() async {
    // Stop any ongoing TTS before navigating
    await _flutterTts.stop();
    
    // Save audio preference to accessibility service
    await _accessibilityService.setAudioPlayback(_wantsAudioPlayback);
    
    // Save all preferences
    await _accessibilityService.completeAccessibilitySetup();

    // Navigate directly to the Home screen (new flow: Welcome -> Preferences -> Home)
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
      );
    }
  }


  Widget _buildWelcomePage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 32.0),
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
                fontSize: 24 * _accessibilityService.textSizeMultiplier,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text(
              _steps[0].description,
              style: TextStyle(
                fontSize: 16 * _accessibilityService.textSizeMultiplier,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextSizePage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.text_fields,
              size: 80,
              color: Colors.green.shade600,
            ),
            const SizedBox(height: 40),
            Text(
              _steps[1].title,
              style: TextStyle(
                fontSize: 24 * _accessibilityService.textSizeMultiplier,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text(
              _steps[1].description,
              style: TextStyle(
                fontSize: 16 * _accessibilityService.textSizeMultiplier,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // Text size buttons
            Column(
              children: [
                _buildTextSizeButton('Medium', 1.4),
                const SizedBox(height: 12),
                _buildTextSizeButton('Large', 1.6),
                const SizedBox(height: 12),
                _buildTextSizeButton('Extra Large', 1.85),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextSizeButton(String label, double multiplier) {
    bool isSelected = _accessibilityService.textSizeMultiplier == multiplier;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _accessibilityService.setTextSizeMultiplier(multiplier);
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.blue.shade600 : Colors.white,
          foregroundColor: isSelected ? Colors.white : Colors.blue.shade600,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          minimumSize: const Size(0, 60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.blue.shade600),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildYesNoPage(int stepIndex, bool currentValue, Function(bool) onChanged, IconData icon, Color iconColor) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 60,
              color: iconColor,
            ),
            const SizedBox(height: 24),
            Text(
              _steps[stepIndex].title,
              style: TextStyle(
                fontSize: 22 * _accessibilityService.textSizeMultiplier,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              _steps[stepIndex].description,
              style: TextStyle(
                fontSize: 14 * _accessibilityService.textSizeMultiplier,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            // Add silent mode reminder for audio step
            if (stepIndex == 2) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.volume_off,
                          color: Colors.orange.shade600,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Turn off silent mode to hear audio',
                            style: TextStyle(
                              fontSize: 12 * _accessibilityService.textSizeMultiplier,
                              color: Colors.orange.shade800,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'If unsure, flip the switch on the left side UP (not down)',
                      style: TextStyle(
                        fontSize: 11 * _accessibilityService.textSizeMultiplier,
                        color: Colors.orange.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 20),
            Row(
              children: [
                _buildYesNoButton('Yes', true, currentValue, onChanged),
                const SizedBox(width: 16),
                _buildYesNoButton('No', false, currentValue, onChanged),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYesNoButton(String label, bool value, bool currentValue, Function(bool) onChanged) {
    bool isSelected = currentValue == value;
    return Expanded(
      child: ElevatedButton(
        onPressed: () => onChanged(value),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.blue.shade600 : Colors.white,
          foregroundColor: isSelected ? Colors.white : Colors.blue.shade600,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          minimumSize: const Size(0, 60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.blue.shade600),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentPage() {
    switch (_currentPage) {
      case 0:
        return _buildWelcomePage();
      case 1:
        return _buildTextSizePage();
      case 2:
        return _buildYesNoPage(2, _wantsAudioPlayback, (value) {
          setState(() {
            _wantsAudioPlayback = value;
          });
        }, Icons.volume_up, Colors.purple.shade600);
      default:
        return _buildWelcomePage();
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
        child: SafeArea(
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
              child: _buildCurrentPage(),
            ),
            
            // Navigation buttons at bottom
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
                      child: const Text(
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
                      style: const TextStyle(
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
