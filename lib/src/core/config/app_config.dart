import 'package:flutter/foundation.dart' show kIsWeb;

class AppConfig {
  /// Toggle this via: --dart-define=USE_LOCAL_PROXY=true
  static const bool useLocalProxy = bool.fromEnvironment('USE_LOCAL_PROXY', defaultValue: false);

  /// The base URL for the Progres WebEtu API.
  /// 
  /// SMART ROUTING:
  /// - On Mobile (Android/iOS): Calls Progres directly (No CORS, No IP block).
  /// - On Web: Uses the Vercel Proxy (to bypass browser CORS).
  static String get apiBaseUrl {
    // 1. Manual override via --dart-define
    const manualUrl = String.fromEnvironment('API_URL');
    if (manualUrl.isNotEmpty) return manualUrl;

    // 2. Local Proxy override
    if (useLocalProxy) return 'http://localhost:3000/api';

    // 3. Smart Default
    if (kIsWeb) {
      return 'https://iqamty-v1.vercel.app/api'; // Proxy for browsers
    } else {
      return 'https://progres.mesrs.dz/api'; // Direct for phones
    }
  }
  
  static const String appName = 'Iqamty';
  static const String appVersion = '1.0.0';
}

