import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../services/accessibility_service.dart';
import '../services/ai_service.dart';
import '../services/settings_linker.dart';

/// Model for a learning step in the interactive system
class LearningStep {
  final String title;
  final String content;
  final String? question;
  final List<String>? options;
  final String? correctAnswer;
  final String? explanation;
  final bool requiresConfirmation;

  LearningStep({
    required this.title,
    required this.content,
    this.question,
    this.options,
    this.correctAnswer,
    this.explanation,
    this.requiresConfirmation = false,
  });
}

/// Interactive learning card widget that displays step-by-step content
class InteractiveLearningCard extends StatefulWidget {
  final List<LearningStep> steps;
  final Function(bool completed) onComplete;
  final AccessibilityService accessibilityService;
  final Function(String)? onStepRead;
  final String? deepLink;
  final String? userQuestion;

  const InteractiveLearningCard({
    super.key,
    required this.steps,
    required this.onComplete,
    required this.accessibilityService,
    this.onStepRead,
    this.deepLink,
    this.userQuestion,
  });

  @override
  State<InteractiveLearningCard> createState() => _InteractiveLearningCardState();
}

class _InteractiveLearningCardState extends State<InteractiveLearningCard>
    with TickerProviderStateMixin {
  int currentStepIndex = 0;
  bool showQuestion = false;
  String? selectedAnswer;
  bool showExplanation = false;
  bool stepCompleted = false;
  bool showConfirmation = false;
  bool awaitingTroubleshooting = false;
  bool isListening = false;
  String troubleshootingInput = '';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Follow-up question functionality
  final SpeechToText _speechToText = SpeechToText();
  final AIService _aiService = AIService();
  bool isListeningForFollowUp = false;
  bool isProcessingFollowUp = false;
  String followUpQuestion = '';
  String followUpAnswer = '';
  bool showFollowUpAnswer = false;
  Timer? _speechTimeout;
  
  // Deep link state - only show button if verified
  SettingsLinkResult? _verifiedDeepLink;
  bool _deepLinkVerified = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    
    // Verify deep link if provided
    _verifyDeepLink();
  }
  
  /// Verify the deep link is valid and launchable before showing button
  Future<void> _verifyDeepLink() async {
    if (widget.deepLink == null || widget.deepLink!.isEmpty) {
      return;
    }
    
    final result = await SettingsLinker.verifyAndGetLink(widget.deepLink);
    
    if (mounted) {
      setState(() {
        _verifiedDeepLink = result;
        _deepLinkVerified = result.isValid;
      });
    }
  }
  
  /// Launch the verified settings URL
  Future<void> _launchSettingsLink() async {
    if (_verifiedDeepLink == null || !_verifiedDeepLink!.isValid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'This feature is not available for this step.',
              style: TextStyle(
                fontSize: 16 * widget.accessibilityService.textSizeMultiplier,
              ),
            ),
            backgroundColor: Colors.orange.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    
    try {
      // Use category-based launch for better reliability
      final launched = await SettingsLinker.launchSettingsForCategory(
        _verifiedDeepLink!.category,
      );

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'This feature is not available for this step.',
              style: TextStyle(
                fontSize: 16 * widget.accessibilityService.textSizeMultiplier,
              ),
            ),
            backgroundColor: Colors.orange.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'This feature is not available for this step.',
              style: TextStyle(
                fontSize: 16 * widget.accessibilityService.textSizeMultiplier,
              ),
            ),
            backgroundColor: Colors.orange.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
  
  /// Share the question and steps with family via native share sheet
  Future<void> _shareWithFamily() async {
    // Build the share message
    final StringBuffer message = StringBuffer();
    
    // Add the user's question
    final question = widget.userQuestion ?? 'a tech question';
    message.writeln('Hi! I\'m using Pebl to figure out: $question');
    message.writeln();
    message.writeln('Pebl gave me these steps:');
    
    // Add all steps
    for (int i = 0; i < widget.steps.length; i++) {
      final step = widget.steps[i];
      message.writeln('${i + 1}. ${step.title}');
      message.writeln('   ${step.content}');
      message.writeln();
    }
    
    message.writeln('But I\'m still a little stuck. Can you help me with this?');
    
    // Get the render box for share position (required on iPad)
    final box = context.findRenderObject() as RenderBox?;
    final sharePositionOrigin = box != null 
        ? box.localToGlobal(Offset.zero) & box.size
        : const Rect.fromLTWH(0, 0, 100, 100);
    
    try {
      // Load app icon from assets and save to temp file for sharing
      final byteData = await rootBundle.load('assets/icons/app_icon_1024.png');
      final tempDir = await getTemporaryDirectory();
      final iconFile = File('${tempDir.path}/pebl_share_icon.png');
      await iconFile.writeAsBytes(byteData.buffer.asUint8List());
      
      // Share with image (shows logo in share sheet)
      await Share.shareXFiles(
        [XFile(iconFile.path)],
        text: message.toString(),
        subject: 'Help me with: $question',
        sharePositionOrigin: sharePositionOrigin,
      );
    } catch (e) {
      // Fallback to text-only share if image fails
      await Share.share(
        message.toString(),
        subject: 'Help me with: $question',
        sharePositionOrigin: sharePositionOrigin,
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _speechTimeout?.cancel();
    super.dispose();
  }

  void _nextStep() async {
    // Stop current audio before moving to next step
    if (widget.onStepRead != null) {
      widget.onStepRead!('');
    }
    
    // Stop any active speech recognition and clear timers
    _speechTimeout?.cancel();
    if (_speechToText.isListening) {
      await _speechToText.stop();
    }
    
    if (currentStepIndex < widget.steps.length - 1) {
      setState(() {
        currentStepIndex++;
        showQuestion = false;
        selectedAnswer = null;
        showExplanation = false;
        stepCompleted = false;
        showConfirmation = false;
        awaitingTroubleshooting = false;
        showFollowUpAnswer = false;
        followUpQuestion = '';
        followUpAnswer = '';
        isListeningForFollowUp = false;
        isProcessingFollowUp = false;
      });
      _animationController.reset();
      _animationController.forward();
      
      // Start reading the new step if audio is enabled
      if (widget.accessibilityService.isAudioEnabled && widget.onStepRead != null) {
        final currentStep = widget.steps[currentStepIndex];
        await Future.delayed(const Duration(milliseconds: 500));
        widget.onStepRead!(currentStep.content);
      }
    } else {
      // Stop audio on completion
      if (widget.onStepRead != null) {
        widget.onStepRead!('');
      }
      widget.onComplete(true);
    }
  }

  void _startFollowUpListening() async {
    if (!isListeningForFollowUp) {
      // Stop current audio narration when starting Question feature
      if (widget.onStepRead != null) {
        widget.onStepRead!('');
      }
      
      setState(() {
        isListeningForFollowUp = true;
        followUpQuestion = 'Listening for your question...';
      });

      try {
        bool available = await _speechToText.initialize();
        if (available) {
          // Start 7-second timeout
          _speechTimeout = Timer(const Duration(seconds: 7), () {
            if (isListeningForFollowUp && followUpQuestion.isNotEmpty && 
                followUpQuestion != 'Listening for your question...') {
              _processFollowUpQuestion(followUpQuestion);
            } else {
              _stopListening();
            }
          });
          
          await _speechToText.listen(
            onResult: (result) {
              setState(() {
                followUpQuestion = result.recognizedWords;
              });
              
              // Reset timeout on new words
              _speechTimeout?.cancel();
              if (result.recognizedWords.isNotEmpty) {
                _speechTimeout = Timer(const Duration(seconds: 7), () {
                  if (isListeningForFollowUp && result.recognizedWords.isNotEmpty) {
                    _processFollowUpQuestion(result.recognizedWords);
                  }
                });
              }
              
              if (result.finalResult && result.recognizedWords.isNotEmpty) {
                _speechTimeout?.cancel();
                _processFollowUpQuestion(result.recognizedWords);
              }
            },
            listenOptions: SpeechListenOptions(
              partialResults: true,
              listenMode: ListenMode.confirmation,
            ),
            localeId: 'en_US',
          );
        }
      } catch (e) {
        setState(() {
          followUpQuestion = 'Error starting speech recognition';
          isListeningForFollowUp = false;
        });
      }
    } else {
      _stopListening();
    }
  }

  void _stopListening() async {
    _speechTimeout?.cancel();
    await _speechToText.stop();
    setState(() {
      isListeningForFollowUp = false;
    });
  }

  void _processFollowUpQuestion(String question) async {
    _speechTimeout?.cancel();
    setState(() {
      isListeningForFollowUp = false;
      isProcessingFollowUp = true;
      followUpAnswer = 'Thinking about your question...';
    });

    try {
      final currentStep = widget.steps[currentStepIndex];
      final context = "Current step: ${currentStep.title}\nStep content: ${currentStep.content}\nUser's follow-up question: $question";
      
      final response = await _aiService.getFollowUpAnswer(context);
      
      setState(() {
        followUpAnswer = response;
        showFollowUpAnswer = true;
        isProcessingFollowUp = false;
      });
      
      // Read the follow-up answer aloud if audio is enabled
      if (widget.accessibilityService.isAudioEnabled && widget.onStepRead != null) {
        await Future.delayed(const Duration(milliseconds: 500));
        widget.onStepRead!(response);
      }
    } catch (e) {
      final errorMessage = "Sorry, I couldn't process your question. Please try again.";
      setState(() {
        followUpAnswer = errorMessage;
        showFollowUpAnswer = true;
        isProcessingFollowUp = false;
      });
      
      // Read the error message aloud if audio is enabled
      if (widget.accessibilityService.isAudioEnabled && widget.onStepRead != null) {
        await Future.delayed(const Duration(milliseconds: 500));
        widget.onStepRead!(errorMessage);
      }
    }
  }

  void _showQuestionOrNext() {
    final currentStep = widget.steps[currentStepIndex];
    if (currentStep.question != null && !showQuestion) {
      setState(() {
        showQuestion = true;
      });
    } else if (!showConfirmation && !awaitingTroubleshooting) {
      setState(() {
        showConfirmation = true;
      });
    } else {
      _nextStep();
    }
  }

  void _selectAnswer(String answer) {
    setState(() {
      selectedAnswer = answer;
      showExplanation = true;
      stepCompleted = true;
    });
  }

  void _handleNoResponse() {
    setState(() {
      awaitingTroubleshooting = true;
    });
  }

  void _handleYesResponse() {
    setState(() {
      showConfirmation = false;
      stepCompleted = true;
    });
    _nextStep();
  }

  String _generateConfirmationQuestion() {
    final currentStep = widget.steps[currentStepIndex];
    final title = currentStep.title.toLowerCase();
    
    // Generate dynamic questions based on step content
    if (title.contains('find') || title.contains('locate')) {
      return 'Did you manage to find what we\'re looking for?';
    } else if (title.contains('open') || title.contains('launch')) {
      return 'Did you manage to open the app or menu?';
    } else if (title.contains('tap') || title.contains('click') || title.contains('select')) {
      return 'Did you manage to tap or select the option?';
    } else if (title.contains('settings')) {
      return 'Did you manage to find the settings?';
    } else if (title.contains('search')) {
      return 'Did you manage to search successfully?';
    } else if (title.contains('type') || title.contains('enter')) {
      return 'Did you manage to type or enter the information?';
    } else {
      return 'Did you manage to complete this step?';
    }
  }

  void _startTroubleshootingInput() {
    setState(() {
      isListening = true;
      troubleshootingInput = '';
    });
    
    // Simulate speech recognition for now
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          isListening = false;
          troubleshootingInput = 'I can\'t find the button you mentioned';
        });
        _updateStepWithTroubleshooting();
      }
    });
  }

  void _updateStepWithTroubleshooting() {
    final currentStep = widget.steps[currentStepIndex];
    
    // Create an updated step with additional guidance
    final updatedContent = '${currentStep.content}\n\nSince you mentioned: "$troubleshootingInput"\n\nLet me help: Look more carefully at the screen. The button might be at the bottom, or you might need to scroll down to see it. Take your time and look for any text that says what we\'re looking for.';
    
    // Update the current step content
    widget.steps[currentStepIndex] = LearningStep(
      title: currentStep.title,
      content: updatedContent,
      question: currentStep.question,
      options: currentStep.options,
      correctAnswer: currentStep.correctAnswer,
      explanation: currentStep.explanation,
      requiresConfirmation: true,
    );
    
    setState(() {
      awaitingTroubleshooting = false;
      showConfirmation = true;
    });
  }


  @override
  Widget build(BuildContext context) {
    final currentStep = widget.steps[currentStepIndex];
    final progress = (currentStepIndex + 1) / widget.steps.length;

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.shade100.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress indicator
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${currentStepIndex + 1}/${widget.steps.length}',
                      style: TextStyle(
                        fontSize: 14 * widget.accessibilityService.textSizeMultiplier,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Step title
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    currentStep.title,
                    style: TextStyle(
                      fontSize: 18 * widget.accessibilityService.textSizeMultiplier,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Step content
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Text(
                    currentStep.content,
                    style: TextStyle(
                      fontSize: 16 * widget.accessibilityService.textSizeMultiplier,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),
                ),
                
                // "Open Settings For Me" button - ONLY shown if deep link is verified
                if (_deepLinkVerified && _verifiedDeepLink != null && _verifiedDeepLink!.isValid) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 80,
                    child: ElevatedButton(
                      onPressed: _launchSettingsLink,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: Colors.green.shade300,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.settings,
                              size: 28,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Open ${SettingsLinker.getCategoryLabel(_verifiedDeepLink!.category ?? '')}',
                              style: TextStyle(
                                fontSize: 18 * widget.accessibilityService.textSizeMultiplier,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                
                // Question section
                if (showQuestion && currentStep.question != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.quiz,
                              color: Colors.orange.shade600,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Question:',
                              style: TextStyle(
                                fontSize: 16 * widget.accessibilityService.textSizeMultiplier,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          currentStep.question!,
                          style: TextStyle(
                            fontSize: 15 * widget.accessibilityService.textSizeMultiplier,
                            color: Colors.black87,
                          ),
                        ),
                        if (currentStep.options != null) ...[
                          const SizedBox(height: 16),
                          ...currentStep.options!.map((option) {
                            final isSelected = selectedAnswer == option;
                            final isCorrect = option == currentStep.correctAnswer;
                            final showResult = selectedAnswer != null;
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: InkWell(
                                onTap: selectedAnswer == null ? () => _selectAnswer(option) : null,
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: showResult
                                        ? (isCorrect
                                            ? Colors.green.shade100
                                            : isSelected
                                                ? Colors.red.shade100
                                                : Colors.white)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: showResult
                                          ? (isCorrect
                                              ? Colors.green.shade400
                                              : isSelected
                                                  ? Colors.red.shade400
                                                  : Colors.grey.shade300)
                                          : Colors.grey.shade300,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      if (showResult)
                                        Icon(
                                          isCorrect ? Icons.check_circle : 
                                          isSelected ? Icons.cancel : Icons.radio_button_unchecked,
                                          color: isCorrect
                                              ? Colors.green.shade600
                                              : isSelected
                                                  ? Colors.red.shade600
                                                  : Colors.grey.shade400,
                                          size: 20,
                                        ),
                                      if (showResult) const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          option,
                                          style: TextStyle(
                                            fontSize: 14 * widget.accessibilityService.textSizeMultiplier,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ],
                    ),
                  ),
                ],
                
                // Explanation section
                if (showExplanation && currentStep.explanation != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb,
                              color: Colors.green.shade600,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Explanation:',
                              style: TextStyle(
                                fontSize: 16 * widget.accessibilityService.textSizeMultiplier,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currentStep.explanation!,
                          style: TextStyle(
                            fontSize: 14 * widget.accessibilityService.textSizeMultiplier,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 24),
                
                // Confirmation question or troubleshooting
                if (showConfirmation && !awaitingTroubleshooting) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _generateConfirmationQuestion(),
                          style: TextStyle(
                            fontSize: 18 * widget.accessibilityService.textSizeMultiplier,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _handleYesResponse,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade600,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Yes',
                                  style: TextStyle(
                                    fontSize: 16 * widget.accessibilityService.textSizeMultiplier,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _handleNoResponse,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange.shade600,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'No',
                                  style: TextStyle(
                                    fontSize: 16 * widget.accessibilityService.textSizeMultiplier,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ] else if (awaitingTroubleshooting) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'What went wrong with this step?',
                          style: TextStyle(
                            fontSize: 18 * widget.accessibilityService.textSizeMultiplier,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tap the microphone to describe what you\'re seeing or what\'s not working.',
                          style: TextStyle(
                            fontSize: 14 * widget.accessibilityService.textSizeMultiplier,
                            color: Colors.orange.shade700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        if (isListening) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.mic, color: Colors.red.shade600),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Listening... Describe what went wrong',
                                    style: TextStyle(
                                      fontSize: 14 * widget.accessibilityService.textSizeMultiplier,
                                      color: Colors.red.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    _startTroubleshootingInput();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade600,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(Icons.mic),
                                  label: Text(
                                    'Describe Issue',
                                    style: TextStyle(
                                      fontSize: 16 * widget.accessibilityService.textSizeMultiplier,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextButton(
                                  onPressed: () {
                                    setState(() {
                                      awaitingTroubleshooting = false;
                                      showConfirmation = false;
                                    });
                                    _nextStep();
                                  },
                                  child: Text(
                                    'Skip Step',
                                    style: TextStyle(
                                      fontSize: 14 * widget.accessibilityService.textSizeMultiplier,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ] else if (!showConfirmation) ...[
                  // Show continue and help buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _nextStep,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: Icon(
                            currentStepIndex == widget.steps.length - 1
                                ? Icons.check
                                : Icons.arrow_forward,
                          ),
                          label: Text(
                            currentStepIndex == widget.steps.length - 1
                                ? 'Done'
                                : 'Next',
                            style: TextStyle(
                              fontSize: 14 * widget.accessibilityService.textSizeMultiplier,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _startFollowUpListening,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isListeningForFollowUp 
                                ? Colors.red.shade600 
                                : Colors.orange.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: Icon(
                            isListeningForFollowUp ? Icons.stop : Icons.help_outline,
                          ),
                          label: Text(
                            isListeningForFollowUp ? 'Stop' : 'Question',
                            style: TextStyle(
                              fontSize: 14 * widget.accessibilityService.textSizeMultiplier,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Follow-up question display
                  if (followUpQuestion.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Question:',
                            style: TextStyle(
                              fontSize: 14 * widget.accessibilityService.textSizeMultiplier,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            followUpQuestion,
                            style: TextStyle(
                              fontSize: 14 * widget.accessibilityService.textSizeMultiplier,
                              color: Colors.black87,
                            ),
                            softWrap: true,
                            overflow: TextOverflow.visible,
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  // Follow-up answer display
                  if (showFollowUpAnswer && followUpAnswer.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Text(
                        followUpAnswer,
                        style: TextStyle(
                          fontSize: 14 * widget.accessibilityService.textSizeMultiplier,
                          color: Colors.black87,
                        ),
                        softWrap: true,
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  ],
                  
                  // Processing indicator
                  if (isProcessingFollowUp) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade600),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Thinking about your question...',
                              style: TextStyle(
                                fontSize: 14 * widget.accessibilityService.textSizeMultiplier,
                                color: Colors.orange.shade700,
                              ),
                              softWrap: true,
                              overflow: TextOverflow.visible,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                ],
                
                // "Share with Family" button - always visible for human handoff
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 80,
                  child: OutlinedButton.icon(
                    onPressed: _shareWithFamily,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.purple.shade700,
                      side: BorderSide(
                        color: Colors.purple.shade400,
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: Icon(
                      Icons.share,
                      size: 28,
                      color: Colors.purple.shade600,
                    ),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        "I'm Still Stuck - Share with Family",
                        style: TextStyle(
                          fontSize: 16 * widget.accessibilityService.textSizeMultiplier,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade700,
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
