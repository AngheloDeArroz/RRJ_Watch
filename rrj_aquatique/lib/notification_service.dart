// lib/notification_service.dart
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

// Top-level background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('Background message received: ${message.messageId}');
  // Optionally show a local notification for background messages
  // You could call NotificationService._showLocalNotification(message) here
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'Used for important notifications',
    importance: Importance.high,
  );

  /// Initialize Firebase Messaging and Local Notifications
  static Future<void> init() async {
    // Initialize Firebase
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Create Android notification channel
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Initialize flutter_local_notifications
    const InitializationSettings initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('Notification tapped: ${response.payload}');
      },
    );

    // Request notification permission (Android 13+)
    await _requestPermissions();

    // 6️⃣ Get device token and save it to Firestore
    await _saveDeviceToken();

    // 4️⃣ Listen for token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      await FirebaseFirestore.instance
          .collection('fcm-tokens')
          .doc(newToken)
          .set({'updatedAt': FieldValue.serverTimestamp()});
      print('Token refreshed: $newToken');
    });

    // 5️⃣ Listen for foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground message: ${message.messageId}');
      _showLocalNotification(message);
    });
  }

  /// Request notification permission
  static Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      final messaging = FirebaseMessaging.instance;
      NotificationSettings settings = await messaging.requestPermission();
      print('Android permission: ${settings.authorizationStatus}');
    }
  }

  /// Show a local notification
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final androidDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.high,
      priority: Priority.high,
    );

    final details = NotificationDetails(android: androidDetails);

    await _flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
      payload: message.data.toString(),
    );
  }

  /// Get device FCM token
  static Future<String?> getDeviceToken() async {
    return FirebaseMessaging.instance.getToken();
  }

  /// Save device token to Firestore
  static Future<void> _saveDeviceToken() async {
    final token = await getDeviceToken();
    if (token != null) {
      await FirebaseFirestore.instance
          .collection('fcm-tokens')
          .doc(token)
          .set({'createdAt': FieldValue.serverTimestamp()});
      print('Device token saved: $token');
    }
  }

  /// Subscribe to a topic
  static Future<void> subscribeToTopic(String topic) async {
    await FirebaseMessaging.instance.subscribeToTopic(topic);
  }

  /// Unsubscribe from a topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
  }
}
