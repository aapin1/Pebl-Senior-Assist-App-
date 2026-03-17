import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../widgets/interactive_learning_card.dart';

/// AI Service for handling OpenAI GPT interactions
/// Specifically designed for senior tech support queries
class AIService {
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';
  static const String _model = 'gpt-4o-mini'; // Better technical knowledge and reasoning
  
  /// Get API key from environment variables
  String get _apiKey => dotenv.env['OPENAI_API_KEY'] ?? '';
  
  /// Check if API key is configured
  bool get isConfigured => _apiKey.isNotEmpty;
  
  /// Senior-focused system prompt for tech support with interactive learning format
  static const String _systemPrompt = '''
You are a friendly, patient, and helpful technology assistant designed to support senior citizens with their Apple devices (iPhone, iPad, Mac). Your main goal is to explain solutions in a way that is simple, clear, and encouraging.

If the user attached a screenshot:
- Look at the screenshot carefully.
- If the question is about the screenshot (for example: "what is this?" or "what does this mean?") then your FIRST step should briefly describe what is on the screen and what it likely indicates.
- Then continue with simple next steps.

IMPORTANT FORMATTING RULES:
- Never use markdown formatting like ### or ** or __ in your responses
- Use simple line breaks and spacing for emphasis instead
- Use CAPITAL LETTERS sparingly for very important words only
- Keep formatting clean and readable without special characters

RESPONSE FORMAT REQUIREMENTS:
You must format your response as a JSON object with a "steps" array. Each step should be a learning card that users can progress through one at a time.

IMPORTANT: You MUST respond with valid JSON in exactly this format:
{
  "steps": [
    {
      "title": "Step 1: [Brief title]",
      "content": "[1-2 sentences maximum with specific instructions. Keep it short and focused.]",
      "question": "[Optional: Simple yes/no or multiple choice question]",
      "options": ["Option 1", "Option 2", "Option 3"],
      "correctAnswer": "Option 1",
      "explanation": "[Why this is correct/important]",
      "requiresConfirmation": true
    }
  ]
}

When creating steps:
- Break complex instructions into 3-5 digestible steps maximum
- CRITICAL: Each step content should be ONLY 1-2 sentences maximum. If you need more explanation, create another step.
- The whole point is to split information into small, digestible chunks - never put 3+ sentences in one step
- Use plain language and avoid technical jargon
- Be very descriptive about button locations and what users should expect to see
- IMPORTANT: The Settings app icon is GRAY with a gear icon (not blue)
- Include specific details like "the gray Settings app with a gear icon" or "the green Phone app that looks like an old telephone"
- Include a confirmation question or check every 1-2 steps
- Make questions simple (yes/no or easy multiple choice)
- Be encouraging and patient in your tone
- NEVER include any text outside the JSON structure

Focus exclusively on Apple devices and iOS/iPadOS/macOS:
- Provide instructions specifically for iPhone and iPad
- Reference iOS interface elements and Apple-specific features
- No need to mention Android or other platforms
- Use Apple terminology (Home button, Control Center, Settings app, etc.)

Example situations you should handle clearly:
Explaining why phone calls may not be going through if a number is blocked, and how to unblock it on iPhone.
Helping someone turn Wi-Fi on and off using iPhone Settings or Control Center.
Showing how to delete an app from their iPhone or iPad home screen.
Guiding them through checking their volume using the side buttons or Settings.
Explaining how to update their iPhone or iPad through the Settings app.

Tone and style guidelines:
Sound warm, kind, and supportive, like a helpful friend.
Never make the user feel embarrassed about not knowing something.
Celebrate small successes: "Great job!" or "You did that perfectly."
Keep answers short but detailed: not overwhelming, but not too vague either.
Assume the user may have vision difficulties — so emphasize clarity, like saying "the blue button near the bottom right."

Remember: Your role is not just to solve the problem, but to make the person feel comfortable and confident using their Apple device. Keep formatting simple and clean without any markdown symbols.
''';

  /// Send a query to OpenAI with conversation history and get structured learning steps
  /// Optional [screenshotPath] allows us to let the model know a screenshot was attached
  Future<List<LearningStep>> getSeniorTechSupportStepsWithHistory(
    String userQuery,
    List<Map<String, String>> conversationHistory, {
    String? screenshotPath,
  }) async {
    final response = await getSeniorTechSupportWithHistory(
      userQuery,
      conversationHistory,
      screenshotPath: screenshotPath,
    );
    return _parseResponseToSteps(response);
  }

