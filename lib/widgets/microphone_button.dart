import 'package:flutter/material.dart';

/// A large, accessible microphone button widget
/// Designed specifically for senior users with visual and tactile feedback
class MicrophoneButton extends StatelessWidget {
  /// Whether the microphone is currently listening
  final bool isListening;
  
  /// Callback function when the button is tapped
  final VoidCallback onTap;

  const MicrophoneButton({
    super.key,
    required this.isListening,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          // Change color based on listening state for visual feedback
          color: isListening ? Colors.red.shade400 : Colors.blue.shade600,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          // Add a subtle border for better definition
          border: Border.all(
            color: Colors.white,
            width: 3,
          ),
        ),
        child: Icon(
          Icons.mic,
          size: 60, // Large icon for easy visibility
          color: Colors.white,
        ),
      ),
    );
  }
}
