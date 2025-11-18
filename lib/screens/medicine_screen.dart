import 'package:flutter/material.dart';
import '../services/accessibility_service.dart';

/// Medicine management screen
/// Allows users to track and manage their medications
class MedicineScreen extends StatefulWidget {
  final AccessibilityService accessibilityService;
  
  const MedicineScreen({
    super.key,
    required this.accessibilityService,
  });

  @override
  State<MedicineScreen> createState() => _MedicineScreenState();
}

class _MedicineScreenState extends State<MedicineScreen> {
  @override
  void dispose() {
    // Stop any audio when navigating away from this screen
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.accessibilityService,
      builder: (context, child) {
        return Scaffold(
          body: Container(
            height: MediaQuery.of(context).size.height,
            // Same gradient background as question screen
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
                    // Back button
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.arrow_back),
                          iconSize: 28,
                          color: Colors.blue.shade700,
                        ),
                        Expanded(
                          child: Text(
                            'Manage Medicines',
                            style: TextStyle(
                              fontSize: 24 * widget.accessibilityService.textSizeMultiplier,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 48), // Balance the back button
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Medicine icon
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
                        Icons.medication,
                        size: 50,
                        color: Colors.blue.shade600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Placeholder text
                    Text(
                      'Medicine tracking coming soon!',
                      style: TextStyle(
                        fontSize: 18 * widget.accessibilityService.textSizeMultiplier,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
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
