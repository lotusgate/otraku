import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otraku/modules/notification/notifications_model.dart';
import 'package:otraku/common/models/paged.dart';
import 'package:otraku/common/utils/api.dart';
import 'package:otraku/common/utils/graphql.dart';

final notificationsProvider = AsyncNotifierProvider.autoDispose<
    NotificationsNotifier, PagedWithTotal<SiteNotification>>(
  NotificationsNotifier.new,
);

final notificationsFilterProvider = NotifierProvider.autoDispose<
    NotificationsFilterNotifier, NotificationFilter>(
  NotificationsFilterNotifier.new,
);

class NotificationsNotifier
    extends AutoDisposeAsyncNotifier<PagedWithTotal<SiteNotification>> {
  late NotificationFilter filter;

  @override
  FutureOr<PagedWithTotal<SiteNotification>> build() async {
    filter = ref.watch(notificationsFilterProvider);
    return await _fetch(const PagedWithTotal());
  }

  Future<void> fetch() async {
    final oldState = state.valueOrNull ?? const PagedWithTotal();
    if (!oldState.hasNext) return;
    state = await AsyncValue.guard(() => _fetch(oldState));
  }

  Future<PagedWithTotal<SiteNotification>> _fetch(
    PagedWithTotal<SiteNotification> oldState,
  ) async {
    final data = await Api.get(GqlQuery.notifications, {
      'page': oldState.next,
      if (filter == NotificationFilter.all) ...{
        'withCount': true,
        'resetCount': true,
      } else
        'filter': filter.vars,
    });

    int? unreadCount;
    if (filter.index < 1) {
      unreadCount = data['Viewer']['unreadNotificationCount'] ?? 0;
    }

    final items = <SiteNotification>[];
    for (final n in data['Page']['notifications']) {
      final item = SiteNotification.maybe(n);
      if (item != null) items.add(item);
    }

    return oldState.withNext(
      items,
      data['Page']['pageInfo']['hasNextPage'] ?? false,
      unreadCount,
    );
  }
}

class NotificationsFilterNotifier
    extends AutoDisposeNotifier<NotificationFilter> {
  @override
  NotificationFilter build() => NotificationFilter.all;

  @override
  NotificationFilter get state => super.state;

  @override
  set state(NotificationFilter newState) => super.state = newState;
}
