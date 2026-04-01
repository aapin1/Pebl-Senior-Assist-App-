import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Deep link service for iOS Settings and Apps
/// Supports both Settings pages and native iOS apps
class SettingsLinker {
  /// iOS settings URLs by category (attempted in order)
  static const Map<String, List<String>> _iosSettingsUrls = {
    'WIFI': [
      'App-prefs:root=WIFI',
      'App-prefs://',
      'App-prefs:',
      'prefs:root=WIFI',
      'prefs://',
      'prefs:',
      'prefs:root',
    ],
    'BLUETOOTH': [
      'App-prefs:root=Bluetooth',
      'App-prefs://',
      'App-prefs:',
      'prefs:root=Bluetooth',
      'prefs:root=BLUETOOTH',
      'prefs://',
      'prefs:',
      'prefs:root',
    ],
    'ACCESSIBILITY': [
      'App-prefs:root=ACCESSIBILITY',
      'App-prefs://',
      'App-prefs:',
      'prefs:root=ACCESSIBILITY',
      'prefs://',
      'prefs:',
      'prefs:root',
    ],
    'DISPLAY': [
      'App-prefs:root=DISPLAY',
      'App-prefs://',
      'App-prefs:',
      'prefs:root=DISPLAY',
      'prefs://',
      'prefs:',
      'prefs:root',
    ],
    'CELLULAR': [
      'App-prefs:root=MOBILE_DATA_SETTINGS_ID',
      'App-prefs:root=MOBILE_DATA',
      'App-prefs://',
      'App-prefs:',
      'prefs:root=MOBILE_DATA_SETTINGS_ID',
      'prefs:root=MOBILE_DATA',
      'prefs://',
      'prefs:',
      'prefs:root',
    ],
    'CAMERA': [
      'App-prefs:root=CAMERA',
      'App-prefs://',
      'App-prefs:',
      'prefs:root=CAMERA',
      'prefs://',
      'prefs:',
      'prefs:root',
    ],
  };

  /// Settings categories - open the Settings app (App Store safe)
  static const Set<String> _iosSettingsCategories = {
    'WIFI',
    'BLUETOOTH',
    'ACCESSIBILITY',
    'DISPLAY',
    'CELLULAR',
    'CAMERA',
  };
  
  /// App deep links — direct app scheme first, App-prefs settings page as fallback.
  /// Order is based on simctl openurl testing + known real-device behaviour.
  /// Simulator exit-0 confirmed schemes are marked ✓; device-only schemes are noted.
  static const Map<String, List<String>> _iosAppUrls = {
    // contacts:// opens Contacts app (device-only; simulator lacks app) ✓ on device
    'CONTACTS': [
      'contacts://',
      'addressbook://',
      'App-prefs:root=CONTACTS',
      'App-prefs://',
    ],
    // messages:// opens Messages home (NOT compose) ✓ simulator + device
    'MESSAGES': [
      'messages://',
      'imessage://',
      'App-prefs:root=MESSAGES',
      'App-prefs://',
    ],
    // Open Settings > Phone to avoid accidental call prompt
    'PHONE': [
      'App-prefs:root=Phone',
      'App-prefs://',
      'tel://',
    ],
    // message:// opens Mail app (device-only); mailto: opens compose (fallback only)
    'MAIL': [
      'message://',
      'App-prefs:root=MAIL',
      'App-prefs://',
      'mailto:',
    ],
    // photos-redirect:// ✓ simulator + device
    'PHOTOS': [
      'photos-redirect://',
    ],
    // maps:// ✓ simulator + device
    'MAPS': [
      'maps://',
      'map://',
      'App-prefs:root=MAPS',
    ],
    // calshow:// ✓ simulator + device; x-apple-calevent:// also works
    'CALENDAR': [
      'calshow://',
      'x-apple-calevent://',
      'App-prefs:root=CALENDAR',
    ],
    // mobilenotes:// opens Notes app (device-only)
    'NOTES': [
      'mobilenotes://',
      'App-prefs:root=NOTES',
      'App-prefs://',
    ],
    // x-apple-reminder:// opens Reminders app (device-only)
    'REMINDERS': [
      'x-apple-reminder://',
      'App-prefs:root=REMINDERS',
      'App-prefs://',
    ],
    // facetime:// opens FaceTime app (device-only; simulator lacks app)
    'FACETIME': [
      'facetime://',
      'facetime-audio://',
      'App-prefs:root=FACETIME',
      'App-prefs://',
    ],
    // x-web-search:// ✓ simulator + device
    'SAFARI': [
      'x-web-search://',
      'App-prefs:root=SAFARI',
    ],
    // itms-apps:// opens App Store (device-only; simulator lacks store)
    'APP_STORE': [
      'itms-apps://itunes.apple.com',
      'itms-apps://',
    ],
    // weather:// opens Weather app (device-only)
    'WEATHER': [
      'weather://',
      'App-prefs://',
    ],
    // applenews:// ✓ simulator + device
    'NEWS': [
      'applenews://',
      'applenewss://',
    ],
    // music:// opens Music app (device-only)
    'MUSIC': [
      'music://',
      'musics://',
      'audio-player-event://',
      'App-prefs:root=MUSIC',
      'App-prefs://',
    ],
    // videos:// opens TV app (device-only)
    'TV': [
      'videos://',
      'App-prefs:root=TVAPP',
      'App-prefs://',
    ],
    // podcasts:// opens Podcasts app (device-only)
    'PODCASTS': [
      'podcasts://',
      'pcast://',
      'podcast://',
      'App-prefs://',
    ],
    // shareddocuments:// ✓ simulator + device
    'FILES': [
      'shareddocuments://',
    ],
    // voicememos:// opens Voice Memos app (device-only)
    'VOICE_MEMOS': [
      'voicememos://',
      'App-prefs:root=VOICE_MEMOS',
      'App-prefs://',
    ],
    // clock-alarm:// opens Clock app (device-only)
    'CLOCK': [
      'clock-alarm://',
      'App-prefs://',
    ],
    // shoebox:// ✓ simulator + device
    'WALLET': [
      'shoebox://',
      'App-prefs:root=PASSBOOK',
    ],
    // shortcuts:// ✓ simulator + device
    'SHORTCUTS': [
      'shortcuts://',
      'App-prefs:root=SHORTCUTS',
    ],
    // ibooks:// opens Books app (device-only)
    'BOOKS': [
      'ibooks://',
      'itms-books://',
      'App-prefs://',
    ],
    // dict:// opens Dictionary app (device-only)
    'DICTIONARY': [
      'dict://',
      'App-prefs://',
    ],
  };
  
