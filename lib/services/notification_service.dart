import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vaagai/core/models/doubt_model.dart';
import 'package:vaagai/core/routes/app_routes.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:vaagai/firebase_options.dart';

// ─── Top-level background handler (must be top-level, not static) ─────────────
// IMPORTANT: Must call Firebase.initializeApp(options:...) on cold-start.
// Low-end devices frequently cold-start the isolate for every background message.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Use DefaultFirebaseOptions so this works on a completely fresh isolate
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('🔔 BG Message received: ${message.notification?.title ?? message.data}');
}

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  static GlobalKey<NavigatorState>? _navigatorKey;

  /// Holds the onTokenRefresh subscription so we can cancel it on logout.
  /// Without cancelling, FCM auto-generates a new token after deleteToken()
  /// and the live listener immediately writes it back to Firestore.
  static StreamSubscription<String>? _tokenRefreshSubscription;

  // ─── Initialize ────────────────────────────────────────────────────────────

  static Future<void> initialize(GlobalKey<NavigatorState> navKey) async {
    _navigatorKey = navKey;
    debugPrint('🔔 NotificationService: Initializing...');

    // 1. Local notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null) {
          final data = json.decode(details.payload!);
          _handleNotificationTap(
              RemoteMessage(data: Map<String, dynamic>.from(data)));
        }
      },
    );

    // 2. Android channel
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(_channel);
      await androidPlugin.requestNotificationsPermission();
    }

    // 3. FCM permission
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 4. Background handler (registered before any other handler)
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 5. Foreground handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      final android = message.notification?.android;
      if (notification != null) {
        debugPrint('🔔 Foreground: ${notification.title}');
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              icon: android?.smallIcon ?? '@mipmap/ic_launcher',
              importance: Importance.max,
              priority: Priority.high,
              ticker: 'ticker',
              playSound: true,
              enableVibration: true,
            ),
          ),
          payload: json.encode(message.data),
        );
      }
    });

    // 6. Tap handlers
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  // ─── Notification tap → navigate ───────────────────────────────────────────

  static void _handleNotificationTap(RemoteMessage message) async {
    debugPrint('🔔 Tap: ${message.data}');
    final String? type = message.data['type'];
    final String? doubtId = message.data['doubtId'];

    if (type == 'doubt' && doubtId != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('doubts')
            .doc(doubtId)
            .get();
        if (doc.exists && _navigatorKey != null) {
          final doubt = DoubtModel.fromFirestore(doc);
          _navigatorKey!.currentState
              ?.pushNamed(AppRoutes.doubtChat, arguments: doubt);
        }
      } catch (e) {
        debugPrint('Error navigating from notification tap: $e');
      }
    }
  }

  // ─── Token helpers ─────────────────────────────────────────────────────────

  static Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  /// Save FCM token to users/{userId}/tokens/{token} sub-collection.
  static Future<void> saveTokenForUser(String userId) async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('tokens')
          .doc(token)
          .set({
        'token': token,
        'device': 'android',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('🔔 Token saved for $userId');

      // Cancel any previous subscription before registering a new one.
      // This prevents stacked listeners when saveTokenForUser is called
      // multiple times (app resume, login).
      await _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((newToken) async {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('tokens')
            .doc(newToken)
            .set({
          'token': newToken,
          'device': 'android',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('🔔 Token refreshed for $userId');
      });
    } catch (e) {
      debugPrint('🔔 Error saving token: $e');
    }
  }

  /// Delete only this device's FCM token on logout.
  static Future<void> deleteTokenForUser(String userId) async {
    try {
      // 1. Cancel the refresh listener FIRST.
      //    FCM fires onTokenRefresh immediately after deleteToken().
      //    If the listener is still active it will write the new token
      //    back to Firestore — defeating the logout entirely.
      await _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription = null;
      debugPrint('🔔 Token refresh listener cancelled for $userId');

      // 2. Get the current token before it is deleted
      final token = await _messaging.getToken();
      if (token == null) return;

      // 3. Delete from Firestore sub-collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('tokens')
          .doc(token)
          .delete();

      // 4. Delete from device (FCM will auto-generate a new token,
      //    but the listener above is already cancelled so it won't be saved)
      await _messaging.deleteToken();
      debugPrint('🔔 Token deleted for $userId');
    } catch (e) {
      debugPrint('🔔 Error deleting token: $e');
    }
  }

  // ─── Send multicast notification (client-side via service account) ─────────

  /// Saves a notification document and sends push to ALL active devices.
  static Future<void> sendNotification({
    required String recipientUid,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? doubtId,
  }) async {
    try {
      // 1. Persist in Firestore notifications collection
      await FirebaseFirestore.instance.collection('notifications').add({
        'receiver_id': recipientUid,
        'title': title,
        'body': body,
        'doubt_id': doubtId ?? data?['doubtId'],
        'type': data?['type'] ?? 'doubt',
        'is_read': false,
        'created_at': FieldValue.serverTimestamp(),
      });

      // 2. Fetch all active device tokens
      final tokensSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(recipientUid)
          .collection('tokens')
          .get();

      final tokens =
          tokensSnapshot.docs.map((d) => d.data()['token'] as String).toList();

      if (tokens.isEmpty) {
        debugPrint('🔔 No tokens for $recipientUid');
        return;
      }

      debugPrint('🔔 Sending to ${tokens.length} device(s) for $recipientUid');

      // 3. Send to each token via FCM V1 (multicast emulation)
      final List<String> invalidTokens = [];
      for (int i = 0; i < tokens.length; i++) {
        final success = await _sendDirectPushNotification(
          fcmToken: tokens[i],
          title: title,
          body: body,
          data: data,
        );
        if (!success) invalidTokens.add(tokens[i]);
      }

      // 4. Clean up invalid tokens
      for (final badToken in invalidTokens) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(recipientUid)
            .collection('tokens')
            .doc(badToken)
            .delete();
        debugPrint('🔔 Removed invalid token for $recipientUid');
      }
    } catch (e) {
      debugPrint('🔔 sendNotification ERROR: $e');
    }
  }

  static Future<bool> _sendDirectPushNotification({
    required String fcmToken,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final serviceAccountJson =
          await rootBundle.loadString('assets/service_account.json');
      final Map<String, dynamic> account = json.decode(serviceAccountJson);
      final String projectId = account['project_id'];

      final client = await auth.clientViaServiceAccount(
        auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
        ['https://www.googleapis.com/auth/cloud-platform'],
      );

      final fcmUrl =
          'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';

      // All data values must be strings for FCM V1
      final Map<String, String> stringData = {
        ...(data ?? {}).map((k, v) => MapEntry(k, v.toString())),
        // Duplicate title/body in data block so OEM battery-savers
        // (MIUI, ColorOS, FunTouchOS) that kill notification messages
        // can still wake the background handler from the data message.
        'notification_title': title,
        'notification_body': body,
      };

      final Map<String, dynamic> messagePayload = {
        'message': {
          'token': fcmToken,
          // notification block → shown by system when app is in background/killed
          'notification': {
            'title': title,
            'body': body,
          },
          // data block → delivered even through Doze + OEM battery savers
          'data': stringData,
          'android': {
            'priority': 'high', // Wakes the device from Doze
            'ttl': '86400s',    // Retry for up to 24h if device is offline
            'notification': {
              'channel_id': 'high_importance_channel',
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'default_sound': true,
              'default_vibrate_timings': true,
              'notification_priority': 'PRIORITY_MAX',
              'visibility': 'PUBLIC',
            },
          },
        }
      };

      final response = await client.post(
        Uri.parse(fcmUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(messagePayload),
      );

      client.close();

      if (response.statusCode == 200) return true;

      // Token not registered → signal for cleanup
      if (response.statusCode == 404 ||
          response.body.contains('registration-token-not-registered') ||
          response.body.contains('UNREGISTERED')) {
        return false;
      }

      debugPrint('🔔 FCM responded ${response.statusCode}: ${response.body}');
      return true; // Don't delete on temporary errors
    } catch (e) {
      debugPrint('🔔 _sendDirectPush ERROR: $e');
      return true; // Keep token on network errors
    }
  }
}
