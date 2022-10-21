import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otraku/edit/edit_model.dart';
import 'package:otraku/settings/settings_provider.dart';
import 'package:otraku/utils/api.dart';
import 'package:otraku/utils/graphql.dart';

/// Updates an entry and returns the entry id or an error if unsuccessful. This
/// is useful, if the entry didn't exist up until now, i.e. there wasn't an id.
Future<Object> updateEntry(Edit edit) async {
  try {
    final data = await Api.get(GqlMutation.updateEntry, edit.toMap());
    return data['SaveMediaListEntry']['id'];
  } catch (e) {
    return e;
  }
}

/// Increments entry progress and returns the entry's custom lists
/// (`List<String>`) or an error if unsuccessful. The lists are
/// used to easily update the entry locally.
Future<Object> updateProgress(int mediaId, int progress) async {
  try {
    final data = await Api.get(
      GqlMutation.updateProgress,
      {'mediaId': mediaId, 'progress': progress},
    );

    final entries = data['SaveMediaListEntry']?['customLists']?.entries;
    if (entries == null) return <String>[];

    final customLists = <String>[];
    for (final e in entries) {
      if (e.value) customLists.add(e.key.toString().toLowerCase());
    }
    return customLists;
  } catch (e) {
    return e;
  }
}

/// Removes an entry and returns an error if unsuccessful.
Future<Object?> removeEntry(int entryId) async {
  try {
    await Api.get(GqlMutation.removeEntry, {'entryId': entryId});
    return null;
  } catch (e) {
    return e;
  }
}

final currentEditProvider = FutureProvider.autoDispose.family<Edit, int>(
  (ref, id) async {
    final data = await Api.get(GqlQuery.entry, {'mediaId': id});
    return Edit(data['Media'], ref.watch(settingsProvider));
  },
);

final editProvider = StateProvider.autoDispose<Edit>((ref) => Edit.temp());
