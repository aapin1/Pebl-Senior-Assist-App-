import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/accessibility_service.dart';
import '../services/question_history_service.dart';
import '../widgets/interactive_learning_card.dart';

/// Screen displaying the user's past questions history
/// Allows seniors to revisit previous answers without making new API calls
class PastQuestionsScreen extends StatefulWidget {
  final AccessibilityService accessibilityService;

  const PastQuestionsScreen({
    super.key,
    required this.accessibilityService,
  });

  @override
  State<PastQuestionsScreen> createState() => _PastQuestionsScreenState();
}

class _PastQuestionsScreenState extends State<PastQuestionsScreen> {
  final QuestionHistoryService _historyService = QuestionHistoryService();
  final FlutterTts _flutterTts = FlutterTts();
  
  List<SavedQuestion> _history = [];
  bool _isLoading = true;
  SavedQuestion? _selectedQuestion;
  bool _isViewingAnswer = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _initTts();
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  void _initTts() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(0.8);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _loadHistory() async {
    final history = await _historyService.getHistory();
    setState(() {
      _history = history;
      _isLoading = false;
    });
  }

  void _viewAnswer(SavedQuestion question) {
    _flutterTts.stop();
    setState(() {
      _selectedQuestion = question;
      _isViewingAnswer = true;
    });
    
    // Read first step aloud if audio is enabled
    if (widget.accessibilityService.isAudioEnabled && question.steps.isNotEmpty) {
      _flutterTts.speak(question.steps.first.content);
    }
  }

  void _backToList() {
    _flutterTts.stop();
    setState(() {
      _selectedQuestion = null;
      _isViewingAnswer = false;
    });
  }

