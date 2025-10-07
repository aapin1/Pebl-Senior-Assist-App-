import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../widgets/microphone_button.dart';
import '../widgets/interactive_learning_card.dart';
import '../services/ai_service.dart';
import '../services/accessibility_service.dart';
import '../services/ad_service.dart';

/// Dedicated question screen with large microphone button
/// Simple interface for seniors to ask questions
class QuestionScreen extends StatefulWidget {
  final AccessibilityService accessibilityService;
  
  const QuestionScreen({
    super.key,
    required this.accessibilityService,
  });

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  // Speech recognition instance for voice input
  final SpeechToText _speechToText = SpeechToText();
  
  // Text-to-speech instance for AI responses
  final FlutterTts _flutterTts = FlutterTts();
  
  // AI service instance for processing questions
  final AIService _aiService = AIService();
  
  // Track whether the app is currently listening for voice input
  bool _isListening = false;
  
  // Track if AI is processing the question
  bool _isProcessing = false;
  
  // Store the transcribed text from speech recognition
  String _transcribedText = '';
  
  // Store AI learning steps response
  List<LearningStep> _learningSteps = [];
  
  // Track if learning is active (showing step-by-step cards)
  bool _isLearningActive = false;
  
  // Conversation history for context in follow-up questions
  List<Map<String, String>> _conversationHistory = [];
  
  // Track if speech recognition is available on device
  bool _speechEnabled = false;
  
  // Track if scroll reminder should be shown
  bool _showScrollReminder = false;
  
