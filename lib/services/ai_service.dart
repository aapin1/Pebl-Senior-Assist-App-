import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
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

IMPORTANT FORMATTING RULES:
- Never use markdown formatting like ### or ** or __ in your responses
- Use simple line breaks and spacing for emphasis instead
- Use CAPITAL LETTERS sparingly for very important words only
- Keep formatting clean and readable without special characters

RESPONSE FORMAT REQUIREMENTS:
You must format your response as a JSON object with a "steps" array. Each step should be a learning card that users can progress through one at a time.

Structure your response as:
{
  "steps": [
    {
      "title": "Step 1: [Brief title]",
      "content": "[Detailed explanation in simple language]",
      "question": "[Optional: Simple yes/no or multiple choice question]",
      "options": ["Option 1", "Option 2", "Option 3"] // Only if question is multiple choice
      "correctAnswer": "Option 1", // Only if question has options
      "explanation": "[Why this is correct/important]", // Only if question exists
      "requiresConfirmation": true/false // true if user should confirm they completed the step
    }
  ]
}

When creating steps:
- Break complex instructions into 3-5 digestible steps maximum
- Use plain language and avoid technical jargon
- Be descriptive about button locations and what users should expect to see
- Include a confirmation question or check every 1-2 steps
- Make questions simple (yes/no or easy multiple choice)
- Be encouraging and patient in your tone

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
  Future<List<LearningStep>> getSeniorTechSupportStepsWithHistory(String userQuery, List<Map<String, String>> conversationHistory) async {
    final response = await getSeniorTechSupportWithHistory(userQuery, conversationHistory);
    return _parseResponseToSteps(response);
  }

  /// Parse AI response JSON into LearningStep objects
  List<LearningStep> _parseResponseToSteps(String response) {
    print('DEBUG: Parsing response: ${response.substring(0, response.length > 200 ? 200 : response.length)}...');
    
    try {
      // Clean up the response - remove any markdown formatting or extra text
      String cleanResponse = response.trim();
      
      // Find JSON content between curly braces
      int startIndex = cleanResponse.indexOf('{');
      int endIndex = cleanResponse.lastIndexOf('}');
      
      if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
        cleanResponse = cleanResponse.substring(startIndex, endIndex + 1);
        print('DEBUG: Cleaned JSON: ${cleanResponse.substring(0, cleanResponse.length > 200 ? 200 : cleanResponse.length)}...');
      }
      
      final jsonResponse = jsonDecode(cleanResponse);
      final stepsJson = jsonResponse['steps'] as List;
      
      print('DEBUG: Successfully parsed ${stepsJson.length} steps');
      
      return stepsJson.map((stepJson) {
        return LearningStep(
          title: stepJson['title'] ?? 'Step',
          content: stepJson['content'] ?? '',
          question: stepJson['question'],
          options: stepJson['options'] != null 
              ? List<String>.from(stepJson['options']) 
              : null,
          correctAnswer: stepJson['correctAnswer'],
          explanation: stepJson['explanation'],
          requiresConfirmation: stepJson['requiresConfirmation'] ?? true,
        );
      }).toList();
    } catch (e) {
      print('DEBUG: JSON parsing failed: $e');
      print('DEBUG: Raw response: $response');
      
      // Fallback: create a single step from the raw response
      return [
        LearningStep(
          title: 'Help with your question',
          content: 'I\'m having trouble formatting my response right now. Let me try to help you anyway: ${response.replaceAll(RegExp(r'[{}"\[\]]'), '').replaceAll('steps:', '').replaceAll('title:', '').replaceAll('content:', '').trim()}',
          requiresConfirmation: true,
        ),
      ];
    }
  }

  /// Send a query to OpenAI with conversation history for context (legacy method)
  Future<String> getSeniorTechSupportWithHistory(String userQuery, List<Map<String, String>> conversationHistory) async {
    print('DEBUG: Starting AI request with history for query: $userQuery');
    print('DEBUG: Conversation history length: ${conversationHistory.length}');
    print('DEBUG: API key configured: $isConfigured');
    print('DEBUG: API key length: ${_apiKey.length}');
    
    if (!isConfigured) {
      print('DEBUG: No API key found');
      return 'I need an API key to help you. Please check your app settings.';
    }

    // Retry logic for rate limiting
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        print('DEBUG: Attempt ${attempt + 1} - Making request to OpenAI');
        
        // Build messages array with system prompt + conversation history
        List<Map<String, String>> messages = [
          {
            'role': 'system',
            'content': _systemPrompt,
          }
        ];
        
        // Add conversation history (limit to last 10 exchanges to avoid token limits)
        if (conversationHistory.length > 20) {
          messages.addAll(conversationHistory.sublist(conversationHistory.length - 20));
        } else {
          messages.addAll(conversationHistory);
        }
        
        final response = await http.post(
          Uri.parse(_baseUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_apiKey',
          },
          body: jsonEncode({
            'model': _model,
            'messages': messages,
            'max_tokens': 500, // Allow more detailed explanations for seniors
            'temperature': 0.7, // Balanced creativity and consistency
            'frequency_penalty': 0.0,
            'presence_penalty': 0.0
          }),
        );

        print('DEBUG: Response status code: ${response.statusCode}');
        print('DEBUG: Response body: ${response.body}');
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final aiResponse = data['choices'][0]['message']['content'] as String;
          print('DEBUG: Successfully got AI response');
          return aiResponse.trim();
        } else if (response.statusCode == 401) {
          print('DEBUG: Invalid API key error');
          return 'Invalid API key. Please check your OpenAI settings.';
        } else if (response.statusCode == 429) {
          print('DEBUG: Rate limited - attempt ${attempt + 1}');
          final errorBody = jsonDecode(response.body);
          
          // Check if it's a quota exceeded error
          if (errorBody['error']['code'] == 'insufficient_quota') {
            return jsonEncode({
              'steps': _getMockStepsWithHistory(userQuery, conversationHistory)
                  .map((step) => {
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
          print('DEBUG: Billing/permissions error');
          return 'Your OpenAI account needs billing information set up. Please visit platform.openai.com to add a payment method.';
        } else {
          print('DEBUG: Other API error: ${response.statusCode} - ${response.body}');
          return 'I\'m having trouble connecting right now. Error code: ${response.statusCode}. Please try again in a moment.';
        }
      } catch (e) {
        print('DEBUG: Exception caught: $e');
        if (attempt < 2) {
          await Future.delayed(Duration(seconds: (attempt + 1) * 2));
          continue;
        }
        return 'I\'m having trouble connecting to help you right now. Please check your internet connection and try again.';
      }
    }
    
    return 'I\'m having trouble right now. Please try again in a moment.';
  }

  /// Send a query to OpenAI and get a senior-friendly response (legacy method)
  Future<String> getSeniorTechSupport(String userQuery) async {
    print('DEBUG: Starting AI request for query: $userQuery');
    print('DEBUG: API key configured: $isConfigured');
    print('DEBUG: API key length: ${_apiKey.length}');
    
    if (!isConfigured) {
      print('DEBUG: No API key found');
      return 'I need an API key to help you. Please check your app settings.';
    }

    // Retry logic for rate limiting
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        print('DEBUG: Attempt ${attempt + 1} - Making request to OpenAI');
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
            'max_tokens': 500, // Allow more detailed explanations for seniors
            'temperature': 0.7, // Balanced creativity and consistency
            'frequency_penalty': 0.0,
            'presence_penalty': 0.0
          }),
        );

        print('DEBUG: Response status code: ${response.statusCode}');
        print('DEBUG: Response body: ${response.body}');
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final aiResponse = data['choices'][0]['message']['content'] as String;
          print('DEBUG: Successfully got AI response');
          return aiResponse.trim();
        } else if (response.statusCode == 401) {
          print('DEBUG: Invalid API key error');
          return 'Invalid API key. Please check your OpenAI settings.';
        } else if (response.statusCode == 429) {
          print('DEBUG: Rate limited - attempt ${attempt + 1}');
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
          print('DEBUG: Billing/permissions error');
          return 'Your OpenAI account needs billing information set up. Please visit platform.openai.com to add a payment method.';
        } else {
          print('DEBUG: Other API error: ${response.statusCode} - ${response.body}');
          return 'I\'m having trouble connecting right now. Error code: ${response.statusCode}. Please try again in a moment.';
        }
      } catch (e) {
        print('DEBUG: Exception caught: $e');
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

  /// Test the AI service with a simple query
  Future<String> testConnection() async {
    return await getSeniorTechSupport('How do I make a phone call?');
  }
}