  Future<void> _speakText(String text) async {
    await _flutterTts.stop();
    await _flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final baseTextSize = screenHeight * 0.02;

    return AnimatedBuilder(
      animation: widget.accessibilityService,
      builder: (context, child) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.purple.shade100,
                  Colors.purple.shade50,
                  Colors.white,
                ],
              ),
            ),
            child: SafeArea(
              child: _isViewingAnswer && _selectedQuestion != null
                  ? _buildAnswerView(screenHeight, screenWidth, baseTextSize)
                  : _buildHistoryList(screenHeight, screenWidth, baseTextSize),
            ),
          ),
        );
      },
    );
  }

  /// Build the history list view
  Widget _buildHistoryList(double screenHeight, double screenWidth, double baseTextSize) {
    return Column(
      children: [
        // Header with back button
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: screenHeight * 0.015,
          ),
          child: Row(
            children: [
              // Back button
              SizedBox(
                height: 60,
                width: 60,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.purple.shade700,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: Icon(
                    Icons.arrow_back,
                    size: 28,
                    color: Colors.purple.shade700,
                  ),
                ),
              ),
              SizedBox(width: screenWidth * 0.03),
              // Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Past Questions',
                      style: TextStyle(
                        fontSize: baseTextSize * 1.3 * widget.accessibilityService.textSizeMultiplier,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade800,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Tap any question to see the answer',
                      style: TextStyle(
                        fontSize: baseTextSize * 0.75 * widget.accessibilityService.textSizeMultiplier,
                        color: Colors.purple.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Content
        Expanded(
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: Colors.purple.shade600,
                  ),
                )
              : _history.isEmpty
                  ? _buildEmptyState(screenHeight, screenWidth, baseTextSize)
                  : _buildQuestionsList(screenHeight, screenWidth, baseTextSize),
        ),
      ],
    );
  }

  /// Build empty state when no history exists
  Widget _buildEmptyState(double screenHeight, double screenWidth, double baseTextSize) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.08),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: screenHeight * 0.12,
              color: Colors.purple.shade300,
            ),
            SizedBox(height: screenHeight * 0.03),
            Text(
              "You haven't asked any questions yet!",
              style: TextStyle(
                fontSize: baseTextSize * 1.2 * widget.accessibilityService.textSizeMultiplier,
                fontWeight: FontWeight.bold,
                color: Colors.purple.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: screenHeight * 0.015),
            Text(
              'When you ask Pebl a question, it will be saved here so you can look back at the answers anytime.',
              style: TextStyle(
                fontSize: baseTextSize * 0.9 * widget.accessibilityService.textSizeMultiplier,
                color: Colors.purple.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: screenHeight * 0.04),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade600,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  minimumSize: const Size.fromHeight(56),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.arrow_back, size: 28),
                label: Text(
                  'Go Back Home',
                  style: TextStyle(
                    fontSize: baseTextSize * 1.1 * widget.accessibilityService.textSizeMultiplier,
                    fontWeight: FontWeight.bold,
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
    );
  }

  /// Build the list of past questions
  Widget _buildQuestionsList(double screenHeight, double screenWidth, double baseTextSize) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenHeight * 0.01,
      ),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final question = _history[index];
        return Padding(
          padding: EdgeInsets.only(bottom: screenHeight * 0.015),
          child: _buildQuestionCard(question, screenHeight, screenWidth, baseTextSize),
        );
      },
    );
  }

  /// Build a single question card
  Widget _buildQuestionCard(SavedQuestion question, double screenHeight, double screenWidth, double baseTextSize) {
    return InkWell(
      onTap: () => _viewAnswer(question),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        constraints: BoxConstraints(minHeight: 100),
        padding: EdgeInsets.all(screenWidth * 0.04),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.purple.shade200,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.shade100.withOpacity(0.5),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Question icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.purple.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.help_outline,
                size: 28,
                color: Colors.purple.shade600,
              ),
            ),
            SizedBox(width: screenWidth * 0.03),
            // Question text and date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    question.questionPreview,
                    style: TextStyle(
                      fontSize: baseTextSize * widget.accessibilityService.textSizeMultiplier,
                      fontWeight: FontWeight.w600,
                      color: Colors.purple.shade800,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    question.formattedDate,
                    style: TextStyle(
                      fontSize: baseTextSize * 0.75 * widget.accessibilityService.textSizeMultiplier,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            // Arrow indicator
            Icon(
              Icons.chevron_right,
              size: 32,
              color: Colors.purple.shade400,
            ),
          ],
        ),
      ),
    );
  }

  /// Build the answer view when a question is selected
  Widget _buildAnswerView(double screenHeight, double screenWidth, double baseTextSize) {
    return Column(
      children: [
        // Header with back button
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: screenHeight * 0.015,
          ),
          child: Row(
            children: [
              // Back button
              SizedBox(
                height: 60,
                width: 60,
                child: ElevatedButton(
                  onPressed: _backToList,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.purple.shade700,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: Icon(
                    Icons.arrow_back,
                    size: 28,
                    color: Colors.purple.shade700,
                  ),
                ),
              ),
              SizedBox(width: screenWidth * 0.03),
              // Title showing the question
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Question',
                      style: TextStyle(
                        fontSize: baseTextSize * 0.8 * widget.accessibilityService.textSizeMultiplier,
                        color: Colors.purple.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _selectedQuestion!.questionPreview,
                      style: TextStyle(
                        fontSize: baseTextSize * widget.accessibilityService.textSizeMultiplier,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade800,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Learning cards with saved steps
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.04,
              vertical: screenHeight * 0.01,
            ),
            child: InteractiveLearningCard(
              steps: _selectedQuestion!.steps,
              onComplete: (completed) {
                // Just go back to list when completed
                _backToList();
              },
              accessibilityService: widget.accessibilityService,
              onStepRead: (text) {
                if (widget.accessibilityService.isAudioEnabled) {
                  _speakText(text);
                }
              },
              deepLink: _selectedQuestion!.deepLink,
              userQuestion: _selectedQuestion!.userQuestion,
            ),
          ),
        ),
      ],
    );
  }
}