  /// Combined whitelist of all supported categories
  static Set<String> get allSupportedCategories => {
    ..._iosSettingsCategories,
    ..._iosAppUrls.keys,
  };
  
  /// Check if a category is a Settings page or an App
  static bool isSettingsCategory(String category) {
    return _iosSettingsCategories.contains(category.toUpperCase());
  }
  
  static bool isAppCategory(String category) {
    return _iosAppUrls.containsKey(category.toUpperCase());
  }

  /// Result of a deep link verification
  /// Contains whether the link is valid and launchable
  static Future<SettingsLinkResult> verifyAndGetLink(String? deepLinkCategory) async {
    // No deep link provided - this is fine, just return invalid
    if (deepLinkCategory == null || deepLinkCategory.trim().isEmpty) {
      return SettingsLinkResult(
        isValid: false,
        category: null,
        url: null,
        reason: 'No deep link provided',
      );
    }

    final category = deepLinkCategory.trim().toUpperCase();

    // Check if category is in our whitelist (Settings OR Apps)
    final isSettings = _iosSettingsCategories.contains(category);
    final isApp = _iosAppUrls.containsKey(category);
    
    if (!isSettings && !isApp) {
      if (kDebugMode) {
        debugPrint('SettingsLinker: Category "$category" not in whitelist');
      }
      return SettingsLinkResult(
        isValid: false,
        category: category,
        url: null,
        reason: 'Category not in whitelist',
      );
    }

    // Only attempt iOS deep links on iOS devices
    if (!Platform.isIOS) {
      if (kDebugMode) {
        debugPrint('SettingsLinker: Not iOS platform, skipping deep link');
      }
      return SettingsLinkResult(
        isValid: false,
        category: category,
        url: null,
        reason: 'Deep links only supported on iOS',
      );
    }

    // Provide representative URL for validated category (launch uses category handlers)
    final Uri? uri =
        isApp ? Uri.parse(_iosAppUrls[category]!.first) : null;

    if (kDebugMode) {
      debugPrint('SettingsLinker: Approved ${isSettings ? "settings" : "app"} link for $category');
    }
    
    return SettingsLinkResult(
      isValid: true,
      category: category,
      url: uri,
      reason: 'Whitelisted and ready',
    );
  }

  /// Launch Settings or App for the given category
  /// Uses app_settings package for Settings, url_launcher for Apps
  static Future<bool> launchSettingsForCategory(String? category) async {
    if (category == null) {
      if (kDebugMode) {
        debugPrint('SettingsLinker: No category provided');
      }
      return false;
    }
    
    final upperCategory = category.toUpperCase();
    
    if (kDebugMode) {
      debugPrint('SettingsLinker: Launching for category: $upperCategory');
    }
    
    // Check if it's a Settings category
    if (isSettingsCategory(upperCategory)) {
      return _launchSettingsPage(upperCategory);
    }
    
    // Check if it's an App category
    if (isAppCategory(upperCategory)) {
      return _launchApp(upperCategory);
    }
    
    if (kDebugMode) {
      debugPrint('SettingsLinker: Unknown category: $upperCategory');
    }
    return false;
  }
  
