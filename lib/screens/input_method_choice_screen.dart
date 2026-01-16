import 'package:flutter/material.dart';
import '../services/accessibility_service.dart';
import 'question_screen.dart';
import 'typed_question_screen.dart';

/// Screen that lets the user choose how to describe their problem
/// Simple choice between speaking or typing for minimal clutter
class InputMethodChoiceScreen extends StatelessWidget {
  final AccessibilityService accessibilityService;

  const InputMethodChoiceScreen({
    super.key,
    required this.accessibilityService,
  });

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive sizing
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Calculate base text size from screen height
    final baseTextSize = screenHeight * 0.02;

    return AnimatedBuilder(
      animation: accessibilityService,
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
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Back',
                    style: TextStyle(
                      fontSize: 18 * accessibilityService.textSizeMultiplier,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.visible,
                    softWrap: false,
                  ),
                ),
              ),
            ),
            body: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.06,
                  vertical: screenHeight * 0.015,
                ),
                child: Column(
                  children: [
                    // Main question prompt
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: screenHeight * 0.012),
                      child: Text(
                        'How would you like to describe your problem?',
                        style: TextStyle(
                          fontSize: baseTextSize * 1.25 * accessibilityService.textSizeMultiplier,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    SizedBox(height: screenHeight * 0.015),
                    
                    // Option 1: Speak to microphone
                    Expanded(
                      child: _buildOptionCard(
                        context: context,
                        icon: Icons.mic,
                        iconColor: Colors.blue.shade600,
                        backgroundColor: Colors.blue.shade50,
                        borderColor: Colors.blue.shade300,
                        title: 'Speak to the microphone',
                        description: 'Tap to use your voice',
                        onTap: () {
                          // Navigate to voice-only question screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => QuestionScreen(
                                accessibilityService: accessibilityService,
                              ),
                            ),
                          );
                        },
                        baseTextSize: baseTextSize,
                        screenHeight: screenHeight,
                      ),
                    ),
                    
                    SizedBox(height: screenHeight * 0.02),
                    
                    // Option 2: Type it out
                    Expanded(
                      child: _buildOptionCard(
                        context: context,
                        icon: Icons.keyboard,
                        iconColor: Colors.green.shade600,
                        backgroundColor: Colors.green.shade50,
                        borderColor: Colors.green.shade300,
                        title: 'Type it out',
                        description: 'Tap to type your question',
                        onTap: () {
                          // Navigate to typed question screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TypedQuestionScreen(
                                accessibilityService: accessibilityService,
                              ),
                            ),
                          );
                        },
                        baseTextSize: baseTextSize,
                        screenHeight: screenHeight,
                      ),
                    ),
                    
                    SizedBox(height: screenHeight * 0.015),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Build a large, tappable option card for input method selection
  Widget _buildOptionCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required Color borderColor,
    required String title,
    required String description,
    required VoidCallback onTap,
    required double baseTextSize,
    required double screenHeight,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(screenHeight * 0.014),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: borderColor,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: borderColor.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableHeight = constraints.maxHeight;

            // Keep the icon big enough to recognize, but small enough to avoid overflow on XL text.
            final iconSize = (availableHeight * 0.35).clamp(44.0, screenHeight * 0.065);
            final titleSize = (baseTextSize * 0.95 * accessibilityService.textSizeMultiplier)
                .clamp(14.0, 28.0);
            final descriptionSize =
                (baseTextSize * 0.75 * accessibilityService.textSizeMultiplier)
                    .clamp(12.0, 22.0);

            return Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Large icon
                Icon(
                  icon,
                  size: iconSize,
                  color: iconColor,
                ),

                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.bold,
                        color: iconColor,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),

                // Description
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    description,
                    style: TextStyle(
                      fontSize: descriptionSize,
                      color: Colors.grey.shade700,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
