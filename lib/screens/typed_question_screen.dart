import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/interactive_learning_card.dart';
import '../services/ai_service.dart';
import '../services/accessibility_service.dart';

/// Screen for typing questions with optional screenshot attachment
/// Clean, minimal interface for text-based input
class TypedQuestionScreen extends StatefulWidget {
  final AccessibilityService accessibilityService;
  
  const TypedQuestionScreen({
    super.key,
    required this.accessibilityService,
  });

  @override
  State<TypedQuestionScreen> createState() => _TypedQuestionScreenState();
}

class _TypedQuestionScreenState extends State<TypedQuestionScreen> {
  // Text-to-speech instance for AI responses
  final FlutterTts _flutterTts = FlutterTts();
  
  // AI service instance for processing questions
  final AIService _aiService = AIService();
  
  // Track if AI is processing the question
  bool _isProcessing = false;
  
  // Store AI learning steps response
  List<LearningStep> _learningSteps = [];
  
  // Track if learning is active (showing step-by-step cards)
  bool _isLearningActive = false;
  
  // Conversation history for context in follow-up questions
  List<Map<String, String>> _conversationHistory = [];
  
  // Track if scroll reminder should be shown
  bool _showScrollReminder = false;
  
  // Scroll controller to detect when user scrolls
  final ScrollController _scrollController = ScrollController();

  // Screenshot file selected by the user for additional context
  File? _screenshotFile;

  // Image picker instance for selecting screenshots
  final ImagePicker _imagePicker = ImagePicker();