  /// Launch a Settings page via iOS Settings URL schemes.
  /// Returns false when unavailable so UI can show fallback guidance.
  static Future<bool> _launchSettingsPage(String category) async {
    try {
      final candidates = _iosSettingsUrls[category];
      if (candidates == null || candidates.isEmpty) {
        if (kDebugMode) {
          debugPrint('SettingsLinker: No settings candidates for $category');
        }
        return false;
      }

      for (final urlString in candidates) {
        final uri = Uri.parse(urlString);

        if (kDebugMode) {
          debugPrint('SettingsLinker: Trying settings URL: $urlString');
        }

        final canLaunch = await canLaunchUrl(uri);

        if (kDebugMode) {
          debugPrint('SettingsLinker: canLaunch($urlString) = $canLaunch');
        }

        try {
          final launched = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );

          if (kDebugMode) {
            debugPrint('SettingsLinker: launch($urlString) = $launched');
          }

          if (launched) {
            if (kDebugMode) {
              debugPrint('SettingsLinker: Settings launch succeeded with $urlString');
            }
            return true;
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('SettingsLinker: launch($urlString) threw $e');
          }
        }
      }

      if (kDebugMode) {
        debugPrint('SettingsLinker: All settings URLs failed for $category');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SettingsLinker: Failed to launch settings: $e');
      }
      return false;
    }
  }
  
  /// Launch an iOS app using its URL scheme
  static Future<bool> _launchApp(String category) async {
    try {
      final candidates = _iosAppUrls[category];
      if (candidates == null || candidates.isEmpty) {
        if (kDebugMode) {
          debugPrint('SettingsLinker: No app candidates for $category');
        }
        return false;
      }

      for (final urlString in candidates) {
        final uri = Uri.parse(urlString);

        if (kDebugMode) {
          debugPrint('SettingsLinker: Trying app URL: $urlString');
        }

        final canLaunch = await canLaunchUrl(uri);

        if (kDebugMode) {
          debugPrint('SettingsLinker: canLaunch($urlString) = $canLaunch');
        }

        try {
          final launched = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );

          if (kDebugMode) {
            debugPrint('SettingsLinker: App launch result: $launched');
          }

          if (launched) {
            if (kDebugMode) {
              debugPrint('SettingsLinker: App launch succeeded with $urlString');
            }
            return true;
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('SettingsLinker: launch($urlString) threw $e');
          }
        }
      }

      if (kDebugMode) {
        debugPrint('SettingsLinker: All app URLs failed for $category');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SettingsLinker: Failed to launch app: $e');
      }
      return false;
    }
  }
  
  /// Legacy method - kept for compatibility
  static Future<bool> launchSettingsUrl(Uri url) async {
    final urlString = url.toString().toUpperCase();
    
    // Try to extract category from URL
    for (final category in _iosSettingsCategories) {
      if (urlString.contains(category)) {
        return launchSettingsForCategory(category);
      }
    }
    
    for (final entry in _iosAppUrls.entries) {
      if (urlString.contains(entry.key)) {
        return launchSettingsForCategory(entry.key);
      }
    }
    
    // Fallback to general settings
    return launchSettingsForCategory(null);
  }

  /// Get a user-friendly label for the category (Settings or App)
  static String getCategoryLabel(String category) {
    switch (category.toUpperCase()) {
      // Settings categories
      case 'WIFI':
      case 'BLUETOOTH':
      case 'ACCESSIBILITY':
      case 'DISPLAY':
      case 'CELLULAR':
      case 'CAMERA':
        return 'Settings';
      // App categories
      case 'CONTACTS':
        return 'Contacts';
      case 'MESSAGES':
        return 'Messages';
      case 'PHONE':
        return 'Phone';
      case 'MAIL':
        return 'Mail';
      case 'PHOTOS':
        return 'Photos';
      case 'MAPS':
        return 'Maps';
      case 'CALENDAR':
        return 'Calendar';
      case 'NOTES':
        return 'Notes';
      case 'REMINDERS':
        return 'Reminders';
      case 'FACETIME':
        return 'FaceTime';
      case 'SAFARI':
        return 'Safari';
      case 'APP_STORE':
        return 'App Store';
      case 'WEATHER':
        return 'Weather';
      case 'NEWS':
        return 'News';
      case 'MUSIC':
        return 'Music';
      case 'TV':
        return 'TV';
      case 'PODCASTS':
        return 'Podcasts';
      case 'FILES':
        return 'Files';
      case 'VOICE_MEMOS':
        return 'Voice Memos';
      case 'CLOCK':
        return 'Clock';
      case 'WALLET':
        return 'Wallet';
      case 'SHORTCUTS':
        return 'Shortcuts';
      case 'BOOKS':
        return 'Books';
      case 'DICTIONARY':
        return 'Dictionary';
      default:
        return 'App';
    }
  }
}

/// Result of a settings link verification
class SettingsLinkResult {
  final bool isValid;
  final String? category;
  final Uri? url;
  final String reason;

  SettingsLinkResult({
    required this.isValid,
    required this.category,
    required this.url,
    required this.reason,
  });
}
