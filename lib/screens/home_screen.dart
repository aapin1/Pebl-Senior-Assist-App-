import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../widgets/microphone_button.dart';
import '../widgets/interactive_learning_card.dart';
import '../widgets/ad_disclaimer_dialog.dart';
import '../services/ai_service.dart';
import '../services/accessibility_service.dart';
import 'demo_screen.dart';
import 'accessibility_setup_screen.dart';
import 'question_screen.dart';
import 'medicine_screen.dart';

/// Home screen of the Pebl app
/// Contains the main title and Ask a Question button
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
    return AnimatedBuilder(
      animation: _accessibilityService,
      builder: (context, child) {
        return Scaffold(
          body: Container(
            height: MediaQuery.of(context).size.height,
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
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 10),
                      // App icon with shadow
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.shade200.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.smart_toy,
                            size: 50,
                            color: Colors.blue.shade600,
                          ),
                        ),
                      const SizedBox(height: 12),
                      Text(
                        'Pebl',
                        style: TextStyle(
                          fontSize: 28 * _accessibilityService.textSizeMultiplier,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                          letterSpacing: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 6),
                      
                      Text(
                        'Your friendly tech helper',
                        style: TextStyle(
                          fontSize: 14 * _accessibilityService.textSizeMultiplier,
                          color: Colors.blue.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Main Menu - Two Options
                      Expanded(
                        flex: 3,
                        child: Column(
                          children: [
                            // Ask a Question Option - Entire card is tappable
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  // Show disclaimer dialog EVERY time before entering question screen
                                  await AdDisclaimerDialog.showAlways(
                                    context: context,
                                    accessibilityService: _accessibilityService,
                                    onContinue: () {
                                      // This callback is called AFTER user dismisses disclaimer
                                      // OR immediately if disclaimer was already shown
                                      if (context.mounted) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => QuestionScreen(
                                              accessibilityService: _accessibilityService,
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  );
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
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
                                        size: 36,
                                        color: Colors.blue.shade600,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Ask Me Anything!',
                                        style: TextStyle(
                                          fontSize: 18 * _accessibilityService.textSizeMultiplier,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue.shade800,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Get help with tech',
                                        style: TextStyle(
                                          fontSize: 13 * _accessibilityService.textSizeMultiplier,
                                          color: Colors.grey.shade600,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // Manage Medicines Option - Entire card is tappable
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MedicineScreen(
                                        accessibilityService: _accessibilityService,
                                      ),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.95),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.purple.shade300,
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
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.medication,
                                        size: 36,
                                        color: Colors.purple.shade600,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Manage Medicines',
                                        style: TextStyle(
                                          fontSize: 18 * _accessibilityService.textSizeMultiplier,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.purple.shade800,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Track medications',
                                        style: TextStyle(
                                          fontSize: 13 * _accessibilityService.textSizeMultiplier,
                                          color: Colors.grey.shade600,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Additional Options - Settings and Demo as tappable cards
                      Row(
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
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
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
                                      size: 32,
                                      color: Colors.green.shade600,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Settings',
                                      style: TextStyle(
                                        fontSize: 15 * _accessibilityService.textSizeMultiplier,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade700,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
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
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
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
                                      size: 32,
                                      color: Colors.orange.shade600,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Demo',
                                      style: TextStyle(
                                        fontSize: 15 * _accessibilityService.textSizeMultiplier,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange.shade700,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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
