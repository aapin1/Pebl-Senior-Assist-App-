import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_settings/app_settings.dart';

/// Deep link service for iOS Settings and Apps
/// Supports both Settings pages and native iOS apps
class SettingsLinker {
  /// Settings categories - open the Settings app (App Store safe)
  static const Set<String> _iosSettingsCategories = {
    'WIFI',
    'BLUETOOTH',
    'ACCESSIBILITY',
    'DISPLAY',
    'CELLULAR',
  };
  
  /// App deep links - these open native iOS apps
  /// Using URL schemes that are guaranteed to work on iOS
  static const Map<String, String> _iosAppUrls = {
    'CONTACTS': 'contacts://',
    'MESSAGES': 'sms://',
    'PHONE': 'tel://',
    'MAIL': 'mailto:',
    'PHOTOS': 'photos-redirect://',
    'CAMERA': 'camera://',
    'MAPS': 'maps://',
    'CALENDAR': 'calshow://',
    'NOTES': 'mobilenotes://',
    'REMINDERS': 'x-apple-reminderkit://',
    'FACETIME': 'facetime://',
    'SAFARI': 'x-web-search://',
    'APP_STORE': 'itms-apps://',
    'CLOCK': 'clock-alarm://',
    'WEATHER': 'weather://',
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

    // Only app categories get a URL scheme; settings uses app_settings API
    final Uri? uri = isApp ? Uri.parse(_iosAppUrls[category]!) : null;

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
  
  /// Launch a Settings page using app_settings (App Store safe)
  static Future<bool> _launchSettingsPage(String category) async {
    try {
      switch (category) {
        case 'WIFI':
          await AppSettings.openAppSettings(type: AppSettingsType.wifi);
          break;
        case 'BLUETOOTH':
          await AppSettings.openAppSettings(type: AppSettingsType.bluetooth);
          break;
        case 'ACCESSIBILITY':
          await AppSettings.openAppSettings(type: AppSettingsType.accessibility);
          break;
        case 'DISPLAY':
          await AppSettings.openAppSettings(type: AppSettingsType.display);
          break;
        case 'CELLULAR':
          await AppSettings.openAppSettings(type: AppSettingsType.dataRoaming);
          break;
        default:
          await AppSettings.openAppSettings();
      }
      
      return true;
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
      final urlString = _iosAppUrls[category];
      if (urlString == null) return false;
      
      final uri = Uri.parse(urlString);
      
      if (kDebugMode) {
        debugPrint('SettingsLinker: Launching app URL: $urlString');
      }
      
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      
      if (kDebugMode) {
        debugPrint('SettingsLinker: App launch result: $launched');
      }
      
      return launched;
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
      case 'CAMERA':
        return 'Camera';
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
      case 'CLOCK':
        return 'Clock';
      case 'WEATHER':
        return 'Weather';
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