  // Controller for typed questions
  final TextEditingController _typedQuestionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initTts();
    _scrollController.addListener(_onScroll);
  }
  
  // Hide scroll reminder when user scrolls near bottom
  void _onScroll() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      final threshold = maxScroll - 100;
      
      if (currentScroll >= threshold && _showScrollReminder) {
        setState(() {
          _showScrollReminder = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _typedQuestionController.dispose();
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
    _flutterTts.stop();
    if (content.isNotEmpty && widget.accessibilityService.isAudioEnabled) {
      _safeSpeak(content);
    }
  }

  // Speak with error handling + timeout so TTS never hangs the UI
  Future<void> _safeSpeak(String content) async {
    if (content.trim().isEmpty) return;

    try {
      await Future.any([
        _flutterTts.speak(content),
        Future.delayed(const Duration(seconds: 8)),
      ]);
    } catch (e) {
      // Silently ignore TTS errors to avoid confusing seniors
    }
  }

  /// Initialize text-to-speech for AI responses with senior-friendly settings
  void _initTts() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(0.8);
    await _flutterTts.setPitch(1.0);
  }

  /// Process the user's typed question with AI service
  Future<void> _processQuestion(String question) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // Add user question to conversation history for context
      _conversationHistory.add({
        'role': 'user',
        'content': question,
      });

      // Get AI response as learning steps, passing along any attached screenshot path
      final String? screenshotPath = _screenshotFile?.path;
      List<LearningStep> steps = await _aiService.getSeniorTechSupportStepsWithHistory(
        question,
        _conversationHistory,
        screenshotPath: screenshotPath,
      );
      
      // Show scroll reminder after a short delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && _isLearningActive) {
          setState(() {
            _showScrollReminder = true;
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
        await _safeSpeak(steps.first.content);
      }

    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  /// Clear all content and return to initial state
  void _clearAll() {
    _flutterTts.stop();
    setState(() {
      _learningSteps = [];
      _isLearningActive = false;
      _isProcessing = false;
      _conversationHistory.clear();
      _screenshotFile = null;
      _typedQuestionController.clear();
    });
  }

  /// Let the user pick a screenshot from the photo library
  Future<void> _pickScreenshot() async {
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );

      if (picked != null) {
        setState(() {
          _screenshotFile = File(picked.path);
        });
      }
    } catch (e) {
      // Silently ignore picker errors for now to avoid confusing seniors
    }
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
                    
                        // Main input area - always visible but changes based on state
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
                              // Only show input interface if no learning is active
                              if (!_isLearningActive) ...[
                                Icon(
                                  Icons.keyboard,
                                  size: 48,
                                  color: Colors.green.shade400,
                                ),
                                const SizedBox(height: 16),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Column(
                                    children: [
                                      Text(
                                        'Type your question below',
                                        style: TextStyle(
                                          fontSize: 16 * widget.accessibilityService.textSizeMultiplier,
                                          color: Colors.blue.shade700,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        textAlign: TextAlign.center,
                                        softWrap: true,
                                        overflow: TextOverflow.visible,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Text input area (replaces the mic button area)
                                SizedBox(
                                  height: 100,
                                  child: Center(
                                    child: TextField(
                                      controller: _typedQuestionController,
                                      maxLines: 3,
                                      textInputAction: TextInputAction.newline,
                                      style: TextStyle(
                                        fontSize: 15 * widget.accessibilityService.textSizeMultiplier,
                                        color: Colors.black,
                                      ),
                                      onChanged: (_) {
                                        setState(() {});
                                      },
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: Colors.grey.shade50,
                                        hintText: 'Click here...',
                                        hintStyle: TextStyle(
                                          fontSize: 14 * widget.accessibilityService.textSizeMultiplier,
                                          color: Colors.grey.shade500,
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: Colors.grey.shade300),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: Colors.grey.shade300),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Button to add a screenshot for extra context
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _pickScreenshot,
                                    icon: const Icon(Icons.image, size: 22),
                                    label: Text(
                                      _screenshotFile == null
                                          ? 'Add screenshot'
                                          : 'Change screenshot',
                                      style: TextStyle(
                                        fontSize: 15 * widget.accessibilityService.textSizeMultiplier,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue.shade50,
                                      foregroundColor: Colors.blue.shade700,
                                      elevation: 0,
                                      side: BorderSide(color: Colors.blue.shade200, width: 1.5),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    ),
                                  ),
                                ),

                                if (_screenshotFile != null) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.file(
                                            _screenshotFile!,
                                            width: 56,
                                            height: 56,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            'Screenshot attached',
                                            style: TextStyle(
                                              fontSize: 13 * widget.accessibilityService.textSizeMultiplier,
                                              color: Colors.grey.shade800,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.close,
                                            size: 20,
                                            color: Colors.grey.shade600,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _screenshotFile = null;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                
                                const SizedBox(height: 16),

                                // Submit button (matches the placement of the voice screen status area)
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: (_isProcessing || _typedQuestionController.text.trim().isEmpty)
                                        ? null
                                        : () {
                                            final text = _typedQuestionController.text.trim();
                                            _processQuestion(text);
                                          },
                                    icon: const Icon(Icons.send, size: 20),
                                    label: Text(
                                      'Ask',
                                      style: TextStyle(
                                        fontSize: 14 * widget.accessibilityService.textSizeMultiplier,
                                      ),
                                      overflow: TextOverflow.visible,
                                      softWrap: false,
                                    ),
                                    style: ButtonStyle(
                                      backgroundColor: WidgetStateProperty.resolveWith<Color>(
                                        (states) {
                                          if (states.contains(WidgetState.disabled)) {
                                            return Colors.grey.shade300;
                                          }
                                          return Colors.blue.shade600;
                                        },
                                      ),
                                      foregroundColor: WidgetStateProperty.resolveWith<Color>(
                                        (states) {
                                          if (states.contains(WidgetState.disabled)) {
                                            return Colors.grey.shade700;
                                          }
                                          return Colors.white;
                                        },
                                      ),
                                      padding: const WidgetStatePropertyAll(
                                        EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                      ),
                                      shape: WidgetStatePropertyAll(
                                        RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            
                                // Show thinking text when processing
                                if (_isProcessing) ...[
                                  const SizedBox(height: 16),
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
                                  onPressed: () {
                                    setState(() {
                                      _isLearningActive = false;
                                      _learningSteps = [];
                                    });
                                    _typedQuestionController.clear();
                                    _screenshotFile = null;
                                    _showScrollReminder = false;
                                  },
                                  icon: const Icon(Icons.keyboard, size: 20),
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
                
                // Scroll reminder indicator
                if (_isLearningActive && _showScrollReminder)
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: () {
                          _scrollController.animateTo(
                            _scrollController.offset + 200,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                          );
                          setState(() {
                            _showScrollReminder = false;
                          });
                        },
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width - 40,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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
                                Flexible(
                                  child: Text(
                                    'Scroll down to see more',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize:
                                          15 * widget.accessibilityService.textSizeMultiplier,
                                      fontWeight: FontWeight.w600,
                                    ),
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
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
