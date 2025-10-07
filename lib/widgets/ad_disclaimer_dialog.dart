import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/accessibility_service.dart';

/// First-time disclaimer dialog about ads
/// Shows once when user first clicks "Ask a Question"
/// Explains ads keep the app free and how to close them
class AdDisclaimerDialog extends StatelessWidget {
  final AccessibilityService accessibilityService;
  final VoidCallback onContinue;
  
  // SharedPreferences key to track if disclaimer was shown
  static const String _disclaimerShownKey = 'ad_disclaimer_shown';
  
  const AdDisclaimerDialog({
    super.key,
    required this.accessibilityService,
    required this.onContinue,
  });

  /// Check if disclaimer has been shown before
  static Future<bool> hasBeenShown() async {
    final prefs = await SharedPreferences.getInstance();
    bool shown = prefs.getBool(_disclaimerShownKey) ?? false;
    print('🔍 Checking disclaimer status: shown = $shown');
    return shown;
  }

  /// Mark disclaimer as shown
  static Future<void> markAsShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_disclaimerShownKey, true);
  }
  
  /// Reset disclaimer (for testing purposes)
  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_disclaimerShownKey);
  }

  /// Show disclaimer dialog EVERY time (not just first time)
  /// Returns true if dialog was shown
  static Future<bool> showAlways({
    required BuildContext context,
    required AccessibilityService accessibilityService,
    required VoidCallback onContinue,
  }) async {
    // Always show the disclaimer - no check needed
    print('📢 Showing disclaimer dialog now...');
    if (context.mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false, // User must tap button
        builder: (context) => AdDisclaimerDialog(
          accessibilityService: accessibilityService,
          onContinue: onContinue,
        ),
      );
      
      // Mark as shown AFTER dialog is dismissed
      await markAsShown();
      print('✅ Disclaimer shown and marked as complete');
      return true;
    }
    
    return false;
  }

  // Helper method to build a step with number badge
  static Widget _buildStep(String number, String text, AccessibilityService accessibilityService) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.orange.shade700,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15 * accessibilityService.textSizeMultiplier,
                color: Colors.grey.shade800,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade50,
              Colors.white,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 50,
                height: 50,
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(40),
              ),
                child: Icon(
                  Icons.info_outline,
                  size: 28,
                  color: Colors.blue.shade700,
                ),
              ),
              
              const SizedBox(height: 12),
            
              // Title
              Text(
                'Quick Message',
                style: TextStyle(
                  fontSize: 20 * accessibilityService.textSizeMultiplier,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            
              const SizedBox(height: 12),
              
              // Main message about ads
              Text(
                'Short ads keep this app free',
                style: TextStyle(
                  fontSize: 15 * accessibilityService.textSizeMultiplier,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            
              const SizedBox(height: 10),
              
              // Instructions
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200, width: 1.5),
              ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.orange.shade600,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text(
                              '1',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'When a video plays on the screen, watch it entirely',
                            style: TextStyle(
                              fontSize: 14 * accessibilityService.textSizeMultiplier,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.orange.shade600,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text(
                              '2',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'At the end, it should have an "X" in the corner',
                            style: TextStyle(
                              fontSize: 14 * accessibilityService.textSizeMultiplier,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
            
              // Thank you message
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite,
                    size: 16,
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Thank you!',
                      style: TextStyle(
                        fontSize: 12 * accessibilityService.textSizeMultiplier,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.visible,
                    softWrap: true,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 10),
            
              // Continue button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    print('🔘 User clicked Got It! button');
                    Navigator.of(context).pop(); // Close dialog
                    // Wait a tiny bit to ensure dialog is fully closed
                    await Future.delayed(const Duration(milliseconds: 100));
                    print('➡️ Calling onContinue to navigate');
                    onContinue(); // Continue to question screen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                  child: Text(
                    'Got It!',
                    style: TextStyle(
                      fontSize: 18 * accessibilityService.textSizeMultiplier,
                    fontWeight: FontWeight.w600,
                  ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
