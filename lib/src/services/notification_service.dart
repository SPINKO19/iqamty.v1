import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _isEnabled = true;

  Future<void> init() async {
    debugPrint("Notification Service Initialized");
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool('notifications_enabled') ?? true;
    // Initialize FCM and Local Notifications here
  }

  bool isEnabled() => _isEnabled;

  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);
  }

  Future<void> showNotification(String title, String body) async {
    if (!_isEnabled) return;
    debugPrint("Showing Notification: $title - $body");
    // Trigger local notification
  }

  Future<void> subscribeToTopic(String topic) async {
    if (!_isEnabled) return;
    debugPrint("Subscribed to topic: $topic");
    // FirebaseMessaging.instance.subscribeToTopic(topic);
  }
}
