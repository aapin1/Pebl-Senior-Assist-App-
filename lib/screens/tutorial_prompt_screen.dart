import 'package:flutter/material.dart';
import 'onboarding_screen.dart';
import 'home_screen.dart';

/// Screen that asks if user wants to see the tutorial after preferences setup
class TutorialPromptScreen extends StatelessWidget {
  const TutorialPromptScreen({super.key});

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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                // Enhanced icon with multiple shadows and glow effect
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        Colors.blue.shade50,
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.8),
                        blurRadius: 30,
                        offset: const Offset(0, 0),
                      ),
                      BoxShadow(
                        color: Colors.blue.shade200.withOpacity(0.6),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.school_rounded,
                    size: 70,
                    color: Colors.blue.shade600,
                  ),
                ),
                
                const SizedBox(height: 50),
                
                // Enhanced title with shadow effect
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Ready to Learn?',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                      letterSpacing: -1.0,
                      shadows: [
                        Shadow(
                          color: Colors.white.withOpacity(0.8),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Enhanced description with backdrop
                Container(
                  padding: const EdgeInsets.all(24),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'Would you like to see a quick tutorial on how to use Pebl? It only takes a minute and will help you get the most out of the app.',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade700,
                      height: 1.6,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Enhanced buttons with premium styling
                Column(
                  children: [
                    // Yes button with vibrant gradient and glow
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 65),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.green.shade400,
                            Colors.green.shade600,
                            Colors.teal.shade500,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.shade300.withOpacity(0.6),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: Colors.white.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => const OnboardingScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          minimumSize: const Size.fromHeight(65),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          'Yes, Show Me the Tutorial',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // No button with glass morphism effect
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 60),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade600.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.grey.shade500,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => const HomeScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          minimumSize: const Size.fromHeight(60),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text(
                          'No Thanks, Take Me to the App',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
