import 'package:flutter/material.dart';
import 'accessibility_setup_screen.dart';

/// Welcome screen that introduces the app before accessibility setup
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

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
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
              // App icon with enhanced styling
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.shade200.withOpacity(0.6),
                      blurRadius: 25,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.smart_toy,
                  size: 70,
                  color: Colors.blue.shade600,
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Welcome title with enhanced styling
              Text(
                'Welcome to Pebl!',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                  letterSpacing: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              const SizedBox(height: 40),
              
              // Enhanced description container
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.blue.shade300,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.shade100.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 48,
                      color: Colors.blue.shade600,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'I am your friendly tech helper, designed to assist you with any of your technology questions.',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.grey.shade800,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Just speak your question and I\'ll provide clear, helpful answers.',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 36),
              
              // Enhanced continue button
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.shade100.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const AccessibilitySetupScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(65),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.arrow_forward, size: 24),
                  label: const Text(
                    'Get Started',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
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
