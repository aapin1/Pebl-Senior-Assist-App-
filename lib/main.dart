import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/home_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/accessibility_service.dart';
import 'services/ad_service.dart';

/// Main entry point of the Pebl application
/// This app is designed with accessibility in mind for senior users
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  runApp(const PeblApp());
}

/// Root widget of the Pebl application
/// Configures the overall app theme and navigation
class PeblApp extends StatefulWidget {
  const PeblApp({super.key});

  @override
  State<PeblApp> createState() => _PeblAppState();
}

class _PeblAppState extends State<PeblApp> {
  final AccessibilityService _accessibilityService = AccessibilityService();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Initialize accessibility service first
    await _accessibilityService.initialize();
    
    // Initialize ad service for monetization
    await AdService().initialize();
    
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
          title: 'Pebl',
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
    // Go directly to home screen - no setup required
    // Users can change settings anytime from the Settings button
    return const HomeScreen();
  }
}
