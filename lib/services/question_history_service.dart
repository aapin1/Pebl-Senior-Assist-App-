import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/interactive_learning_card.dart';

/// Service for managing question history using local device storage
/// Uses iOS sandbox storage via shared_preferences - no accounts needed
class QuestionHistoryService {
  static const String _historyKey = 'pebl_question_history';
  static const int _maxHistoryItems = 10;

  /// Singleton instance
  static final QuestionHistoryService _instance = QuestionHistoryService._internal();
  factory QuestionHistoryService() => _instance;
  QuestionHistoryService._internal();

  /// Save a question and its response to history
  /// Automatically limits to most recent 10 items
  Future<bool> saveQuestion({
    required String userQuestion,
    required List<LearningStep> steps,
    String? deepLink,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing history
      final List<SavedQuestion> history = await getHistory();
      
      // Create new saved question
      final newQuestion = SavedQuestion(
        userQuestion: userQuestion,
        steps: steps,
        deepLink: deepLink,
        timestamp: DateTime.now(),
      );
      
      // Add to beginning of list (most recent first)
      history.insert(0, newQuestion);
      
      // Limit to max items
      if (history.length > _maxHistoryItems) {
        history.removeRange(_maxHistoryItems, history.length);
      }
      
      // Convert to JSON and save
      final jsonList = history.map((q) => q.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      
      await prefs.setString(_historyKey, jsonString);
      
      if (kDebugMode) {
        debugPrint('QuestionHistoryService: Saved question. History count: ${history.length}');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('QuestionHistoryService: Error saving question: $e');
      }
      return false;
    }
  }

  /// Get all saved questions from history
  /// Returns empty list if no history exists
  Future<List<SavedQuestion>> getHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_historyKey);
      
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      final history = jsonList
          .map((json) => SavedQuestion.fromJson(json as Map<String, dynamic>))
          .toList();
      
      if (kDebugMode) {
        debugPrint('QuestionHistoryService: Loaded ${history.length} questions from history');
      }
      
      return history;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('QuestionHistoryService: Error loading history: $e');
      }
      return [];
    }
  }

  /// Clear all history (for testing or user request)
  Future<bool> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
      
      if (kDebugMode) {
        debugPrint('QuestionHistoryService: History cleared');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('QuestionHistoryService: Error clearing history: $e');
      }
      return false;
    }
  }

  /// Check if history is empty
  Future<bool> hasHistory() async {
    final history = await getHistory();
    return history.isNotEmpty;
  }
}

/// Model for a saved question with its response
class SavedQuestion {
  final String userQuestion;
  final List<LearningStep> steps;
  final String? deepLink;
  final DateTime timestamp;

  SavedQuestion({
    required this.userQuestion,
    required this.steps,
    this.deepLink,
    required this.timestamp,
  });

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'userQuestion': userQuestion,
      'steps': steps.map((step) => _stepToJson(step)).toList(),
      'deepLink': deepLink,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Create from JSON
  factory SavedQuestion.fromJson(Map<String, dynamic> json) {
    final stepsJson = json['steps'] as List<dynamic>;
    final steps = stepsJson.map((stepJson) => _stepFromJson(stepJson as Map<String, dynamic>)).toList();
    
    return SavedQuestion(
      userQuestion: json['userQuestion'] as String,
      steps: steps,
      deepLink: json['deepLink'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Convert LearningStep to JSON
  static Map<String, dynamic> _stepToJson(LearningStep step) {
    return {
      'title': step.title,
      'content': step.content,
      'question': step.question,
      'options': step.options,
      'correctAnswer': step.correctAnswer,
      'explanation': step.explanation,
      'requiresConfirmation': step.requiresConfirmation,
    };
  }

  /// Create LearningStep from JSON
  static LearningStep _stepFromJson(Map<String, dynamic> json) {
    return LearningStep(
      title: json['title'] as String,
      content: json['content'] as String,
      question: json['question'] as String?,
      options: json['options'] != null 
          ? List<String>.from(json['options'] as List) 
          : null,
      correctAnswer: json['correctAnswer'] as String?,
      explanation: json['explanation'] as String?,
      requiresConfirmation: json['requiresConfirmation'] as bool? ?? false,
    );
  }

  /// Get a truncated preview of the question for display
  String get questionPreview {
    if (userQuestion.length <= 60) {
      return userQuestion;
    }
    return '${userQuestion.substring(0, 57)}...';
  }

  /// Get formatted date string for display
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${timestamp.month}/${timestamp.day}/${timestamp.year}';
    }
  }
}