  /// Parse AI response JSON into LearningStep objects
  List<LearningStep> _parseResponseToSteps(String response) {
    // Parsing response for learning steps
    
    try {
      // Clean up the response - remove any markdown formatting or extra text
      String cleanResponse = response.trim();
      
      // Remove any text before the JSON starts
      if (cleanResponse.contains('{')) {
        int startIndex = cleanResponse.indexOf('{');
        cleanResponse = cleanResponse.substring(startIndex);
      }
      
      // Remove any text after the JSON ends
      if (cleanResponse.contains('}')) {
        int endIndex = cleanResponse.lastIndexOf('}');
        cleanResponse = cleanResponse.substring(0, endIndex + 1);
      }
      
      // Cleaned JSON for parsing
      
      final jsonResponse = jsonDecode(cleanResponse);
      final stepsJson = jsonResponse['steps'] as List;
      
      // Successfully parsed steps
      
      List<LearningStep> parsedSteps = stepsJson.map((stepJson) {
        // Ensure content is detailed and not just a brief phrase
        String content = stepJson['content'] ?? '';
        if (content.length < 50) {
          // If content is too brief, enhance it with more detail
          content = _enhanceStepContent(stepJson['title'] ?? 'Step', content);
        }
        
        return LearningStep(
          title: stepJson['title'] ?? 'Step',
          content: content,
          question: stepJson['question'],
          options: stepJson['options'] != null 
              ? List<String>.from(stepJson['options']) 
              : null,
          correctAnswer: stepJson['correctAnswer'],
          explanation: stepJson['explanation'],
          requiresConfirmation: stepJson['requiresConfirmation'] ?? true,
        );
      }).toList();
      
      return parsedSteps;
    } catch (e) {
      // JSON parsing failed
      // Raw response fallback
      
      // Fallback: try to extract steps from malformed response
      List<LearningStep> fallbackSteps = [];
      
      // Look for step patterns in the response - more aggressive regex to catch variations
      RegExp stepPattern = RegExp(r'(?:Step\s*(\d+)[:\-\.]?\s*([^\n\r]*?))\s*(.*?)(?=(?:Step\s*\d+)|$)', caseSensitive: false, multiLine: true, dotAll: true);
      Iterable<RegExpMatch> matches = stepPattern.allMatches(response);
      
      if (matches.isNotEmpty) {
        for (RegExpMatch match in matches) {
          String stepNumber = match.group(1) ?? '';
          String stepTitle = match.group(2)?.trim() ?? '';
          String stepContent = match.group(3)?.trim() ?? '';
          
          // If we have a title but no content, the title might be the content
          if (stepContent.isEmpty && stepTitle.isNotEmpty) {
            stepContent = stepTitle;
            stepTitle = '';
          }
          
          // Clean up step content more thoroughly
          stepContent = stepContent
              .replaceAll(RegExp(r'["\[\]{}]'), '')
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();
          
          // Create a proper title if we extracted one
          String finalTitle = stepTitle.isNotEmpty ? stepTitle : 'Step $stepNumber';
          
          // Only add if we have substantial content (reduced threshold)
          if (stepContent.isNotEmpty && stepContent.length > 5) {
            fallbackSteps.add(LearningStep(
              title: finalTitle,
              content: stepContent,
              requiresConfirmation: true,
            ));
          }
        }
      }
      
      // If no steps found with numbered pattern, try alternative patterns
      if (fallbackSteps.isEmpty) {
        // Look for numbered list patterns like "1.", "2.", etc.
        RegExp numberedPattern = RegExp(r'(\d+)[\.\)]\s*([^\n\r]*?)\s*(.*?)(?=\d+[\.\)]|$)', multiLine: true, dotAll: true);
        Iterable<RegExpMatch> numberedMatches = numberedPattern.allMatches(response);
        
        if (numberedMatches.length > 1) {
          for (RegExpMatch match in numberedMatches) {
            String stepNumber = match.group(1) ?? '';
            String possibleTitle = match.group(2)?.trim() ?? '';
            String stepContent = match.group(3)?.trim() ?? '';
            
            // If we have a possible title but no content, the title is likely the content
            if (stepContent.isEmpty && possibleTitle.isNotEmpty) {
              stepContent = possibleTitle;
              possibleTitle = '';
            }
            
            stepContent = stepContent
                .replaceAll(RegExp(r'["\[\]{}]'), '')
                .replaceAll(RegExp(r'\s+'), ' ')
                .trim();
            
            String finalTitle = possibleTitle.isNotEmpty ? possibleTitle : 'Step $stepNumber';
            
            // Reduced threshold for content length
            if (stepContent.isNotEmpty && stepContent.length > 5) {
              fallbackSteps.add(LearningStep(
                title: finalTitle,
                content: stepContent,
                requiresConfirmation: true,
              ));
            }
          }
        }
      }
      
      // If we found steps, return them; otherwise create a single step
      if (fallbackSteps.isNotEmpty) {
        // Returning fallback steps
        return fallbackSteps;
      } else {
        // Better content extraction for single step fallback
        String cleanContent = response
            .replaceAll(RegExp(r'[{}"\[\]]'), '')
            .replaceAll('steps:', '')
            .replaceAll('title:', '')
            .replaceAll('content:', '')
            .replaceAll('requiresConfirmation:', '')
            .replaceAll('true', '')
            .replaceAll('false', '')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
        
        // If content contains multiple steps, try to parse them even if JSON failed
        if (cleanContent.contains('Step ') && cleanContent.length > 50) {
          // Try the fallback step parsing on the cleaned content with improved regex
          RegExp stepPattern = RegExp(r'Step\s*(\d+)[:\-\.]?\s*([^\n\r]*?)\s*(.*?)(?=Step\s*\d+|$)', caseSensitive: false, multiLine: true, dotAll: true);
          Iterable<RegExpMatch> matches = stepPattern.allMatches(cleanContent);
          
          List<LearningStep> extractedSteps = [];
          for (RegExpMatch match in matches) {
            String stepNumber = match.group(1) ?? '';
            String possibleTitle = match.group(2)?.trim() ?? '';
            String stepContent = match.group(3)?.trim() ?? '';
            
            // If we have a possible title but no content, the title is likely the content
            if (stepContent.isEmpty && possibleTitle.isNotEmpty) {
              stepContent = possibleTitle;
              possibleTitle = '';
            }
            
            stepContent = stepContent
                .replaceAll(RegExp(r'["\[\]{}]'), '')
                .replaceAll(RegExp(r'\s+'), ' ')
                .trim();
            
            String finalTitle = possibleTitle.isNotEmpty ? possibleTitle : 'Step $stepNumber';
            
            // Reduced threshold for content length
            if (stepContent.isNotEmpty && stepContent.length > 5) {
              extractedSteps.add(LearningStep(
                title: finalTitle,
                content: stepContent,
                requiresConfirmation: true,
              ));
            }
          }
          
          // If we successfully extracted multiple steps, return them
          if (extractedSteps.length > 1) {
            // Extracted steps from cleaned content
            return extractedSteps;
          }
        }
        
        // If content is still too short or we couldn't extract multiple steps
        if (cleanContent.length < 20) {
          // For first question issues, check if we have a better original response
          if (response.length > cleanContent.length && !response.contains('{"steps"') && response.length > 20) {
            cleanContent = response.trim();
          } else {
            // Provide a comprehensive fallback for first questions
            cleanContent = 'I understand you need help with your question. Let me walk you through this step by step. First, let\'s identify what you\'re trying to accomplish and then I\'ll guide you through each part of the process clearly and simply.';
          }
        }
        
        // Additional check: if we have what looks like a step title in the content, extract it properly
        if (cleanContent.startsWith('Step ') && cleanContent.contains(' ')) {
          RegExp titleExtract = RegExp(r'Step\s*\d+[:\-\.]?\s*([^\n\r]*)', caseSensitive: false);
          RegExpMatch? titleMatch = titleExtract.firstMatch(cleanContent);
          if (titleMatch != null) {
            String extractedTitle = titleMatch.group(1)?.trim() ?? '';
            if (extractedTitle.isNotEmpty) {
              // Remove the step title from content and use it as the actual title
              cleanContent = cleanContent.replaceFirst(titleMatch.group(0) ?? '', '').trim();
              if (cleanContent.isEmpty) {
                cleanContent = extractedTitle;
                extractedTitle = 'Step-by-Step Help';
              }
              return [
                LearningStep(
                  title: extractedTitle,
                  content: cleanContent,
                  requiresConfirmation: true,
                ),
              ];
            }
          }
        }
        
        // Creating single fallback step
        return [
          LearningStep(
            title: 'Step-by-Step Help',
            content: cleanContent,
            requiresConfirmation: true,
          ),
        ];
      }
    }
  }

