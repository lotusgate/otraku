import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otraku/modules/character/character_models.dart';
import 'package:otraku/common/models/tile_item.dart';
import 'package:otraku/modules/favorites/favorites_model.dart';
import 'package:otraku/modules/media/media_models.dart';
import 'package:otraku/modules/staff/staff_models.dart';
import 'package:otraku/modules/studio/studio_models.dart';
import 'package:otraku/common/utils/api.dart';
import 'package:otraku/common/utils/graphql.dart';

final favoritesProvider =
    AsyncNotifierProvider.autoDispose.family<FavoritesNotifier, Favorites, int>(
  FavoritesNotifier.new,
);

class FavoritesNotifier extends AutoDisposeFamilyAsyncNotifier<Favorites, int> {
  @override
  FutureOr<Favorites> build(int arg) => _fetch(const Favorites(), null);

  Future<void> fetch(FavoritesTab tab) async {
    final oldState = state.valueOrNull ?? const Favorites();
    switch (tab) {
      case FavoritesTab.anime:
        if (!oldState.anime.hasNext) return;
      case FavoritesTab.manga:
        if (!oldState.manga.hasNext) return;
      case FavoritesTab.characters:
        if (!oldState.characters.hasNext) return;
      case FavoritesTab.staff:
        if (!oldState.staff.hasNext) return;
      case FavoritesTab.studios:
        if (!oldState.studios.hasNext) return;
    }
    state = await AsyncValue.guard(() => _fetch(oldState, tab));
  }

  Future<Favorites> _fetch(Favorites oldState, FavoritesTab? tab) async {
    final variables = <String, dynamic>{'userId': arg};

    if (tab == null) {
      variables['withAnime'] = true;
      variables['withManga'] = true;
      variables['withCharacters'] = true;
      variables['withStaff'] = true;
      variables['withStudios'] = true;
    } else if (tab == FavoritesTab.anime) {
      variables['withAnime'] = true;
      variables['page'] = oldState.anime.next;
    } else if (tab == FavoritesTab.manga) {
      variables['withManga'] = true;
      variables['page'] = oldState.manga.next;
    } else if (tab == FavoritesTab.characters) {
      variables['withCharacters'] = true;
      variables['page'] = oldState.characters.next;
    } else if (tab == FavoritesTab.staff) {
      variables['withStaff'] = true;
      variables['page'] = oldState.staff.next;
    } else {
      variables['withStudios'] = true;
      variables['page'] = oldState.studios.next;
    }

    var data = await Api.get(GqlQuery.favorites, variables);
    data = data['User']['favourites'];

    var anime = oldState.anime;
    var manga = oldState.manga;
    var characters = oldState.characters;
    var staff = oldState.staff;
    var studios = oldState.studios;

    if (tab == null || tab == FavoritesTab.anime) {
      final map = data['anime'];
      final items = <TileItem>[];
      for (final a in map['nodes']) {
        items.add(mediaItem(a));
      }

      anime = anime.withNext(
        items,
        map['pageInfo']['hasNextPage'] ?? false,
        map['pageInfo']['total'],
      );
    }

    if (tab == null || tab == FavoritesTab.manga) {
      final map = data['manga'];
      final items = <TileItem>[];
      for (final m in map['nodes']) {
        items.add(mediaItem(m));
      }

      manga = manga.withNext(
        items,
        map['pageInfo']['hasNextPage'] ?? false,
        map['pageInfo']['total'],
      );
    }

    if (tab == null || tab == FavoritesTab.characters) {
      final map = data['characters'];
      final items = <TileItem>[];
      for (final c in map['nodes']) {
        items.add(characterItem(c));
      }

      characters = characters.withNext(
        items,
        map['pageInfo']['hasNextPage'] ?? false,
        map['pageInfo']['total'],
      );
    }

    if (tab == null || tab == FavoritesTab.staff) {
      final map = data['staff'];
      final items = <TileItem>[];
      for (final s in map['nodes']) {
        items.add(staffItem(s));
      }

      staff = staff.withNext(
        items,
        map['pageInfo']['hasNextPage'] ?? false,
        map['pageInfo']['total'],
      );
    }

    if (tab == null || tab == FavoritesTab.studios) {
      final map = data['studios'];
      final items = <StudioItem>[];
      for (final s in map['nodes']) {
        items.add(StudioItem(s));
      }

      studios = studios.withNext(
        items,
        map['pageInfo']['hasNextPage'] ?? false,
        map['pageInfo']['total'],
      );
    }

    return Favorites(
      anime: anime,
      manga: manga,
      characters: characters,
      staff: staff,
      studios: studios,
    );
  }
}
