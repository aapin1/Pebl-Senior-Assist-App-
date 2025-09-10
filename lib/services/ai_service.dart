import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// AI Service for handling OpenAI GPT interactions
/// Specifically designed for senior tech support queries
class AIService {
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';
  static const String _model = 'gpt-4o-mini'; // Better technical knowledge and reasoning
  
  /// Get API key from environment variables
  String get _apiKey => dotenv.env['OPENAI_API_KEY'] ?? '';
  
  /// Check if API key is configured
  bool get isConfigured => _apiKey.isNotEmpty;
  
  /// Senior-focused system prompt for tech support
  static const String _systemPrompt = '''
You are a friendly, patient, and helpful technology assistant designed to support senior citizens with their Apple devices (iPhone, iPad, Mac). Your main goal is to explain solutions in a way that is simple, clear, and encouraging.

IMPORTANT FORMATTING RULES:
- Never use markdown formatting like ### or ** or __ in your responses
- Use simple line breaks and spacing for emphasis instead
- Use CAPITAL LETTERS sparingly for very important words only
- Keep formatting clean and readable without special characters

When answering:
Use plain language — avoid technical jargon unless absolutely necessary. If you must use a technical term (like "Wi-Fi"), explain what it means in simple words.
Be step-by-step — break instructions into small, numbered steps that are easy to follow.
Be descriptive — explain what buttons look like, where they are on the screen, and what the user should expect to see.
Be reassuring — remind the user that it's normal to have these problems and they're doing great following along.
Be patient — never rush; assume the user may need a little extra explanation.
Check understanding — when appropriate, ask simple confirmation questions like: "Did you see the button I mentioned?" or "Does that make sense so far?"

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

  /// Send a query to OpenAI with conversation history for context
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
            return _getMockResponseWithHistory(userQuery, conversationHistory);
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
        return '''${context.isNotEmpty ? 'Following up on your phone call question:\n\n' : ''}The Phone app is usually on your main home screen. Here's how to find it:

1. Look for a green icon that looks like an old telephone handset.
2. If you don't see it, swipe left or right to check other home screen pages.
3. You can also swipe down from the middle of your screen and type "Phone" to search for it.

The Phone app is always there - it can't be deleted since it's built into your iPhone!

Would you like me to walk you through making the actual call once you find it?''';
      }
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
      return '''${context.isNotEmpty ? 'Following up on our conversation:\n\n' : ''}I understand you need help with: "$userQuery"

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
