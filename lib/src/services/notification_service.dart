import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<void> init() async {
    debugPrint("Notification Service Initialized");
    // Initialize FCM and Local Notifications here
  }

  Future<void> showNotification(String title, String body) async {
    debugPrint("Showing Notification: $title - $body");
    // Trigger local notification
  }

  Future<void> subscribeToTopic(String topic) async {
    debugPrint("Subscribed to topic: $topic");
    // FirebaseMessaging.instance.subscribeToTopic(topic);
  }
}
