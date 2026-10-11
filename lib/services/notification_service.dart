import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';
import 'firebase_service.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseService().messaging;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseService().firestore;

  Future<void> initialize() async {
    // Initialize local notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps when app is opened from terminated state
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
  }

  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    debugPrint('Handling background message: ${message.messageId}');
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Received foreground message: ${message.notification?.title}');

    if (message.notification != null) {
      _showLocalNotification(
        title: message.notification!.title ?? 'Notification',
        body: message.notification!.body ?? '',
        payload: jsonEncode(message.data),
      );
    }
  }

  void _handleNotificationTap(NotificationResponse? response) {
    if (response?.payload != null) {
      final data = jsonDecode(response!.payload!);
      _navigateToNotificationTarget(data);
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    _navigateToNotificationTarget(message.data);
  }

  void _navigateToNotificationTarget(Map<String, dynamic> data) {
    final type = data['type'];
    final issueId = data['issueId'];
    final commentId = data['commentId'];

    switch (type) {
      case 'issue_status_changed':
      case 'new_comment':
        if (issueId != null) {
          debugPrint('Navigate to issue: $issueId');
        }
        break;
      case 'comment_flagged':
        if (commentId != null) {
          debugPrint('Navigate to moderate comment: $commentId');
        }
        break;
    }
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'civicvoice_channel',
      'CivicVoice Notifications',
      channelDescription: 'Notifications for CivicVoice app',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  Future<String?> getFCMToken() async {
    return await _messaging.getToken();
  }

  Future<void> saveFCMToken(String userId) async {
    final token = await getFCMToken();
    if (token != null) {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
        'tokenUpdatedAt': Timestamp.now(),
      });
    }
  }

  Future<void> removeFCMToken(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'fcmToken': FieldValue.delete(),
      'tokenUpdatedAt': FieldValue.delete(),
    });
  }

  void setupTokenRefreshListener(String userId) {
    _messaging.onTokenRefresh.listen((newToken) async {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': newToken,
        'tokenUpdatedAt': Timestamp.now(),
      });
    });
  }

  Future<void> updateNotificationPreferences(String userId, Map<String, bool> preferences) async {
    await _firestore.collection('users').doc(userId).update({
      'notificationPreferences': preferences,
      'preferencesUpdatedAt': Timestamp.now(),
    });
  }

  Future<Map<String, dynamic>?> getNotificationPreferences(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.data()?['notificationPreferences'];
  }

  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final userData = userDoc.data();

    if (userData == null || userData['fcmToken'] == null) {
      throw Exception('User not found or no FCM token');
    }

    final message = {
      'token': userData['fcmToken'],
      'notification': {
        'title': title,
        'body': body,
      },
      'data': data ?? {},
    };

    debugPrint('Sending notification to user $userId: $message');
  }

  Future<void> sendNotificationToMultipleUsers({
    required List<String> userIds,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final tokens = [];

    for (final userId in userIds) {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();

      if (userData != null && userData['fcmToken'] != null) {
        tokens.add(userData['fcmToken']);
      }
    }

    if (tokens.isEmpty) {
      throw Exception('No valid FCM tokens found');
    }

    final message = {
      'tokens': tokens,
      'notification': {
        'title': title,
        'body': body,
      },
      'data': data ?? {},
    };

    debugPrint('Sending multicast notification: $message');
  }

  Future<void> sendNotificationToAllUsers({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final usersSnapshot = await _firestore.collection('users').get();
    final tokens = usersSnapshot.docs
        .map((doc) => doc.data()['fcmToken'])
        .where((token) => token != null)
        .toList();

    if (tokens.isEmpty) {
      throw Exception('No valid FCM tokens found');
    }

    final message = {
      'tokens': tokens,
      'notification': {
        'title': title,
        'body': body,
      },
      'data': data ?? {},
    };

    debugPrint('Sending broadcast notification: $message');
  }

  Future<void> notifyIssueStatusChange({
    required String issueId,
    required String userId,
    required String oldStatus,
    required String newStatus,
    required String issueTitle,
  }) async {
    await sendNotificationToUser(
      userId: userId,
      title: 'Issue Status Updated',
      body: 'Your issue "$issueTitle" status changed from $oldStatus to $newStatus',
      data: {
        'type': 'issue_status_changed',
        'issueId': issueId,
        'oldStatus': oldStatus,
        'newStatus': newStatus,
      },
    );
  }

  Future<void> notifyNewComment({
    required String issueAuthorId,
    required String commenterName,
    required String issueId,
    required String commentId,
  }) async {
    await sendNotificationToUser(
      userId: issueAuthorId,
      title: 'New Comment',
      body: '$commenterName commented on your issue',
      data: {
        'type': 'new_comment',
        'issueId': issueId,
        'commentId': commentId,
      },
    );
  }

  Future<void> notifyModeratorsOfFlaggedContent({
    required String contentType,
    required String contentId,
    required String reason,
  }) async {
    final moderatorsSnapshot = await _firestore.collection('moderators').get();
    final moderatorIds = moderatorsSnapshot.docs.map((doc) => doc.id).toList();

    if (moderatorIds.isEmpty) return;

    final title = 'Content Flagged for Review';
    final body = '$contentType requires moderation ($reason)';

    await sendNotificationToMultipleUsers(
      userIds: moderatorIds,
      title: title,
      body: body,
      data: {
        'type': '${contentType}_flagged',
        'contentId': contentId,
        'reason': reason,
      },
    );
  }
}
