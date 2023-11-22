import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otraku/modules/activity/activity_models.dart';
import 'package:otraku/common/utils/api.dart';
import 'package:otraku/common/utils/graphql.dart';
import 'package:otraku/common/models/paged.dart';
import 'package:otraku/common/utils/options.dart';

/// Toggles an activity like and returns an error if unsuccessful.
Future<Object?> toggleActivityLike(Activity activity) async {
  try {
    await Api.get(GqlMutation.toggleLike, {
      'id': activity.id,
      'type': 'ACTIVITY',
    });
    return null;
  } catch (e) {
    return e;
  }
}

/// Toggles an activity subscription and returns an error if unsuccessful.
Future<Object?> toggleActivitySubscription(Activity activity) async {
  try {
    await Api.get(GqlMutation.toggleActivitySubscription, {
      'id': activity.id,
      'subscribe': activity.isSubscribed,
    });
    return null;
  } catch (e) {
    return e;
  }
}

/// Pins/Unpins an activity and returns an error if unsuccessful.
Future<Object?> toggleActivityPin(Activity activity) async {
  try {
    await Api.get(GqlMutation.toggleActivityPin, {
      'id': activity.id,
      'pinned': activity.isPinned,
    });
    return null;
  } catch (e) {
    return e;
  }
}

/// Toggles a reply like and returns an error if unsuccessful.
Future<Object?> toggleReplyLike(ActivityReply reply) async {
  try {
    await Api.get(GqlMutation.toggleLike, {
      'id': reply.id,
      'type': 'ACTIVITY_REPLY',
    });
    return null;
  } catch (e) {
    return e;
  }
}

/// Deletes an activity and returns an error if unsuccessful.
Future<Object?> deleteActivity(int activityId) async {
  try {
    await Api.get(GqlMutation.deleteActivity, {'id': activityId});
    return null;
  } catch (e) {
    return e;
  }
}

/// Deletes an activity reply and returns an error if unsuccessful.
Future<Object?> deleteActivityReply(int replyId) async {
  try {
    await Api.get(GqlMutation.deleteActivityReply, {'id': replyId});
    return null;
  } catch (e) {
    return e;
  }
}

final activityProvider = StateNotifierProvider.autoDispose
    .family<ActivityNotifier, AsyncValue<ExpandedActivity>, int>(
  (ref, userId) => ActivityNotifier(userId, Options().id!),
);

class ActivityNotifier extends StateNotifier<AsyncValue<ExpandedActivity>> {
  ActivityNotifier(this.userId, this.viewerId)
      : super(const AsyncValue.loading()) {
    fetch();
  }

  final int userId;
  final int viewerId;

  Future<void> fetch() async {
    state = await AsyncValue.guard(() async {
      final replies = state.value?.replies ?? const Paged();

      final data = await Api.get(GqlQuery.activity, {
        'id': userId,
        'page': replies.next,
        if (replies.next == 1) 'withActivity': true,
      });

      final items = <ActivityReply>[];
      for (final r in data['Page']['activityReplies']) {
        final item = ActivityReply.maybe(r);
        if (item != null) items.add(item);
      }

      final activity =
          state.value?.activity ?? Activity.maybe(data['Activity'], viewerId);
      if (activity == null) throw StateError('Could not parse activity');

      return ExpandedActivity(
        activity,
        replies.withNext(
          items,
          data['Page']['pageInfo']['hasNextPage'] ?? false,
        ),
      );
    });
  }

  /// Deserializes [map] and replaces the current activity.
  /// On success, it returns the new activity.
  Activity? replaceActivity(Map<String, dynamic> map, int viewerId) {
    if (!state.hasValue) return null;
    final value = state.value!;

    final activity = Activity.maybe(map, viewerId);
    if (activity == null) return null;

    state = AsyncValue.data(ExpandedActivity(activity, value.replies));
    return activity;
  }

  /// Deserializes [map] and appends it at the end.
  void appendReply(Map<String, dynamic> map) {
    if (!state.hasValue) return;
    final value = state.value!;

    final reply = ActivityReply.maybe(map);
    if (reply == null) return;

    value.activity.replyCount++;
    state = AsyncData(ExpandedActivity(
      value.activity,
      Paged(
        items: [...value.replies.items, reply],
        hasNext: value.replies.hasNext,
        next: value.replies.next,
      ),
    ));
  }

  /// Replaces an existing reply with another one.
  void replaceReply(Map<String, dynamic> map) {
    if (!state.hasValue) return;
    final value = state.value!;

    final reply = ActivityReply.maybe(map);
    if (reply == null) return;

    for (int i = 0; i < value.replies.items.length; i++) {
      if (value.replies.items[i].id == reply.id) {
        value.replies.items[i] = reply;
        state = AsyncData(ExpandedActivity(
          value.activity,
          Paged(
            items: value.replies.items,
            hasNext: value.replies.hasNext,
            next: value.replies.next,
          ),
        ));
        return;
      }
    }
  }

  /// Removes an already deleted reply.
  void removeReply(int replyId) {
    if (!state.hasValue) return;
    final value = state.value!;

    for (int i = 0; i < value.replies.items.length; i++) {
      if (value.replies.items[i].id == replyId) {
        value.replies.items.removeAt(i);
        value.activity.replyCount--;

        state = AsyncData(ExpandedActivity(
          value.activity,
          Paged(
            items: value.replies.items,
            hasNext: value.replies.hasNext,
            next: value.replies.next,
          ),
        ));
        return;
      }
    }
  }
}
