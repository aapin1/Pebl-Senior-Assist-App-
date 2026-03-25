import 'package:flutter/material.dart';
import '../services/accessibility_service.dart';
import 'demo_screen.dart';
import 'accessibility_setup_screen.dart';
import 'input_method_choice_screen.dart';
import 'scam_analyzer_screen.dart';
import 'past_questions_screen.dart';

/// Responsive Home screen of the Pebl app
/// Adapts to all screen sizes using percentage-based sizing
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  // Accessibility service instance
  final AccessibilityService _accessibilityService = AccessibilityService();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive sizing
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Calculate base text size from screen height for natural appearance
    // This ensures text looks proportional on each device BEFORE accessibility multiplier
    final baseTextSize = screenHeight * 0.02; // 2% of screen height as base
    
    // Calculate responsive sizes as percentages of screen dimensions
    final iconSize = screenHeight * 0.10; // 10% of screen height
    final appTitleSize = baseTextSize * 1.3; // 30% larger than base
    final subtitleSize = baseTextSize * 0.7; // 30% smaller than base
    
    return AnimatedBuilder(
      animation: _accessibilityService,
      builder: (context, child) {
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
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.04,
                  vertical: screenHeight * 0.01,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: screenHeight * 0.01),
                    
                    // App icon with shadow - responsive size
                    Container(
                      width: iconSize,
                      height: iconSize,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(iconSize * 0.25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.shade200.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.smart_toy,
                        size: iconSize * 0.5,
                        color: Colors.blue.shade600,
                      ),
                    ),
                    
                    SizedBox(height: screenHeight * 0.015),
                    
                    // App title
                    Text(
                      'Pebl',
                      style: TextStyle(
                        fontSize: appTitleSize * _accessibilityService.textSizeMultiplier,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                        letterSpacing: 1.0,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    SizedBox(height: screenHeight * 0.005),
                    
                    // Subtitle
                    Text(
                      'Your friendly tech helper',
                      style: TextStyle(
                        fontSize: subtitleSize * _accessibilityService.textSizeMultiplier,
                        color: Colors.blue.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    SizedBox(height: screenHeight * 0.02),
              
                    // Main Menu - Two large buttons: Ask a Question + Is this a Scam?
                    // Ask a Question button
                    SizedBox(
                      height: screenHeight * 0.16,
                      child: InkWell(
                        onTap: () async {
                          if (context.mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => InputMethodChoiceScreen(
                                  accessibilityService: _accessibilityService,
                                ),
                              ),
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.03,
                            vertical: screenHeight * 0.01,
                          ),
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
                              Icon(
                                Icons.mic,
                                size: screenHeight * 0.045,
                                color: Colors.blue.shade600,
                              ),
                              SizedBox(height: screenHeight * 0.008),
                              Flexible(
                                child: Text(
                                  'Ask a Question',
                                  style: TextStyle(
                                    fontSize: baseTextSize * 1.1 * _accessibilityService.textSizeMultiplier,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade800,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.004),
                              Flexible(
                                child: Text(
                                  'Get help with tech',
                                  style: TextStyle(
                                    fontSize: baseTextSize * 0.75 * _accessibilityService.textSizeMultiplier,
                                    color: Colors.grey.shade600,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: screenHeight * 0.015),
                    
                    // Is this a Scam? button
                    SizedBox(
                      height: screenHeight * 0.16,
                      child: InkWell(
                        onTap: () async {
                          if (context.mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ScamAnalyzerScreen(
                                  accessibilityService: _accessibilityService,
                                ),
                              ),
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.03,
                            vertical: screenHeight * 0.01,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.orange.shade400,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.shade200.withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shield,
                                size: screenHeight * 0.045,
                                color: Colors.orange.shade600,
                              ),
                              SizedBox(height: screenHeight * 0.008),
                              Flexible(
                                child: Text(
                                  'Is this a Scam?',
                                  style: TextStyle(
                                    fontSize: baseTextSize * 1.1 * _accessibilityService.textSizeMultiplier,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade800,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.004),
                              Flexible(
                                child: Text(
                                  'Check suspicious messages',
                                  style: TextStyle(
                                    fontSize: baseTextSize * 0.75 * _accessibilityService.textSizeMultiplier,
                                    color: Colors.grey.shade600,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: screenHeight * 0.015),
                    
                    // My Past Questions button
                    SizedBox(
                      height: screenHeight * 0.12,
                      child: InkWell(
                        onTap: () async {
                          if (context.mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PastQuestionsScreen(
                                  accessibilityService: _accessibilityService,
                                ),
                              ),
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.03,
                            vertical: screenHeight * 0.01,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.purple.shade400,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.purple.shade200.withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.history,
                                size: screenHeight * 0.04,
                                color: Colors.purple.shade600,
                              ),
                              SizedBox(width: screenWidth * 0.03),
                              Flexible(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'My Past Questions',
                                      style: TextStyle(
                                        fontSize: baseTextSize * 1.0 * _accessibilityService.textSizeMultiplier,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.purple.shade800,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      'See previous answers',
                                      style: TextStyle(
                                        fontSize: baseTextSize * 0.7 * _accessibilityService.textSizeMultiplier,
                                        color: Colors.grey.shade600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                size: screenHeight * 0.035,
                                color: Colors.purple.shade400,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: screenHeight * 0.015),
              
                    // Additional Options - Settings and Demo as tappable cards
                    SizedBox(
                      height: screenHeight * 0.11,
                      child: Row(
                        children: [
                          // Settings button - entire card is tappable
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const AccessibilitySetupScreen(),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.02,
                                  vertical: screenHeight * 0.012,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.green.shade300,
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green.shade200.withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.settings,
                                      size: screenHeight * 0.038,
                                      color: Colors.green.shade600,
                                    ),
                                    SizedBox(height: screenHeight * 0.006),
                                    Flexible(
                                      child: Text(
                                        'Settings',
                                        style: TextStyle(
                                          fontSize: baseTextSize * 0.85 * _accessibilityService.textSizeMultiplier,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green.shade700,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          
                          SizedBox(width: screenWidth * 0.03),
                          
                          // Demo button - entire card is tappable
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const DemoScreen(),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.02,
                                  vertical: screenHeight * 0.012,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.orange.shade300,
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.orange.shade200.withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.school,
                                      size: screenHeight * 0.038,
                                      color: Colors.orange.shade600,
                                    ),
                                    SizedBox(height: screenHeight * 0.006),
                                    Flexible(
                                      child: Text(
                                        'Demo',
                                        style: TextStyle(
                                          fontSize: baseTextSize * 0.85 * _accessibilityService.textSizeMultiplier,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange.shade700,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: screenHeight * 0.01),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