  /// Enhance brief step content with more detailed instructions
  String _enhanceStepContent(String title, String briefContent) {
    // Add more detailed explanations based on common step types
    if (title.toLowerCase().contains('find') || title.toLowerCase().contains('locate')) {
      return '$briefContent Look carefully at your home screen - you might need to swipe left or right to see all your apps. The app icons are usually arranged in a grid pattern, and each app has a distinctive icon and name underneath it.';
    } else if (title.toLowerCase().contains('open') || title.toLowerCase().contains('tap')) {
      return '$briefContent When you tap an app, you should see it highlight briefly before opening. If nothing happens, try tapping it again - sometimes it takes a moment to respond. The app will open and fill your entire screen.';
    } else if (title.toLowerCase().contains('settings') || title.toLowerCase().contains('preferences')) {
      return '$briefContent The Settings app looks like a gray gear icon. Inside Settings, you\'ll see a list of options you can scroll through. Each option controls different aspects of your device, so take your time to find what you need.';
    } else if (title.toLowerCase().contains('call') || title.toLowerCase().contains('phone')) {
      return '$briefContent The Phone app is essential for making calls on your iPhone. It has several tabs at the bottom including Favorites, Recents, Contacts, Keypad, and Voicemail. You can use any of these to make a call.';
    } else {
      // Generic enhancement for any brief content
      return '$briefContent Take your time with this step and don\'t worry if it takes a few tries. If you get stuck, you can always ask a follow-up question for more help with this specific part.';
    }
  }

