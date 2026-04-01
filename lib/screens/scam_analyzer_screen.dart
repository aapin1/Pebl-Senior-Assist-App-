import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ai_service.dart';
import '../services/accessibility_service.dart';
import 'home_screen.dart';

/// Scam Analyzer Screen - Analyzes screenshots for scam/phishing attempts
/// Immediately triggers screenshot picker, then shows results
class ScamAnalyzerScreen extends StatefulWidget {
  final AccessibilityService accessibilityService;
  
  const ScamAnalyzerScreen({
    super.key,
    required this.accessibilityService,
  });

  @override
  State<ScamAnalyzerScreen> createState() => _ScamAnalyzerScreenState();
}

class _ScamAnalyzerScreenState extends State<ScamAnalyzerScreen> {
  final FlutterTts _flutterTts = FlutterTts();
  final AIService _aiService = AIService();
  final ImagePicker _imagePicker = ImagePicker();
  
  bool _isProcessing = false;
  bool _hasResult = false;
  bool _pickerOpened = false;
  File? _screenshotFile;
  ScamAnalysisResult? _result;

  @override
  void initState() {
    super.initState();
    _initTts();
    // Trigger screenshot picker immediately after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pickScreenshotAndAnalyze();
    });
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  void _initTts() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.4); // Slower for seniors
    await _flutterTts.setVolume(0.9);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _safeSpeak(String content) async {
    if (content.trim().isEmpty) return;
    try {
      await Future.any([
        _flutterTts.speak(content),
        Future.delayed(const Duration(seconds: 15)),
      ]);
    } catch (e) {
      // Silently ignore TTS errors
    }
  }

  void _stopTtsAndNavigate(VoidCallback navigationCallback) {
    _flutterTts.stop();
    navigationCallback();
  }

  Future<void> _pickScreenshotAndAnalyze() async {
    if (_pickerOpened) return;
    _pickerOpened = true;
    
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );

      if (picked != null) {
        setState(() {
          _screenshotFile = File(picked.path);
          _isProcessing = true;
        });

        final result = await _aiService.analyzeScamScreenshot(picked.path);

        setState(() {
          _result = result;
          _isProcessing = false;
          _hasResult = true;
        });

        // Read the result aloud if audio is enabled
        if (widget.accessibilityService.isAudioEnabled && _result != null) {
          String statusText = '';
          switch (_result!.status) {
            case ScamStatus.danger:
              statusText = 'Warning! This looks like a scam.';
              break;
            case ScamStatus.suspicious:
              statusText = 'Be careful. This message looks suspicious.';
              break;
            case ScamStatus.safe:
              statusText = 'This message appears to be safe.';
              break;
            case ScamStatus.error:
              statusText = 'There was a problem analyzing this message.';
              break;
          }
          await _safeSpeak('$statusText ${_result!.explanation} ${_result!.action}');
        }
      } else {
        // User cancelled picker - go back
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _result = ScamAnalysisResult(
          status: ScamStatus.error,
          explanation: 'Could not open the photo picker.',
          action: 'Please try again.',
        );
        _hasResult = true;
      });
    }
  }

  void _analyzeAnother() {
    _flutterTts.stop();
    setState(() {
      _screenshotFile = null;
      _result = null;
      _hasResult = false;
      _isProcessing = false;
      _pickerOpened = false;
    });
    _pickScreenshotAndAnalyze();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final baseTextSize = screenHeight * 0.02;

    return AnimatedBuilder(
      animation: widget.accessibilityService,
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
              leadingWidth: 92,
              leading: Container(
                padding: const EdgeInsets.only(left: 8.0),
                child: TextButton(
                  onPressed: () => _stopTtsAndNavigate(() => Navigator.pop(context)),
                  child: Text(
                    'Back',
                    style: TextStyle(
                      fontSize: (14 * widget.accessibilityService.textSizeMultiplier)
                          .clamp(14.0, 26.0),
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                  ),
                ),
              ),
            ),
            body: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.05,
                  vertical: screenHeight * 0.02,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shield,
                          size: screenHeight * 0.04,
                          color: Colors.orange.shade600,
                        ),
                        SizedBox(width: screenWidth * 0.02),
                        Flexible(
                          child: Text(
                            'Scam Analyzer',
                            style: TextStyle(
                              fontSize: baseTextSize * 1.3 * widget.accessibilityService.textSizeMultiplier,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade800,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: screenHeight * 0.03),

                    // Loading state
                    if (_isProcessing) ...[
                      _buildLoadingCard(screenHeight, screenWidth, baseTextSize),
                    ]
                    // Result state
                    else if (_hasResult && _result != null) ...[
                      _buildResultCard(screenHeight, screenWidth, baseTextSize),
                    ]
                    // Initial state (waiting for picker)
                    else ...[
                      _buildWaitingCard(screenHeight, screenWidth, baseTextSize),
                    ],

                    SizedBox(height: screenHeight * 0.03),

                    // Action buttons (only show after result)
                    if (_hasResult) ...[
                      // Check Another button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _analyzeAnother,
                          icon: Icon(Icons.refresh, size: screenHeight * 0.03),
                          label: Text(
                            'Check Another Message',
                            style: TextStyle(
                              fontSize: baseTextSize * 0.9 * widget.accessibilityService.textSizeMultiplier,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade600,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(56),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      
                      SizedBox(height: screenHeight * 0.015),
                      
                      // Go Home button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _stopTtsAndNavigate(() {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const HomeScreen()),
                              (route) => false,
                            );
                          }),
                          icon: Icon(Icons.home, size: screenHeight * 0.03),
                          label: Text(
                            'Go Home',
                            style: TextStyle(
                              fontSize: baseTextSize * 0.9 * widget.accessibilityService.textSizeMultiplier,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue.shade700,
                            side: BorderSide(color: Colors.blue.shade400, width: 2),
                            minimumSize: const Size.fromHeight(56),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],

                    SizedBox(height: screenHeight * 0.03),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingCard(double screenHeight, double screenWidth, double baseTextSize) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenWidth * 0.06),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.shade300, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade200.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Show the selected screenshot
          if (_screenshotFile != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                _screenshotFile!,
                height: screenHeight * 0.25,
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(height: screenHeight * 0.03),
          ],
          
          SizedBox(
            width: screenHeight * 0.06,
            height: screenHeight * 0.06,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade600),
            ),
          ),
          SizedBox(height: screenHeight * 0.02),
          Text(
            'Analyzing for scams...',
            style: TextStyle(
              fontSize: baseTextSize * 1.1 * widget.accessibilityService.textSizeMultiplier,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: screenHeight * 0.01),
          Text(
            'This will only take a moment',
            style: TextStyle(
              fontSize: baseTextSize * 0.8 * widget.accessibilityService.textSizeMultiplier,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingCard(double screenHeight, double screenWidth, double baseTextSize) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenWidth * 0.06),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.shade300, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade200.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.photo_library,
            size: screenHeight * 0.08,
            color: Colors.blue.shade400,
          ),
          SizedBox(height: screenHeight * 0.02),
          Text(
            'Select a screenshot',
            style: TextStyle(
              fontSize: baseTextSize * 1.1 * widget.accessibilityService.textSizeMultiplier,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: screenHeight * 0.01),
          Text(
            'Choose a photo of the suspicious message',
            style: TextStyle(
              fontSize: baseTextSize * 0.8 * widget.accessibilityService.textSizeMultiplier,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(double screenHeight, double screenWidth, double baseTextSize) {
    // Determine colors and icons based on status
    Color statusColor;
    Color backgroundColor;
    Color borderColor;
    IconData statusIcon;
    String statusTitle;

    switch (_result!.status) {
      case ScamStatus.danger:
        statusColor = Colors.red.shade800;
        backgroundColor = Colors.red.shade50;
        borderColor = Colors.red.shade400;
        statusIcon = Icons.warning_rounded;
        statusTitle = 'DANGER - Likely a Scam!';
        break;
      case ScamStatus.suspicious:
        statusColor = Colors.orange.shade800;
        backgroundColor = Colors.orange.shade50;
        borderColor = Colors.orange.shade400;
        statusIcon = Icons.help_outline_rounded;
        statusTitle = 'SUSPICIOUS - Be Careful';
        break;
      case ScamStatus.safe:
        statusColor = Colors.green.shade800;
        backgroundColor = Colors.green.shade50;
        borderColor = Colors.green.shade400;
        statusIcon = Icons.check_circle_rounded;
        statusTitle = 'SAFE - Looks OK';
        break;
      case ScamStatus.error:
        statusColor = Colors.grey.shade800;
        backgroundColor = Colors.grey.shade100;
        borderColor = Colors.grey.shade400;
        statusIcon = Icons.error_outline_rounded;
        statusTitle = 'Could Not Analyze';
        break;
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenWidth * 0.05),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 3),
        boxShadow: [
          BoxShadow(
            color: borderColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Status icon and title
          Icon(
            statusIcon,
            size: screenHeight * 0.1,
            color: statusColor,
          ),
          SizedBox(height: screenHeight * 0.015),
          Text(
            statusTitle,
            style: TextStyle(
              fontSize: baseTextSize * 1.3 * widget.accessibilityService.textSizeMultiplier,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: screenHeight * 0.025),
          
          // Explanation section
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(screenWidth * 0.04),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Why:',
                  style: TextStyle(
                    fontSize: baseTextSize * 0.9 * widget.accessibilityService.textSizeMultiplier,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                SizedBox(height: screenHeight * 0.008),
                Text(
                  _result!.explanation,
                  style: TextStyle(
                    fontSize: baseTextSize * 1.0 * widget.accessibilityService.textSizeMultiplier,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: screenHeight * 0.015),
          
          // Action section
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(screenWidth * 0.04),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withOpacity(0.5), width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: baseTextSize * 1.2,
                      color: statusColor,
                    ),
                    SizedBox(width: screenWidth * 0.02),
                    Text(
                      'What to do:',
                      style: TextStyle(
                        fontSize: baseTextSize * 0.9 * widget.accessibilityService.textSizeMultiplier,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.008),
                Text(
                  _result!.action,
                  style: TextStyle(
                    fontSize: baseTextSize * 1.0 * widget.accessibilityService.textSizeMultiplier,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          
        ],
      ),
    );
  }
}