  // Scroll controller to detect when user scrolls
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();
    _scrollController.addListener(_onScroll);
  }
  
  // Hide scroll reminder when user scrolls near bottom
  void _onScroll() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      final threshold = maxScroll - 100; // Hide when within 100px of bottom
      
      if (currentScroll >= threshold && _showScrollReminder) {
        setState(() {
          _showScrollReminder = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _speechToText.stop();
    _flutterTts.stop();
    _scrollController.dispose();
    super.dispose();
  }

  // Stop TTS when navigating away from screen
  void _stopTtsAndNavigate(VoidCallback navigationCallback) {
    _flutterTts.stop();
    navigationCallback();
  }

  // Method to handle TTS for learning steps - stops current audio first
  void _handleStepTts(String content) {
    _flutterTts.stop(); // Stop any current speech
    if (content.isNotEmpty && widget.accessibilityService.isAudioEnabled) {
      _flutterTts.speak(content);
    }
  }
  
  /// Show ad if needed (called after completing or asking another question)
  Future<void> _showAdIfNeeded() async {
    // Check if we should show an ad
    bool shouldShowAd = await AdService().onUserQuery();
    
    if (shouldShowAd && mounted) {
      print('📺 Showing ad after completion/new question');
      // Ad shows directly - no dialog needed
      // The AdService.onUserQuery() already triggered the ad
      
      // Add a small delay to let user settle back after ad
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  /// Initialize text-to-speech for AI responses with senior-friendly settings
  void _initTts() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.5); // Slower speech rate for seniors
    await _flutterTts.setVolume(0.8);
    await _flutterTts.setPitch(1.0);
  }

  /// Initialize speech recognition and request permissions
  void _initSpeech() async {
    // Initialize speech recognition (this will trigger permission request)
    _speechEnabled = await _speechToText.initialize(
      onError: (error) {
        setState(() {
          _isListening = false;
          _transcribedText = 'Error: ${error.errorMsg}';
        });
      },
      onStatus: (status) {
        // Handle speech recognition status changes
        if (status == 'done' || status == 'notListening') {
          setState(() {
            _isListening = false;
          });
        }
      },
    );
    
    // Show message if speech recognition is not available
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
          _transcribedText = 'Please allow microphone access in Settings > Privacy & Security > Microphone > Pebl';
        });
        return;
      } else {
        setState(() {
          _transcribedText = 'Permission granted! Tap microphone again to start listening.';
        });
        return;
      }
    }

    if (!_isListening) {
      // Start listening for voice input
      setState(() {
        _isListening = true;
        _transcribedText = 'Listening...';
      });

      try {
        // Start speech recognition with extended timeout for seniors
        await _speechToText.listen(
          onResult: (result) {
            setState(() {
              _transcribedText = result.recognizedWords;
            });
            
            // When speech recognition is complete, process the question
            if (result.finalResult && result.recognizedWords.isNotEmpty) {
              _processQuestion(result.recognizedWords);
            }
          },
          listenOptions: SpeechListenOptions(
            partialResults: true,
            listenMode: ListenMode.confirmation,
          ),
          localeId: 'en_US',
          listenFor: const Duration(seconds: 100), // Extended listening time
          pauseFor: const Duration(seconds: 10), // Extended pause tolerance
        );
      } catch (e) {
        setState(() {
          _isListening = false;
          _transcribedText = 'Error starting speech recognition';
        });
      }
    } else {
      // Stop listening
      await _speechToText.stop();
      setState(() {
        _isListening = false;
      });
    }
  }

  /// Process the user's question with AI service
  Future<void> _processQuestion(String question) async {
    setState(() {
      _isProcessing = true;
      _isListening = false;
    });

    try {
      // Don't show ad when asking question - only show after completion or new question
      
      // Add user question to conversation history for context
      _conversationHistory.add({
        'role': 'user',
        'content': question,
      });

      // Get AI response as learning steps
      List<LearningStep> steps = await _aiService.getSeniorTechSupportStepsWithHistory(question, _conversationHistory);
      
      // Show scroll reminder after a short delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && _isLearningActive) {
          setState(() {
            _showScrollReminder = true; // Show the reminder
          });
          
          // Auto-hide after 8 seconds if user hasn't scrolled
          Future.delayed(const Duration(seconds: 8), () {
            if (mounted && _showScrollReminder) {
              setState(() {
                _showScrollReminder = false;
              });
            }
          });
        }
      });
      
      // Add AI response to conversation history
      String aiContent = steps.map((step) => '${step.title}: ${step.content}').join('\n');
      _conversationHistory.add({
        'role': 'assistant', 
        'content': aiContent,
      });

      setState(() {
        _learningSteps = steps;
        _isLearningActive = true;
        _isProcessing = false;
      });

      // Read the first step aloud if audio is enabled
      if (widget.accessibilityService.isAudioEnabled && steps.isNotEmpty) {
        await _flutterTts.speak(steps.first.content);
      }

    } catch (e) {
      // Handle errors gracefully for seniors
      setState(() {
        _transcribedText = 'Sorry, I couldn\'t process your question. Please try again.';
        _isProcessing = false;
      });
    }
  }

  /// Clear all content and return to initial state
  void _clearAll() {
    _flutterTts.stop(); // Stop any ongoing TTS
    setState(() {
      _transcribedText = '';
      _learningSteps = [];
      _isLearningActive = false;
      _isProcessing = false;
      _conversationHistory.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.accessibilityService,
      builder: (context, child) {
        return Container(
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
            
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: Container(
                padding: const EdgeInsets.only(left: 8.0),
                child: TextButton(
                  onPressed: () => _stopTtsAndNavigate(() => Navigator.pop(context)),
                  child: Text(
                    'Back',
                    style: TextStyle(
                      fontSize: 18 * widget.accessibilityService.textSizeMultiplier,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.visible,
                    softWrap: false,
                  ),
                ),
              ),
            ),
            
            body: Stack(
              children: [
                SingleChildScrollView(
                  controller: _scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                    
                        // Prompt area - always visible but changes position and content
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(_isLearningActive ? 16.0 : 24.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.blue.shade300,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.shade200.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Show transcribed text when speaking or after question asked
                              if (_transcribedText.isNotEmpty) ...[
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: Text(
                                    _transcribedText,
                                    style: TextStyle(
                                      fontSize: 15 * widget.accessibilityService.textSizeMultiplier,
                                      color: Colors.grey.shade800,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                          
                              // Only show microphone interface if no learning is active
                              if (!_isLearningActive) ...[
                                // Status text with better styling
                                if (!_isListening && _transcribedText.isEmpty && !_isProcessing) ...[
                                  Icon(
                                    Icons.mic_none,
                                    size: 48,
                                    color: Colors.blue.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Column(
                                      children: [
                                        Text(
                                          'Tap the microphone below and ask your question',
                                          style: TextStyle(
                                            fontSize: 16 * widget.accessibilityService.textSizeMultiplier,
                                            color: Colors.blue.shade700,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 3,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Be as specific as possible',
                                          style: TextStyle(
                                            fontSize: 13 * widget.accessibilityService.textSizeMultiplier,
                                            color: Colors.grey.shade600,
                                            fontStyle: FontStyle.italic,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                            
                                // Large microphone button
                                SizedBox(
                                  height: 100, // Fixed height for button area
                                  child: Center(
                                    child: MicrophoneButton(
                                      isListening: _isListening,
                                      onTap: _onMicrophoneTapped,
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(height: 16),
                            
                                // Show thinking text below microphone when processing
                                if (_isProcessing) ...[
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Text(
                                      'Thinking about your question...',
                                      style: TextStyle(
                                        fontSize: 17 * widget.accessibilityService.textSizeMultiplier,
                                        color: Colors.blue.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                    ),
                                  ),
                                ],
                              ] else if (_isLearningActive) ...[
                                // Show "Ask Another Question" button when learning is active
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    // Show ad before allowing another question
                                    await _showAdIfNeeded();
                                    
                                    setState(() {
                                      _isLearningActive = false;
                                      _learningSteps.clear();
                                      _transcribedText = '';
                                      _showScrollReminder = false;
                                    });
                                  },
                                  icon: const Icon(Icons.mic, size: 20),
                                  label: Text(
                                    'Ask Another Question',
                                    style: TextStyle(
                                      fontSize: 14 * widget.accessibilityService.textSizeMultiplier,
                                    ),
                                    overflow: TextOverflow.visible,
                                    softWrap: true,
                                    textAlign: TextAlign.center,
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade600,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                          
                        // Interactive learning cards for AI response
                        if (_isLearningActive && _learningSteps.isNotEmpty) ...[
                          InteractiveLearningCard(
                            steps: _learningSteps,
                            accessibilityService: widget.accessibilityService,
                            onStepRead: _handleStepTts,
                            onComplete: (success) async {
                              if (success) {
                                // Show ad after completing the learning steps
                                await _showAdIfNeeded();
                                _clearAll();
                              }
                            },
                          ),
                        ],
                        
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                
                // Scroll reminder indicator - shows when learning is active and user hasn't scrolled to bottom
                if (_isLearningActive && _showScrollReminder)
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: () {
                          // Scroll down 200 pixels to show there's more content
                          _scrollController.animateTo(
                            _scrollController.offset + 200,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                          );
                          // Hide the reminder after scrolling
                          setState(() {
                            _showScrollReminder = false;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade600.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.arrow_downward,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Scroll down to see more',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15 * widget.accessibilityService.textSizeMultiplier,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