  /// Send a query to OpenAI with conversation history for context (legacy method)
  /// Optional [screenshotPath] lets us tell the model a screenshot is present
  Future<String> getSeniorTechSupportWithHistory(
    String userQuery,
    List<Map<String, String>> conversationHistory, {
    String? screenshotPath,
  }) async {
    // Starting AI request with history
    // Conversation history available
    // API key configuration checked
    // API key validated
    
    if (!isConfigured) {
      // No API key configured
      return 'I need an API key to help you. Please check your app settings.';
    }

    // Retry logic for rate limiting
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        // Making request to OpenAI
        
        // Build messages array with system prompt + conversation history
        final List<Map<String, dynamic>> messages = [
          {
            'role': 'system',
            'content': _systemPrompt,
          }
        ];
        
        // Add conversation history (limit to last 10 exchanges to avoid token limits)
        final List<Map<String, String>> recentHistory = conversationHistory.length > 20
            ? conversationHistory.sublist(conversationHistory.length - 20)
            : conversationHistory;

        messages.addAll(recentHistory.map((m) => <String, dynamic>{
              'role': m['role'],
              'content': m['content'],
            }));

        // If a screenshot is attached, try to send it as a multimodal message.
        // If anything fails, fall back to a text-only note so the feature never breaks.
        Map<String, dynamic> userMessage = {
          'role': 'user',
          'content': userQuery,
        };

        if (screenshotPath != null) {
          try {
            final file = File(screenshotPath);
            final exists = await file.exists();
            if (!exists) {
              if (kDebugMode) {
                debugPrint('AIService: screenshot path does not exist: $screenshotPath');
              }
            }

            if (exists) {
              final normalized = userQuery.trim().toLowerCase();
              final isImageIdQuestion = normalized == 'what is it' ||
                  normalized == 'what is this' ||
                  normalized == 'what is that' ||
                  normalized.contains('what am i looking at') ||
                  normalized.contains('what is on my screen') ||
                  normalized.contains('what is this on my screen') ||
                  normalized.contains('what does this mean') ||
                  normalized.contains('explain the screenshot') ||
                  normalized.contains('describe the screenshot');

              final promptText = isImageIdQuestion
                  ? '$userQuery\n\nLook at the attached screenshot. In Step 1, describe what you see on the screen. Then answer my question.'
                  : '$userQuery\n\nPlease use the attached screenshot to answer.';

              // iOS screenshots can be HEIC. If we send HEIC bytes mislabeled as PNG/JPEG,
              // the model will not be able to interpret the image.
              // To make this reliable, we always convert unsupported/large images to JPEG.
              final lower = screenshotPath.toLowerCase();
              final isAlreadySupported =
                  lower.endsWith('.png') || lower.endsWith('.jpg') || lower.endsWith('.jpeg');

              final originalBytes = await file.readAsBytes();

              // Convert to a supported format when needed.
              // If conversion fails for an unsupported format, we must NOT send invalid bytes.
              final _VisionImage? conversion = await _prepareVisionImageBytes(
                screenshotPath: screenshotPath,
                originalBytes: originalBytes,
                isAlreadySupported: isAlreadySupported,
              );

              if (conversion == null) {
                if (kDebugMode) {
                  debugPrint(
                    'AIService: screenshot conversion failed (unsupported format). path=$screenshotPath',
                  );
                }
                userMessage = {
                  'role': 'user',
                  'content':
                      '$promptText\n\nNote: A screenshot was attached, but the app could not upload it.',
                };
              } else {
                if (kDebugMode) {
                  debugPrint(
                    'AIService: screenshot attach path=$screenshotPath supported=$isAlreadySupported original=${originalBytes.length} final=${conversion.bytes.length} mime=${conversion.mime}',
                  );
                }

                // If still too large, gracefully fall back.
                if (conversion.bytes.length > 4 * 1024 * 1024) {
                  if (kDebugMode) {
                    debugPrint(
                      'AIService: screenshot too large after conversion: ${conversion.bytes.length} bytes',
                    );
                  }
                  userMessage = {
                    'role': 'user',
                    'content':
                        '$promptText\n\nNote: The screenshot was too large to upload from the app.',
                  };
                } else {
                  final b64 = base64Encode(conversion.bytes);
                  final dataUrl = 'data:${conversion.mime};base64,$b64';

                  if (kDebugMode) {
                    debugPrint('AIService: sending multimodal message (text + image_url)');
                  }

                  userMessage = {
                    'role': 'user',
                    'content': [
                      {
                        'type': 'text',
                        'text': promptText,
                      },
                      {
                        'type': 'image_url',
                        'image_url': {
                          'url': dataUrl,
                          'detail': 'low',
                        }
                      }
                    ],
                  };
                }
              }
            }
          } catch (_) {
            if (kDebugMode) {
              debugPrint('AIService: exception while attaching screenshot');
            }
            userMessage = {
              'role': 'user',
              'content': '$userQuery\n\nNote: A screenshot was attached.',
            };
          }
        }

        final response = await http.post(
          Uri.parse(_baseUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_apiKey',
          },
          body: jsonEncode({
            'model': _model,
            'messages': [
              ...messages,
              userMessage,
            ],
            'max_tokens': 1500, // Increased to prevent cut-off responses
            'temperature': 0.7, // Balanced creativity and consistency
            'frequency_penalty': 0.0,
            'presence_penalty': 0.0
          }),
        );

        // Response received
        // Processing response
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final aiResponse = data['choices'][0]['message']['content'] as String;
          // AI response successful
          return aiResponse.trim();
        } else if (response.statusCode == 401) {
          // Invalid API key
          return 'Invalid API key. Please check your OpenAI settings.';
        } else if (response.statusCode == 429) {
          // Rate limited, retrying
          final errorBody = jsonDecode(response.body);
          
          // Check if it's a quota exceeded error
          if (errorBody['error']['code'] == 'insufficient_quota') {
            // Return mock steps directly instead of JSON encoding them
            final mockSteps = _getMockStepsWithHistory(userQuery, conversationHistory);
            return jsonEncode({
              'steps': mockSteps.map((step) => {
                'title': step.title,
                'content': step.content,
                'question': step.question,
                'options': step.options,
                'correctAnswer': step.correctAnswer,
                'explanation': step.explanation,
                'requiresConfirmation': step.requiresConfirmation,
              }).toList()
            });
          }
          
          // Regular rate limiting - wait and retry
          if (attempt < 2) {
            await Future.delayed(Duration(seconds: (attempt + 1) * 2));
            continue;
          }
          return 'I\'m getting too many requests right now. Please wait 30 seconds and try again.';
        } else if (response.statusCode == 403) {
          // Billing/permissions issue
          return 'Your OpenAI account needs billing information set up. Please visit platform.openai.com to add a payment method.';
        } else {
          // API error occurred
          return 'I\'m having trouble connecting right now. Error code: ${response.statusCode}. Please try again in a moment.';
        }
      } catch (e) {
        // Exception during request
        if (attempt < 2) {
          await Future.delayed(Duration(seconds: (attempt + 1) * 2));
          continue;
        }
        return 'I\'m having trouble connecting to help you right now. Please check your internet connection and try again.';
      }
    }
    
    return 'I\'m having trouble right now. Please try again in a moment.';
  }

  Future<_VisionImage?> _prepareVisionImageBytes({
    required String screenshotPath,
    required List<int> originalBytes,
    required bool isAlreadySupported,
  }) async {
    final lower = screenshotPath.toLowerCase();
    final isPng = lower.endsWith('.png');

    // Keep small, already-supported images as-is.
    if (isAlreadySupported && originalBytes.length <= 2 * 1024 * 1024) {
      return _VisionImage(
        bytes: originalBytes,
        mime: isPng ? 'image/png' : 'image/jpeg',
      );
    }

    // Convert/compress to JPEG for reliability and size.
    final Uint8List? jpegBytes = await FlutterImageCompress.compressWithFile(
      screenshotPath,
      quality: 85,
      format: CompressFormat.jpeg,
      keepExif: false,
    );

    if (jpegBytes == null) {
      // If it's an unsupported format and we cannot convert it, do not send invalid bytes.
      if (!isAlreadySupported) {
        return null;
      }

      // If it's a supported format but compression failed, fall back to original bytes.
      return _VisionImage(
        bytes: originalBytes,
        mime: isPng ? 'image/png' : 'image/jpeg',
      );
    }

    return _VisionImage(
      bytes: jpegBytes,
      mime: 'image/jpeg',
    );
  }
  /// Send a query to OpenAI and get a senior-friendly response (legacy method)
  Future<String> getSeniorTechSupport(String userQuery) async {
    // Starting AI request for query
    // API key configuration checked
    // API key validated
    
    if (!isConfigured) {
      // No API key configured
      return 'I need an API key to help you. Please check your app settings.';
    }

    // Retry logic for rate limiting
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        // Making request to OpenAI
        final response = await http.post(
          Uri.parse(_baseUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_apiKey',
          },
          body: jsonEncode({
            'model': _model,
            'messages': [
              {
                'role': 'system',
                'content': _systemPrompt,
              },
              {
                'role': 'user',
                'content': 'I need help with: $userQuery',
              },
            ],
            'max_tokens': 1500, // Increased to prevent cut-off responses
            'temperature': 0.7, // Balanced creativity and consistency
            'frequency_penalty': 0.0,
            'presence_penalty': 0.0
          }),
        );

        // Response received
        // Processing response
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final aiResponse = data['choices'][0]['message']['content'] as String;
          // AI response successful
          return aiResponse.trim();
        } else if (response.statusCode == 401) {
          // Invalid API key
          return 'Invalid API key. Please check your OpenAI settings.';
        } else if (response.statusCode == 429) {
          // Rate limited, retrying
          final errorBody = jsonDecode(response.body);
          
          // Check if it's a quota exceeded error
          if (errorBody['error']['code'] == 'insufficient_quota') {
            return _getMockResponse(userQuery);
          }
          
          // Regular rate limiting - wait and retry
          if (attempt < 2) {
            await Future.delayed(Duration(seconds: (attempt + 1) * 2));
            continue;
          }
          return 'I\'m getting too many requests right now. Please wait 30 seconds and try again.';
        } else if (response.statusCode == 403) {
          // Billing/permissions issue
          return 'Your OpenAI account needs billing information set up. Please visit platform.openai.com to add a payment method.';
        } else {
          // API error occurred
          return 'I\'m having trouble connecting right now. Error code: ${response.statusCode}. Please try again in a moment.';
        }
      } catch (e) {
        // Exception during request
        if (attempt < 2) {
          await Future.delayed(Duration(seconds: (attempt + 1) * 2));
          continue;
        }
        return 'I\'m having trouble connecting to help you right now. Please check your internet connection and try again.';
      }
    }
    
    return 'I\'m having trouble right now. Please try again in a moment.';
  }

  /// Get mock learning steps for testing when quota is exceeded
  List<LearningStep> _getMockStepsWithHistory(String userQuery, List<Map<String, String>> conversationHistory) {
    final mockResponse = _getMockResponseWithHistory(userQuery, conversationHistory);
    return _parseResponseToSteps(mockResponse);
  }

  /// Get a mock response with conversation history for testing when quota is exceeded
  String _getMockResponseWithHistory(String userQuery, List<Map<String, String>> conversationHistory) {
    final query = userQuery.toLowerCase();
    
    // Check if this is a follow-up question based on conversation history
    bool isFollowUp = conversationHistory.length > 1;
    String context = '';
    
    if (isFollowUp) {
      // Get context from previous conversation
      final lastUserMessage = conversationHistory.where((msg) => msg['role'] == 'user').lastOrNull;
      final lastAssistantMessage = conversationHistory.where((msg) => msg['role'] == 'assistant').lastOrNull;
      
      if (lastUserMessage != null && lastAssistantMessage != null) {
        context = 'Previous question: ${lastUserMessage['content']}\n';
      }
    }
    
    if (query.contains('call') || query.contains('phone')) {
      if (isFollowUp && query.contains('what') || query.contains('where') || query.contains('find')) {
        return '''{
  "steps": [
    {
      "title": "Step 1: Locate the Phone App",
      "content": "The Phone app is usually on your main home screen. Look for a green icon that looks like an old telephone handset.",
      "question": "Can you see the green phone icon on your home screen?",
      "options": ["Yes, I found it", "No, I don't see it"],
      "correctAnswer": "Yes, I found it",
      "explanation": "Great! If you can't find it, don't worry - we'll help you locate it in the next step.",
      "requiresConfirmation": true
    },
    {
      "title": "Step 2: If You Can't Find It",
      "content": "If you don't see the Phone app, try swiping left or right to check other home screen pages. You can also swipe down from the middle of your screen and type 'Phone' to search for it.",
      "requiresConfirmation": true
    },
    {
      "title": "Step 3: Remember",
      "content": "The Phone app is always there - it can't be deleted since it's built into your iPhone! Once you find it, you're ready to make calls.",
      "question": "Are you ready to learn how to make the actual call?",
      "options": ["Yes, show me how", "I need more help finding the app"],
      "correctAnswer": "Yes, show me how",
      "explanation": "Perfect! Making calls is easy once you know the steps.",
      "requiresConfirmation": true
    }
  ]
}''';
          }
          return '''{
  "steps": [
    {
      "title": "Step 1: Find the Phone App",
      "content": "Look for the green Phone app on your home screen. It looks like an old telephone handset.",
      "question": "Can you see the green phone icon?",
      "options": ["Yes, I see it", "No, I can't find it"],
      "correctAnswer": "Yes, I see it",
      "explanation": "Perfect! The green phone icon is your gateway to making calls.",
      "requiresConfirmation": true
    },
    {
      "title": "Step 2: Open the Phone App",
      "content": "Tap the green Phone app to open it. You'll see a screen with numbers - this is called the keypad.",
      "requiresConfirmation": true
    },
    {
      "title": "Step 3: Dial the Number",
      "content": "Tap the numbers on the keypad to enter the phone number you want to call. Take your time - you can see the numbers appear at the top of the screen.",
      "question": "Have you entered all the numbers for the phone number?",
      "options": ["Yes, all numbers entered", "I made a mistake"],
      "correctAnswer": "Yes, all numbers entered",
      "explanation": "Great! If you made a mistake, you can tap the backspace button to delete numbers.",
      "requiresConfirmation": true
    },
    {
      "title": "Step 4: Make the Call",
      "content": "When you've entered all the numbers, tap the green 'Call' button. Hold the phone to your ear and wait for the person to answer.",
      "requiresConfirmation": true
    }
  ]
}''';
    } else if (query.contains('delete') || query.contains('remove') || query.contains('app')) {
      return '''{
  "steps": [
    {
      "title": "Step 1: Find the App",
      "content": "Look for the app you want to delete on your home screen. It might be on the main screen or you might need to swipe left or right to find it.",
      "question": "Can you see the app you want to delete?",
      "options": ["Yes, I found it", "No, I can't find it"],
      "correctAnswer": "Yes, I found it",
      "explanation": "Great! If you can't find it, try swiping between home screens or using the search feature.",
      "requiresConfirmation": false
    },
    {
      "title": "Step 2: Press and Hold",
      "content": "Press and hold your finger on the app icon for about 2 seconds. Don't tap quickly - hold it down until something happens.",
      "question": "Did the app start to wiggle and show an 'X' button?",
      "options": ["Yes, I see the X", "No, nothing happened"],
      "correctAnswer": "Yes, I see the X",
      "explanation": "Perfect! The wiggling and X button means you're in delete mode. If nothing happened, try holding a bit longer.",
      "requiresConfirmation": false
    },
    {
      "title": "Step 3: Delete the App",
      "content": "Tap the small 'X' button that appeared on the app. A message will ask if you want to delete the app.",
      "requiresConfirmation": true
    },
    {
      "title": "Step 4: Confirm Deletion",
      "content": "Tap 'Delete' to confirm. The app will disappear from your phone. Don't worry - you can always download it again from the App Store if you change your mind!",
      "requiresConfirmation": true
    }
  ]
}''';
    } else {
      return '''{
  "steps": [
    {
      "title": "Understanding Your Question",
      "content": "I understand you need help with: '$userQuery'. I'm here to help you with any tech problems!",
      "requiresConfirmation": true
    },
    {
      "title": "Demo Mode Notice",
      "content": "Right now I'm running in demo mode because your OpenAI account needs billing information set up. This means I can give you basic help, but for detailed personalized assistance, we need to set up billing.",
      "question": "Would you like to know how to set up full AI assistance?",
      "options": ["Yes, show me how", "No, just help with what you can"],
      "correctAnswer": "Yes, show me how",
      "explanation": "Setting up billing will give you access to much more detailed and personalized help.",
      "requiresConfirmation": false
    },
    {
      "title": "Setting Up Full AI Assistance",
      "content": "To get full AI assistance: 1) Go to platform.openai.com, 2) Click Settings then Billing, 3) Add a payment method, 4) Add at least 5 dollars credit. Once that is done, I will be able to give you detailed, personalized help with any tech question!",
      "requiresConfirmation": true
    }
  ]
}''';
    }
  }

  /// Get a mock response for testing when quota is exceeded (legacy method)
  String _getMockResponse(String userQuery) {
    final query = userQuery.toLowerCase();
    
    if (query.contains('call') || query.contains('phone')) {
      return '''Don't worry, I can help you make a phone call! Here's how:

1. Find the green Phone app on your home screen - it looks like an old telephone.
2. Tap the Phone app to open it.
3. You'll see a keypad with numbers. Tap the numbers for the phone number you want to call.
4. When you've entered all the numbers, tap the green "Call" button.
5. Hold the phone to your ear and wait for the person to answer.

Would you like me to explain any of these steps in more detail?

(Note: This is a demo response while your OpenAI billing is being set up)''';
    } else if (query.contains('delete') || query.contains('remove') || query.contains('app')) {
      return '''Don't worry, I can help you delete an app! Here's how:

1. Find the app you want to delete on your home screen.
2. Press and hold your finger on the app icon for about 2 seconds.
3. You'll see the app start to wiggle and a small "X" will appear.
4. Tap the "X" button on the app you want to delete.
5. A message will ask "Delete [App Name]?" - tap "Delete" to confirm.

The app is now removed from your phone!

Would you like me to explain any of these steps in more detail?

(Note: This is a demo response while your OpenAI billing is being set up)''';
    } else {
      return '''I understand you need help with: "$userQuery"

I'm here to help you with any tech problems! Right now I'm running in demo mode because your OpenAI account needs billing information set up.

To get full AI assistance:
1. Go to platform.openai.com
2. Click "Settings" then "Billing"
3. Add a payment method
4. Add at least \$5 credit

Once that's done, I'll be able to give you detailed, personalized help with any tech question!

(Note: This is a demo response while your OpenAI billing is being set up)''';
    }
  }

  /// Get follow-up answer for additional questions about a step
  Future<String> getFollowUpAnswer(String context) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${dotenv.env['OPENAI_API_KEY']}',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a helpful tech support assistant for seniors. Provide clear, simple answers to follow-up questions about technology steps. Keep responses concise but helpful. Answer in the context of the current step the user is working on.'
            },
            {
              'role': 'user',
              'content': context,
            }
          ],
          'max_tokens': 300,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].toString().trim();
      } else {
        throw Exception('Failed to get follow-up answer: ${response.statusCode}');
      }
    } catch (e) {
      // Error getting follow-up answer
      return 'I apologize, but I\'m having trouble processing your question right now. Please try asking again.';
    }
  }

  /// Test the AI service with a simple query
  Future<String> testConnection() async {
    return await getSeniorTechSupport('How do I make a phone call?');
  }

  /// Scam-specific system prompt for analyzing suspicious messages
  static const String _scamAnalysisPrompt = '''
You are Pebl, a friendly and protective AI assistant for seniors. The user has uploaded an image of a text message, email, or popup. You must determine if it is a scam/phishing attempt. Be brutally honest. Check for spelling inconsistencies, anything unnatural or weird.

Format your response exactly like this:
STATUS: [Respond only with SAFE, DANGER, or SUSPICIOUS]
EXPLANATION: [Explain why in 1-2 very simple, jargon-free sentences. Use a reassuring tone.]
ACTION: [Tell them exactly what to do next in 1 simple step, e.g., 'Delete this message and do not click any links.']

Important guidelines:
- DANGER: Clear scam indicators like fake urgency, requests for money/gift cards, suspicious links, impersonation of banks/government/tech support, lottery winnings, threats
- SUSPICIOUS: Some warning signs but not definitive - unusual sender, slight spelling errors, requests for personal info
- SAFE: Legitimate message from known contacts or verified businesses with no red flags

Always err on the side of caution to protect seniors. If in doubt, mark as SUSPICIOUS.
''';

  /// Analyze a screenshot for scam/phishing indicators
  /// Returns a ScamAnalysisResult with status, explanation, and action
  Future<ScamAnalysisResult> analyzeScamScreenshot(String screenshotPath) async {
    if (!isConfigured) {
      return ScamAnalysisResult(
        status: ScamStatus.error,
        explanation: 'I need an API key to help you. Please check your app settings.',
        action: 'Set up your API key in the app settings.',
      );
    }

    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        final file = File(screenshotPath);
        final exists = await file.exists();
        
        if (!exists) {
          return ScamAnalysisResult(
            status: ScamStatus.error,
            explanation: 'Could not find the screenshot file.',
            action: 'Please try selecting the image again.',
          );
        }

        final lower = screenshotPath.toLowerCase();
        final isAlreadySupported =
            lower.endsWith('.png') || lower.endsWith('.jpg') || lower.endsWith('.jpeg');

        final originalBytes = await file.readAsBytes();

        final _VisionImage? conversion = await _prepareVisionImageBytes(
          screenshotPath: screenshotPath,
          originalBytes: originalBytes,
          isAlreadySupported: isAlreadySupported,
        );

        if (conversion == null) {
          return ScamAnalysisResult(
            status: ScamStatus.error,
            explanation: 'Could not process this image format.',
            action: 'Please try with a different screenshot.',
          );
        }

        if (conversion.bytes.length > 4 * 1024 * 1024) {
          return ScamAnalysisResult(
            status: ScamStatus.error,
            explanation: 'The screenshot is too large to analyze.',
            action: 'Please try with a smaller image.',
          );
        }

        final b64 = base64Encode(conversion.bytes);
        final dataUrl = 'data:${conversion.mime};base64,$b64';

        final userMessage = {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text': 'Please analyze this screenshot and determine if it is a scam or phishing attempt.',
            },
            {
              'type': 'image_url',
              'image_url': {
                'url': dataUrl,
                'detail': 'low',
              }
            }
          ],
        };

        final response = await http.post(
          Uri.parse(_baseUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_apiKey',
          },
          body: jsonEncode({
            'model': _model,
            'messages': [
              {
                'role': 'system',
                'content': _scamAnalysisPrompt,
              },
              userMessage,
            ],
            'max_tokens': 500,
            'temperature': 0.3,
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final aiResponse = data['choices'][0]['message']['content'] as String;
          return _parseScamResponse(aiResponse.trim());
        } else if (response.statusCode == 429) {
          if (attempt < 2) {
            await Future.delayed(Duration(seconds: (attempt + 1) * 2));
            continue;
          }
          return ScamAnalysisResult(
            status: ScamStatus.error,
            explanation: 'Too many requests right now.',
            action: 'Please wait 30 seconds and try again.',
          );
        } else {
          return ScamAnalysisResult(
            status: ScamStatus.error,
            explanation: 'Having trouble connecting right now.',
            action: 'Please try again in a moment.',
          );
        }
      } catch (e) {
        if (attempt < 2) {
          await Future.delayed(Duration(seconds: (attempt + 1) * 2));
          continue;
        }
        return ScamAnalysisResult(
          status: ScamStatus.error,
          explanation: 'Having trouble connecting to help you.',
          action: 'Please check your internet connection and try again.',
        );
      }
    }

    return ScamAnalysisResult(
      status: ScamStatus.error,
      explanation: 'Having trouble right now.',
      action: 'Please try again in a moment.',
    );
  }

  /// Parse the AI response into a ScamAnalysisResult
  ScamAnalysisResult _parseScamResponse(String response) {
    try {
      String status = '';
      String explanation = '';
      String action = '';

      final lines = response.split('\n');
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.toUpperCase().startsWith('STATUS:')) {
          status = trimmed.substring(7).trim().toUpperCase();
        } else if (trimmed.toUpperCase().startsWith('EXPLANATION:')) {
          explanation = trimmed.substring(12).trim();
        } else if (trimmed.toUpperCase().startsWith('ACTION:')) {
          action = trimmed.substring(7).trim();
        }
      }

      ScamStatus scamStatus;
      if (status.contains('DANGER')) {
        scamStatus = ScamStatus.danger;
      } else if (status.contains('SUSPICIOUS')) {
        scamStatus = ScamStatus.suspicious;
      } else if (status.contains('SAFE')) {
        scamStatus = ScamStatus.safe;
      } else {
        scamStatus = ScamStatus.suspicious;
      }

      return ScamAnalysisResult(
        status: scamStatus,
        explanation: explanation.isNotEmpty ? explanation : 'Unable to determine the safety of this message.',
        action: action.isNotEmpty ? action : 'When in doubt, do not click any links or share personal information.',
      );
    } catch (e) {
      return ScamAnalysisResult(
        status: ScamStatus.suspicious,
        explanation: 'Could not fully analyze this message.',
        action: 'When in doubt, do not click any links or share personal information.',
      );
    }
  }
}

/// Enum for scam analysis status
enum ScamStatus {
  safe,
  suspicious,
  danger,
  error,
}

/// Result of scam analysis
class ScamAnalysisResult {
  final ScamStatus status;
  final String explanation;
  final String action;

  ScamAnalysisResult({
    required this.status,
    required this.explanation,
    required this.action,
  });
}

class _VisionImage {
  final List<int> bytes;
  final String mime;

  _VisionImage({
    required this.bytes,
    required this.mime,
  });
}
