import 'package:flutter/material.dart';
import '../services/accessibility_service.dart';

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

  const InteractiveLearningCard({
    super.key,
    required this.steps,
    required this.onComplete,
    required this.accessibilityService,
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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (currentStepIndex < widget.steps.length - 1) {
      setState(() {
        currentStepIndex++;
        showQuestion = false;
        selectedAnswer = null;
        showExplanation = false;
        stepCompleted = false;
        showConfirmation = false;
        awaitingTroubleshooting = false;
      });
      _animationController.reset();
      _animationController.forward();
    } else {
      widget.onComplete(true);
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
                  color: Colors.black.withOpacity(0.1),
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
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
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
                              'Quick Check:',
                              style: TextStyle(
                                fontSize: 16 * widget.accessibilityService.textSizeMultiplier,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade700,
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
                  // Show continue button only when not in confirmation mode
                  ElevatedButton.icon(
                    onPressed: (currentStep.question != null && selectedAnswer == null)
                        ? null
                        : _showQuestionOrNext,
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
                          : currentStep.question != null && !showQuestion
                              ? Icons.quiz
                              : Icons.arrow_forward,
                    ),
                    label: Text(
                      currentStepIndex == widget.steps.length - 1
                          ? 'Complete'
                          : currentStep.question != null && !showQuestion
                              ? 'Quick Check'
                              : 'Continue',
                      style: TextStyle(
                        fontSize: 16 * widget.accessibilityService.textSizeMultiplier,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                
              ],
            ),
          ),
        );
      },
    );
  }
}
