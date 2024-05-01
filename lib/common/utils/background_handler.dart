import 'dart:async';
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:otraku/common/utils/routing.dart';
import 'package:otraku/modules/notification/notifications_model.dart';
import 'package:otraku/modules/viewer/api.dart';
import 'package:otraku/common/utils/graphql.dart';
import 'package:otraku/common/utils/options.dart';
import 'package:workmanager/workmanager.dart';

final _notificationPlugin = FlutterLocalNotificationsPlugin();

class BackgroundHandler {
  BackgroundHandler._();

  static Future<void> init(StreamController<String> notificationCtrl) async {
    _notificationPlugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('notification_icon'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (response) {
        if (response.payload == null) return;
        notificationCtrl.add(response.payload!);
      },
    );

    // Check if the app was launched by a notification.
    _notificationPlugin.getNotificationAppLaunchDetails().then(
      (launchDetails) {
        if (launchDetails?.notificationResponse?.payload == null) return;
        notificationCtrl.add(launchDetails!.notificationResponse!.payload!);
      },
    );

    await Workmanager().initialize(_fetch);

    if (Platform.isAndroid) {
      Workmanager().registerPeriodicTask(
        '0',
        'notifications',
        constraints: Constraints(networkType: NetworkType.connected),
      );
    }
  }

  /// Request for a permission to send notifications, if not already granted.
  static Future<bool> requestPermissionForNotifications() async {
    final android = _notificationPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return true;
    if (await android.areNotificationsEnabled() ?? true) return true;
    return await android.requestNotificationsPermission() ?? true;
  }

  /// Should be called, for example, when the user logs out of an account.
  static void clearNotifications() => _notificationPlugin.cancelAll();
}

@pragma('vm:entry-point')
void _fetch() => Workmanager().executeTask((_, __) async {
      // Initialise local settings.
      await Options.init();
      if (Options().selectedAccount == null) return true;
      Options().lastBackgroundWork = DateTime.now();

      // Log in.
      if (!Api.hasActiveAccount() && !await Api.init()) return true;

      // Get new notifications.
      Map<String, dynamic> data;
      try {
        data = await Api.get(GqlQuery.notifications, const {'withCount': true});
      } catch (_) {
        return true;
      }

      int count = data['Viewer']?['unreadNotificationCount'] ?? 0;
      final ns = data['Page']?['notifications'] ?? [];
      if (count > ns.length) count = ns.length;
      if (count == 0) return true;

      final last = Options().lastNotificationId;
      Options().lastNotificationId = ns[0]?['id'] ?? -1;

      // Show notifications.
      for (int i = 0; i < count && ns[i]?['id'] != last; i++) {
        final notification = SiteNotification.maybe(ns[i]);
        if (notification == null) continue;

        (switch (notification.type) {
          NotificationType.following => _show(
              notification,
              'New Follow',
              Routes.user(notification.bodyId!),
            ),
          NotificationType.activityMessage => _show(
              notification,
              'New Message',
              Routes.activity(notification.bodyId!),
            ),
          NotificationType.activityReply => _show(
              notification,
              'New Reply',
              Routes.activity(notification.bodyId!),
            ),
          NotificationType.activityReplySubscribed => _show(
              notification,
              'New Reply To Subscribed Activity',
              Routes.activity(notification.bodyId!),
            ),
          NotificationType.activityMention => _show(
              notification,
              'New Mention',
              Routes.activity(notification.bodyId!),
            ),
          NotificationType.activityLike => _show(
              notification,
              'New Activity Like',
              Routes.activity(notification.bodyId!),
            ),
          NotificationType.acrivityReplyLike => _show(
              notification,
              'New Reply Like',
              Routes.activity(notification.bodyId!),
            ),
          NotificationType.threadCommentReply => _show(
              notification,
              'New Forum Reply',
              Routes.thread(notification.bodyId!),
            ),
          NotificationType.threadCommentMention => _show(
              notification,
              'New Forum Mention',
              Routes.thread(notification.bodyId!),
            ),
          NotificationType.threadReplySubscribed => _show(
              notification,
              'New Forum Comment',
              Routes.thread(notification.bodyId!),
            ),
          NotificationType.threadLike => _show(
              notification,
              'New Forum Like',
              Routes.thread(notification.bodyId!),
            ),
          NotificationType.threadCommentLike => _show(
              notification,
              'New Forum Comment Like',
              Routes.thread(notification.bodyId!),
            ),
          NotificationType.airing => _show(
              notification,
              'New Episode',
              Routes.media(notification.bodyId!),
            ),
          NotificationType.relatedMediaAddition => _show(
              notification,
              'New Addition',
              Routes.media(notification.bodyId!),
            ),
          NotificationType.mediaDataChange => _show(
              notification,
              'Modified Media',
              Routes.media(notification.bodyId!),
            ),
          NotificationType.mediaMerge => _show(
              notification,
              'Merged Media',
              Routes.media(notification.bodyId!),
            ),
          NotificationType.mediaDeletion =>
            _show(notification, 'Deleted Media', Routes.notifications),
        });
      }

      return true;
    });

() _show(SiteNotification notification, String title, String payload) {
  _notificationPlugin.show(
    notification.id,
    title,
    notification.texts.join(),
    NotificationDetails(
      android: AndroidNotificationDetails(
        notification.type.name,
        notification.type.label,
        channelDescription: notification.type.label,
      ),
    ),
    payload: payload,
  );
  return ();
}
