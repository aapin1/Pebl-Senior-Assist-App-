import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/home_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/accessibility_service.dart';

/// Main entry point of the Senior Assist application
/// This app is designed with accessibility in mind for senior users
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  runApp(const SeniorAssistApp());
}

/// Root widget of the Senior Assist application
/// Configures the overall app theme and navigation
class SeniorAssistApp extends StatefulWidget {
  const SeniorAssistApp({super.key});

  @override
  State<SeniorAssistApp> createState() => _SeniorAssistAppState();
}

class _SeniorAssistAppState extends State<SeniorAssistApp> {
  final AccessibilityService _accessibilityService = AccessibilityService();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _accessibilityService.initialize();
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        debugShowCheckedModeBanner: false,
      );
    }

    return AnimatedBuilder(
      animation: _accessibilityService,
      builder: (context, child) {
        return MaterialApp(
          title: 'Senior Assist',
          debugShowCheckedModeBanner: false,
          
          // Dynamic theme based on accessibility settings
          theme: ThemeData(
            colorScheme: _accessibilityService.getColorScheme(Brightness.light),
            textTheme: _accessibilityService.getTextTheme(),
            
            // Ensure buttons are large and accessible
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                minimumSize: Size(200 * _accessibilityService.textSizeMultiplier, 80), // Dynamic button size
                textStyle: TextStyle(fontSize: 18 * _accessibilityService.textSizeMultiplier),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            
            useMaterial3: true,
          ),
          
          // Determine initial route based on onboarding status
          home: _getInitialScreen(),
        );
      },
    );
  }

  Widget _getInitialScreen() {
    // Start with welcome screen for first-time users
    // After setup is complete, users go directly to home screen
    if (!_accessibilityService.hasCompletedAccessibilitySetup) {
      return const WelcomeScreen();
    }
    return const HomeScreen();
  }
}
