import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../widgets/microphone_button.dart';
import '../services/ai_service.dart';
import '../services/accessibility_service.dart';
import 'onboarding_screen.dart';
import 'accessibility_setup_screen.dart';

/// Home screen of the Senior Assist app
/// Contains the main title and microphone button for voice interaction
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Speech recognition instance
  final SpeechToText _speechToText = SpeechToText();
  
  // Text-to-speech instance
  final FlutterTts _flutterTts = FlutterTts();
  
  // AI service instance
  final AIService _aiService = AIService();
  
  // Accessibility service instance
  final AccessibilityService _accessibilityService = AccessibilityService();
  
  // Track whether the app is currently "listening"
  bool _isListening = false;
  
  // Track if AI is processing
  bool _isProcessing = false;
  
  // Store the transcribed text
  String _transcribedText = '';
  
  // Store AI response
  String _aiResponse = '';
  
  // Conversation history for context
  List<Map<String, String>> _conversationHistory = [];
  
  // Track if speech recognition is available
  bool _speechEnabled = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();
  }

  /// Initialize text-to-speech for AI responses
  void _initTts() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.5); // Slower for seniors
    await _flutterTts.setVolume(0.8);
    await _flutterTts.setPitch(1.0);
  }

  /// Initialize speech recognition and request permissions
  void _initSpeech() async {
    // Initialize speech recognition first (this will trigger permission request)
    _speechEnabled = await _speechToText.initialize(
      onError: (error) {
        setState(() {
          _isListening = false;
          _transcribedText = 'Error: ${error.errorMsg}';
        });
      },
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() {
            _isListening = false;
          });
        }
      },
    );
    
    if (!_speechEnabled) {
      setState(() {
        _transcribedText = 'Tap microphone to enable speech recognition';
      });
    }
  }

  /// Handles microphone button tap - starts/stops speech recognition
  void _onMicrophoneTapped() async {
    // Stop any ongoing TTS to prevent feedback loop
    await _flutterTts.stop();
    
    // If speech recognition isn't enabled, try to initialize it again
    if (!_speechEnabled) {
      setState(() {
        _transcribedText = 'Requesting microphone permission...';
      });
      
      // Try to initialize speech recognition (this will prompt for permission)
      _speechEnabled = await _speechToText.initialize(
        onError: (error) {
          setState(() {
            _isListening = false;
            _transcribedText = 'Permission denied or error: ${error.errorMsg}';
          });
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            setState(() {
              _isListening = false;
            });
          }
        },
      );
      
      if (!_speechEnabled) {
        setState(() {
          _transcribedText = 'Please allow microphone access in Settings > Privacy & Security > Microphone > Senior Assist';
        });
        return;
      } else {
        setState(() {
          _transcribedText = 'Permission granted! Tap microphone again to start listening.';
        });
        return;
      }
    }

    if (_isListening) {
      // Stop listening
      await _speechToText.stop();
      setState(() {
        _isListening = false;
      });
    } else {
      // Start listening
      setState(() {
        _isListening = true;
        _transcribedText = 'Listening...';
      });
      
      await _speechToText.listen(
        onResult: (result) {
          setState(() {
            _transcribedText = result.recognizedWords;
          });
          
          // If speech recognition is complete, process with AI
          if (result.finalResult && result.recognizedWords.isNotEmpty) {
            _processWithAI(result.recognizedWords);
          }
        },
        listenFor: const Duration(seconds: 30), // Listen for up to 30 seconds
        pauseFor: const Duration(seconds: 3), // Stop after 3 seconds of silence
        partialResults: true, // Show results as user speaks
        localeId: 'en_US', // English (US)
        listenMode: ListenMode.confirmation, // More accurate for seniors
      );
    }
  }

  /// Process user query with AI and speak the response
  Future<void> _processWithAI(String userQuery) async {
    setState(() {
      _isProcessing = true;
      _aiResponse = 'Let me help you with that...';
    });

    try {
      // Add user query to conversation history
      _conversationHistory.add({
        'role': 'user',
        'content': userQuery,
      });

      final response = await _aiService.getSeniorTechSupportWithHistory(userQuery, _conversationHistory);
      
      // Add AI response to conversation history
      _conversationHistory.add({
        'role': 'assistant',
        'content': response,
      });

      setState(() {
        _aiResponse = response;
        _isProcessing = false;
      });
      
      // Speak the AI response for accessibility (only if user wants audio)
      if (_accessibilityService.audioPlayback) {
        await _flutterTts.speak(response);
      }
    } catch (e) {
      setState(() {
        _aiResponse = 'I\'m having trouble right now. Please try again.';
        _isProcessing = false;
      });
    }
  }

  /// Clear all text and responses
  void _clearAll() {
    setState(() {
      _transcribedText = '';
      _aiResponse = '';
      _conversationHistory.clear(); // Reset conversation history
    });
  }


  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _accessibilityService,
      builder: (context, child) {
        return Scaffold(
          // Subtle gradient background for visual appeal
          backgroundColor: Colors.grey.shade50,
          
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false, // Remove back button
            actions: [
              IconButton(
                icon: const Icon(Icons.help_outline, size: 32),
                onPressed: () => _showHelpDialog(),
                tooltip: 'Help - Options',
              ),
            ],
          ),
          
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.blue.shade50,
                  Colors.white,
                  Colors.green.shade50,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      // Welcome card with app title
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.assistant,
                              size: 48 * _accessibilityService.textSizeMultiplier,
                              color: Colors.blue.shade600,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Senior Assist',
                              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                fontSize: 36 * _accessibilityService.textSizeMultiplier,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your AI Assistant',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontSize: 18 * _accessibilityService.textSizeMultiplier,
                                color: Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    
                      const SizedBox(height: 40),
                      
                      // Microphone section with enhanced styling
                      Container(
                        padding: const EdgeInsets.all(20.0),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.blue.shade200,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            if (!_isListening && _transcribedText.isEmpty)
                              Text(
                                'Tap the microphone to start speaking',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontSize: 18 * _accessibilityService.textSizeMultiplier,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            if (!_isListening && _transcribedText.isEmpty)
                              const SizedBox(height: 20),
                            // Microphone button widget
                            MicrophoneButton(
                              isListening: _isListening,
                              onTap: _onMicrophoneTapped,
                            ),
                          ],
                        ),
                      ),
              
                      const SizedBox(height: 30),
                      
                      // User's question display
                      if (_transcribedText.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 20,
                          ),
                          decoration: BoxDecoration(
                            color: _isListening ? Colors.blue.shade50 : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _isListening ? Colors.blue.shade300 : Colors.blue.shade200,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Question:',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 16 * _accessibilityService.textSizeMultiplier,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _transcribedText,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: 20 * _accessibilityService.textSizeMultiplier,
                          fontWeight: FontWeight.w500,
                          color: _isListening ? Colors.blue.shade700 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                    
                    // AI Response display
                    if (_aiResponse.isNotEmpty)
                      const SizedBox(height: 20),
                    if (_aiResponse.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 20,
                          ),
                          decoration: BoxDecoration(
                            color: _isProcessing ? Colors.orange.shade50 : Colors.green.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _isProcessing ? Colors.orange.shade300 : Colors.green.shade300,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isProcessing ? Icons.hourglass_empty : Icons.assistant,
                            color: _isProcessing ? Colors.orange.shade600 : Colors.green.shade600,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isProcessing ? 'Thinking...' : 'AI Assistant:',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 16 * _accessibilityService.textSizeMultiplier,
                              fontWeight: FontWeight.bold,
                              color: _isProcessing ? Colors.orange.shade600 : Colors.green.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _aiResponse,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: 18 * _accessibilityService.textSizeMultiplier,
                          fontWeight: FontWeight.w400,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                    
                    const SizedBox(height: 40),
                    
                    
                    // Clear button when there's content
                    if ((_transcribedText.isNotEmpty || _aiResponse.isNotEmpty) && !_isListening && !_isProcessing)
                      const SizedBox(height: 20),
                    if ((_transcribedText.isNotEmpty || _aiResponse.isNotEmpty) && !_isListening && !_isProcessing)
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _clearAll,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade600,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(150, 50),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Clear All',
                              style: TextStyle(fontSize: 18 * _accessibilityService.textSizeMultiplier),
                            ),
                          ),
                        ),
                    
                    const SizedBox(height: 40), // Bottom spacing
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Show help dialog with options for preferences or tutorial
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Help Options',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'What would you like to do?',
            style: TextStyle(fontSize: 18),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AccessibilitySetupScreen()),
                ).then((_) {
                  // Refresh the UI when returning from preferences
                  setState(() {});
                });
              },
              child: const Text(
                'Change Preferences',
                style: TextStyle(fontSize: 16),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const OnboardingScreen(returnToHome: true)),
                );
              },
              child: const Text(
                'View Tutorial',
                style: TextStyle(fontSize: 16),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        );
      },
    );
  }
}
