class AppConfig {
  /// The base URL for the Progres WebEtu API.
  /// Hardcoding URLs is generally discouraged because it makes it harder
  /// to switch between Development, Testing, and Production environments.
  /// 
  /// In a production app, we use 'dart-define' to inject the Vercel URL.
  /// Example: flutter build web --dart-define=API_URL=https://your-app.vercel.app/api
  static const String apiBaseUrl = String.fromEnvironment(
    'API_URL', 
    defaultValue: 'https://iqamty-proxy.vercel.app/api' // Replace with your real Vercel URL
  );
  
  // You can add more configuration constants here as the app grows
  static const String appName = 'Iqamty';
  static const String appVersion = '1.0.0';
}
