import 'package:flutter/material.dart';
import '../services/accessibility_service.dart';

/// Friendly dialog shown before ads to explain why they're necessary
/// Designed to be senior-friendly and non-alarming
class AdDialog extends StatelessWidget {
  final AccessibilityService accessibilityService;
  final VoidCallback onContinue;
  
  const AdDialog({
    super.key,
    required this.accessibilityService,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24.0),
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
            // Friendly icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.info_outline,
                size: 40,
                color: Colors.blue.shade700,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Title
            Text(
              'Quick Message',
              style: TextStyle(
                fontSize: 24 * accessibilityService.textSizeMultiplier,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            // Friendly explanation message
            Text(
              'To keep Pebl free for everyone, we show a short video every few questions.',
              style: TextStyle(
                fontSize: 18 * accessibilityService.textSizeMultiplier,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            // Additional reassurance
            Text(
              'It will only take a few seconds, then you can continue getting help!',
              style: TextStyle(
                fontSize: 16 * accessibilityService.textSizeMultiplier,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 24),
            
            // Continue button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  onContinue(); // Show the ad
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  'Continue',
                  style: TextStyle(
                    fontSize: 20 * accessibilityService.textSizeMultiplier,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
                Text(
                  'Thank you for your support!',
                  style: TextStyle(
                    fontSize: 14 * accessibilityService.textSizeMultiplier,
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  /// Static method to show the dialog
  static Future<void> show({
    required BuildContext context,
    required AccessibilityService accessibilityService,
    required VoidCallback onContinue,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false, // User must tap continue
      builder: (context) => AdDialog(
        accessibilityService: accessibilityService,
        onContinue: onContinue,
      ),
    );
  }
}
