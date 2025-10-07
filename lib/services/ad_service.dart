import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ad Service for managing interstitial ads in the Pebl app
/// Shows friendly ads every few queries to keep the app free
class AdService {
  // Singleton pattern for global access
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  // Your Real AdMob Ad Unit IDs
  static const String _androidInterstitialAdUnitId = 'ca-app-pub-3246559805539805/4088277292'; // Real ID
  static const String _iosInterstitialAdUnitId = 'ca-app-pub-3246559805539805/4088277292'; // Real ID

  // Interstitial ad instance
  InterstitialAd? _interstitialAd;
  
  // Track if ad is ready to show
  bool _isAdReady = false;
  
  // Query counter to determine when to show ads
  int _queryCount = 0;
  
  // Show ad every query (1 question = 1 ad)
  static const int _queriesBeforeAd = 1;
  
  // Shared preferences key for persistent query counting
  static const String _queryCountKey = 'query_count';
  
  // Track if ads are enabled (can be toggled in settings)
  bool _adsEnabled = true;

  /// Initialize the ad service
  Future<void> initialize() async {
    // Initialize Google Mobile Ads SDK
    await MobileAds.instance.initialize();
    
    // Load query count from persistent storage
    await _loadQueryCount();
    
    // Load the first interstitial ad
    await _loadInterstitialAd();
  }

  /// Load query count from shared preferences
  Future<void> _loadQueryCount() async {
    final prefs = await SharedPreferences.getInstance();
    _queryCount = prefs.getInt(_queryCountKey) ?? 0;
  }

  /// Save query count to shared preferences
  Future<void> _saveQueryCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_queryCountKey, _queryCount);
  }

  /// Get the appropriate ad unit ID based on platform
  String get _interstitialAdUnitId {
    if (Platform.isAndroid) {
      return _androidInterstitialAdUnitId;
    } else if (Platform.isIOS) {
      return _iosInterstitialAdUnitId;
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  /// Load an interstitial ad
  Future<void> _loadInterstitialAd() async {
    // Don't load if ads are disabled
    if (!_adsEnabled) return;

    // Create ad request with family-friendly targeting for seniors
    final adRequest = const AdRequest(
      keywords: ['technology', 'senior', 'help', 'tutorial', 'family'],
      contentUrl: 'https://peblapp.help',
      nonPersonalizedAds: false, // Allow personalized ads for better revenue
    );

    // Load interstitial ad
    await InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: adRequest,
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          // Ad loaded successfully
          _interstitialAd = ad;
          _isAdReady = true;
          
          // Set up ad event callbacks
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (InterstitialAd ad) {
              // Ad is showing
            },
            onAdDismissedFullScreenContent: (InterstitialAd ad) {
              // User dismissed the ad, dispose and load next ad
              ad.dispose();
              _interstitialAd = null;
              _isAdReady = false;
              _loadInterstitialAd(); // Preload next ad
            },
            onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
              // Ad failed to show
              ad.dispose();
              _interstitialAd = null;
              _isAdReady = false;
              _loadInterstitialAd(); // Try to load another ad
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          // Ad failed to load - this is normal and happens sometimes
          _interstitialAd = null;
          _isAdReady = false;
          
          // Retry loading after a delay (exponential backoff would be better for production)
          Future.delayed(const Duration(seconds: 30), () {
            _loadInterstitialAd();
          });
        },
      ),
    );
  }

  /// Called when user asks a question - increments counter and shows ad if needed
  /// Returns true if ad was shown, false otherwise
  Future<bool> onUserQuery() async {
    // Don't show ads if disabled
    if (!_adsEnabled) {
      print('📺 Ads are disabled');
      return false;
    }

    // Increment query counter
    _queryCount++;
    await _saveQueryCount();
    
    print('📊 Query count: $_queryCount / $_queriesBeforeAd (ad ready: $_isAdReady)');

    // Check if it's time to show an ad
    if (_queryCount >= _queriesBeforeAd) {
      print('🎯 Time to show ad!');
      return await _showAdIfReady();
    }

    print('⏳ Not yet time for ad');
    return false; // No ad shown
  }

  /// Show interstitial ad if ready and reset counter
  Future<bool> _showAdIfReady() async {
    if (_isAdReady && _interstitialAd != null) {
      // Reset query counter before showing ad
      _queryCount = 0;
      await _saveQueryCount();
      
      // Show the ad
      await _interstitialAd!.show();
      return true; // Ad was shown
    }
    
    return false; // Ad not ready or not available
  }

  /// Enable or disable ads (for premium users or settings)
  void setAdsEnabled(bool enabled) {
    _adsEnabled = enabled;
    
    if (!enabled && _interstitialAd != null) {
      // Dispose current ad if ads are disabled
      _interstitialAd!.dispose();
      _interstitialAd = null;
      _isAdReady = false;
    } else if (enabled && !_isAdReady) {
      // Load ad if ads are enabled and no ad is ready
      _loadInterstitialAd();
    }
  }

  /// Check if ads are currently enabled
  bool get adsEnabled => _adsEnabled;

  /// Get current query count (for debugging or UI display)
  int get queryCount => _queryCount;

  /// Get queries remaining until next ad
  int get queriesUntilNextAd => _queriesBeforeAd - _queryCount;

  /// Check if ad is ready to show
  bool get isAdReady => _isAdReady;

  /// Dispose of resources when app is closing
  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isAdReady = false;
  }

  /// Reset query counter (useful for testing or premium features)
  Future<void> resetQueryCounter() async {
    _queryCount = 0;
    await _saveQueryCount();
  }

  /// Manually trigger ad loading (useful for preloading)
  Future<void> preloadAd() async {
    if (!_isAdReady && _adsEnabled) {
      await _loadInterstitialAd();
    }
  }
}
