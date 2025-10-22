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
  
  // Track number of consecutive ad load failures for better retry logic
  int _consecutiveFailures = 0;
  
  // Track if we're currently loading an ad to prevent duplicate loads
  bool _isLoadingAd = false;
  
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
    // Don't load if ads are disabled or already loading
    if (!_adsEnabled || _isLoadingAd) return;
    
    // Mark as loading to prevent duplicate requests
    _isLoadingAd = true;
    print('📥 Loading interstitial ad...');

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
          print('✅ Ad loaded successfully!');
          _interstitialAd = ad;
          _isAdReady = true;
          _isLoadingAd = false;
          _consecutiveFailures = 0; // Reset failure counter on success
          
          // Set up ad event callbacks
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (InterstitialAd ad) {
              // Ad is showing
            },
            onAdDismissedFullScreenContent: (InterstitialAd ad) {
              // User dismissed the ad, dispose and load next ad
              print('👋 Ad dismissed by user');
              ad.dispose();
              _interstitialAd = null;
              _isAdReady = false;
              _isLoadingAd = false;
              // Immediately start loading next ad
              _loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
              // Ad failed to show
              print('❌ Ad failed to show: ${error.message}');
              ad.dispose();
              _interstitialAd = null;
              _isAdReady = false;
              _isLoadingAd = false;
              // Try to load another ad immediately
              _loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          // Ad failed to load - this is normal and happens sometimes
          print('❌ Ad failed to load: ${error.message} (Code: ${error.code})');
          _interstitialAd = null;
          _isAdReady = false;
          _isLoadingAd = false;
          _consecutiveFailures++;
          
          // Exponential backoff: 2s, 4s, 8s, 16s, max 30s
          int retryDelay = (2 * (1 << (_consecutiveFailures - 1))).clamp(2, 30);
          print('⏳ Retrying ad load in $retryDelay seconds (failure #$_consecutiveFailures)');
          
          Future.delayed(Duration(seconds: retryDelay), () {
            if (!_isAdReady && _adsEnabled) {
              _loadInterstitialAd();
            }
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
      
      print('📺 Showing ad now!');
      // Show the ad
      await _interstitialAd!.show();
      return true; // Ad was shown
    } else {
      // Ad not ready - try to load one if not already loading
      print('⚠️ Ad not ready to show (isReady: $_isAdReady, ad exists: ${_interstitialAd != null}, loading: $_isLoadingAd)');
      if (!_isLoadingAd && !_isAdReady) {
        print('🔄 Attempting to load ad now since none is ready');
        _loadInterstitialAd();
      }
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
    if (!_isAdReady && !_isLoadingAd && _adsEnabled) {
      await _loadInterstitialAd();
    }
  }
  
  /// Get diagnostic info about ad status (for debugging)
  String getAdStatus() {
    return 'Ad Status: Ready=$_isAdReady, Loading=$_isLoadingAd, Failures=$_consecutiveFailures, QueryCount=$_queryCount';
  }
}
