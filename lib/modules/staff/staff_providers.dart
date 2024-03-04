import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otraku/common/utils/extensions.dart';
import 'package:otraku/modules/discover/discover_models.dart';
import 'package:otraku/common/models/relation.dart';
import 'package:otraku/modules/settings/settings_model.dart';
import 'package:otraku/modules/settings/settings_provider.dart';
import 'package:otraku/modules/staff/staff_models.dart';
import 'package:otraku/common/utils/api.dart';
import 'package:otraku/common/utils/graphql.dart';
import 'package:otraku/common/utils/options.dart';

/// Favorite/Unfavorite staff. Returns `true` if successful.
Future<bool> toggleFavoriteStaff(int staffId) async {
  try {
    await Api.get(GqlMutation.toggleFavorite, {'staff': staffId});
    return true;
  } catch (_) {
    return false;
  }
}

final staffProvider = FutureProvider.autoDispose.family(
  (ref, int id) async {
    final data = await Api.get(
      GqlQuery.staff,
      {'id': id, 'withInfo': true},
    );

    final settings =
        ref.watch(settingsProvider).valueOrNull ?? Settings.empty();
    return Staff(data['Staff'], settings.personNaming);
  },
);

final staffRelationsProvider = AsyncNotifierProvider.autoDispose
    .family<StaffRelationsNotifier, StaffRelations, int>(
  StaffRelationsNotifier.new,
);

final staffFilterProvider =
    NotifierProvider.autoDispose.family<StaffFilterNotifier, StaffFilter, int>(
  StaffFilterNotifier.new,
);

class StaffRelationsNotifier
    extends AutoDisposeFamilyAsyncNotifier<StaffRelations, int> {
  late StaffFilter filter;

  @override
  FutureOr<StaffRelations> build(arg) async {
    filter = ref.watch(staffFilterProvider(arg));
    return await _fetch(const StaffRelations(), null);
  }

  Future<void> fetch(bool onCharacters) async {
    final oldState = state.valueOrNull ?? const StaffRelations();
    if (onCharacters) {
      if (!oldState.charactersAndMedia.hasNext) return;
    } else {
      if (!oldState.roles.hasNext) return;
    }
    state = await AsyncValue.guard(() => _fetch(oldState, onCharacters));
  }

  Future<StaffRelations> _fetch(
    StaffRelations oldState,
    bool? onCharacters,
  ) async {
    final variables = {
      'id': arg,
      'onList': filter.inLists,
      'sort': filter.sort.name,
      if (filter.ofAnime != null) 'type': filter.ofAnime! ? 'ANIME' : 'MANGA',
    };

    if (onCharacters == null) {
      variables['withCharacters'] = true;
      variables['withRoles'] = true;
    } else if (onCharacters) {
      variables['withCharacters'] = true;
      variables['page'] = oldState.charactersAndMedia.next;
    } else {
      variables['withRoles'] = true;
      variables['page'] = oldState.roles.next;
    }

    var data = await Api.get(GqlQuery.staff, variables);
    data = data['Staff'];

    var charactersAndMedia = oldState.charactersAndMedia;
    var roles = oldState.roles;

    if (onCharacters == null || onCharacters) {
      final map = data['characterMedia'];
      final items = <(Relation, Relation)>[];
      for (final m in map['edges']) {
        final media = Relation(
          id: m['node']['id'],
          title: m['node']['title']['userPreferred'],
          imageUrl: m['node']['coverImage'][Options().imageQuality.value],
          subtitle: StringUtil.tryNoScreamingSnakeCase(m['node']['format']),
          type: m['node']['type'] == 'ANIME'
              ? DiscoverType.Anime
              : DiscoverType.Manga,
        );

        for (final c in m['characters']) {
          if (c == null) continue;

          items.add((
            Relation(
              id: c['id'],
              title: c['name']['userPreferred'],
              imageUrl: c['image']['large'],
              type: DiscoverType.Character,
              subtitle: StringUtil.tryNoScreamingSnakeCase(
                m['characterRole'],
              ),
            ),
            media,
          ));
        }
      }

      charactersAndMedia = charactersAndMedia.withNext(
        items,
        map['pageInfo']['hasNextPage'] ?? false,
      );
    }

    if (onCharacters == null || !onCharacters) {
      final map = data['staffMedia'];
      final items = <Relation>[];
      for (final s in map['edges']) {
        items.add(Relation(
          id: s['node']['id'],
          title: s['node']['title']['userPreferred'],
          imageUrl: s['node']['coverImage'][Options().imageQuality.value],
          subtitle: s['staffRole'],
          type: s['node']['type'] == 'ANIME'
              ? DiscoverType.Anime
              : DiscoverType.Manga,
        ));
      }

      roles = roles.withNext(
        items,
        map['pageInfo']['hasNextPage'] ?? false,
      );
    }

    return StaffRelations(charactersAndMedia: charactersAndMedia, roles: roles);
  }
}

class StaffFilterNotifier extends AutoDisposeFamilyNotifier<StaffFilter, int> {
  @override
  StaffFilter build(arg) => StaffFilter();

  @override
  set state(StaffFilter newState) => super.state = newState;
}
