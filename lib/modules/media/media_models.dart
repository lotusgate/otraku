import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otraku/modules/collection/collection_models.dart';
import 'package:otraku/common/models/paged.dart';
import 'package:otraku/common/models/relation.dart';
import 'package:otraku/common/models/tile_item.dart';
import 'package:otraku/modules/discover/discover_models.dart';
import 'package:otraku/modules/edit/edit_model.dart';
import 'package:otraku/modules/media/media_constants.dart';
import 'package:otraku/modules/tag/tag_models.dart';
import 'package:otraku/common/utils/convert.dart';
import 'package:otraku/common/utils/options.dart';

TileItem mediaItem(Map<String, dynamic> map) => TileItem(
      id: map['id'],
      type: DiscoverType.anime,
      title: map['title']['userPreferred'],
      imageUrl: map['coverImage'][Options().imageQuality.value],
    );

class Media {
  Media(this.edit, this.info, this.stats, this.relations);

  Edit edit;
  final MediaInfo info;
  final MediaStats stats;
  final List<RelatedMedia> relations;
}

enum MediaTab {
  info,
  relations,
  characters,
  staff,
  reviews,
  following,
  recommendations,
  statistics,
}

class MediaRelations {
  const MediaRelations({
    this.characters = const AsyncValue.loading(),
    this.staff = const AsyncValue.loading(),
    this.reviews = const AsyncValue.loading(),
    this.recommendations = const AsyncValue.loading(),
    this.languageToVoiceActors = const {},
    this.language = '',
  });

  final AsyncValue<Paged<Relation>> characters;
  final AsyncValue<Paged<Relation>> staff;
  final AsyncValue<Paged<RelatedReview>> reviews;
  final AsyncValue<Paged<Recommendation>> recommendations;

  /// For each language, a list of voice actors
  /// is mapped to the corresponding media's id.
  final Map<String, Map<int, List<Relation>>> languageToVoiceActors;

  /// The currently selected language.
  final String language;

  Iterable<String> get languages => languageToVoiceActors.keys;

  /// Returns the characters, along with their voice actors,
  /// corresponding to the current [language]. If there are
  /// multiple actors, the given character is repeated for each actor.
  List<(Relation, Relation?)> getCharactersAndVoiceActors() {
    final chars = characters.valueOrNull?.items;
    if (chars == null) return [];

    final actorsPerMedia = languageToVoiceActors[language];
    if (actorsPerMedia == null) return [for (final c in chars) (c, null)];

    final charactersAndVoiceActors = <(Relation, Relation?)>[];
    for (final c in chars) {
      final actors = actorsPerMedia[c.id];
      if (actors == null || actors.isEmpty) {
        charactersAndVoiceActors.add((c, null));
        continue;
      }

      for (final va in actors) {
        charactersAndVoiceActors.add((c, va));
      }
    }

    return charactersAndVoiceActors;
  }

  MediaRelations copyWith({
    AsyncValue<Paged<Relation>>? characters,
    AsyncValue<Paged<Relation>>? staff,
    AsyncValue<Paged<RelatedReview>>? reviews,
    AsyncValue<Paged<Recommendation>>? recommendations,
    Map<String, Map<int, List<Relation>>>? languageToVoiceActors,
    String? language,
  }) =>
      MediaRelations(
        characters: characters ?? this.characters,
        staff: staff ?? this.staff,
        reviews: reviews ?? this.reviews,
        recommendations: recommendations ?? this.recommendations,
        languageToVoiceActors:
            languageToVoiceActors ?? this.languageToVoiceActors,
        language: language ?? this.language,
      );
}

class RelatedMedia {
  RelatedMedia._({
    required this.id,
    required this.type,
    required this.title,
    required this.imageUrl,
    required this.relationType,
    required this.format,
    required this.status,
  });

  factory RelatedMedia(Map<String, dynamic> map) => RelatedMedia._(
        id: map['node']['id'],
        title: map['node']['title']['userPreferred'],
        imageUrl: map['node']['coverImage'][Options().imageQuality.value],
        relationType: Convert.clarifyEnum(map['relationType']),
        format: Convert.clarifyEnum(map['node']['format']),
        status: Convert.clarifyEnum(map['node']['status']),
        type: map['node']['type'] == 'ANIME'
            ? DiscoverType.anime
            : DiscoverType.manga,
      );

  final int id;
  final DiscoverType type;
  final String title;
  final String imageUrl;
  final String? relationType;
  final String? format;
  final String? status;
}

class RelatedReview {
  RelatedReview._({
    required this.reviewId,
    required this.userId,
    required this.avatar,
    required this.username,
    required this.summary,
    required this.rating,
  });

  static RelatedReview? maybe(Map<String, dynamic> map) {
    if (map['user'] == null) return null;

    return RelatedReview._(
      reviewId: map['id'],
      userId: map['user']['id'],
      username: map['user']['name'] ?? '',
      summary: map['summary'] ?? '',
      avatar: map['user']['avatar']['large'],
      rating: '${map['rating']}/${map['ratingAmount']}',
    );
  }

  final int reviewId;
  final int userId;
  final String username;
  final String avatar;
  final String summary;
  final String rating;
}

class MediaFollowing {
  MediaFollowing._({
    required this.status,
    required this.score,
    required this.notes,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.scoreFormat,
  });

  factory MediaFollowing(Map<String, dynamic> map) => MediaFollowing._(
        status: Convert.clarifyEnum(map['status'])!,
        score: (map['score'] ?? 0).toDouble(),
        notes: map['notes'],
        userId: map['user']['id'],
        userName: map['user']['name'],
        userAvatar: map['user']['avatar']['large'],
        scoreFormat: ScoreFormat.values.byName(
          map['user']['mediaListOptions']['scoreFormat'] ?? 'POINT_10_DECIMAL',
        ),
      );

  final String status;
  final double score;
  final String? notes;
  final int userId;
  final String userName;
  final String userAvatar;
  final ScoreFormat scoreFormat;
}

class Recommendation {
  Recommendation._({
    required this.id,
    required this.rating,
    required this.userRating,
    required this.title,
    required this.type,
    required this.imageUrl,
  });

  factory Recommendation(Map<String, dynamic> map) {
    bool? userRating;
    if (map['userRating'] == 'RATE_UP') userRating = true;
    if (map['userRating'] == 'RATE_DOWN') userRating = false;

    return Recommendation._(
      id: map['mediaRecommendation']['id'],
      rating: map['rating'] ?? 0,
      userRating: userRating,
      title: map['mediaRecommendation']['title']['userPreferred'],
      type: map['type'] == 'ANIME' ? DiscoverType.anime : DiscoverType.manga,
      imageUrl: map['mediaRecommendation']['coverImage']
          [Options().imageQuality.value],
    );
  }

  final int id;
  int rating;
  bool? userRating;
  final String title;
  final String? imageUrl;
  final DiscoverType type;
}

class MediaInfo {
  MediaInfo._({
    required this.id,
    required this.type,
    required this.favourites,
    required this.isFavorite,
    required this.preferredTitle,
    required this.romajiTitle,
    required this.englishTitle,
    required this.nativeTitle,
    required this.synonyms,
    required this.cover,
    required this.extraLargeCover,
    required this.banner,
    required this.description,
    required this.format,
    required this.status,
    required this.nextEpisode,
    required this.airingAt,
    required this.episodes,
    required this.duration,
    required this.chapters,
    required this.volumes,
    required this.startDate,
    required this.endDate,
    required this.season,
    required this.averageScore,
    required this.meanScore,
    required this.popularity,
    required this.genres,
    required this.source,
    required this.hashtag,
    required this.siteUrl,
    required this.countryOfOrigin,
    required this.isAdult,
  });

  final int id;
  final DiscoverType type;
  final int favourites;
  bool isFavorite;
  final String? preferredTitle;
  final String? romajiTitle;
  final String? englishTitle;
  final String? nativeTitle;
  final List<String> synonyms;
  final String description;
  final String cover;
  final String extraLargeCover;
  final String? banner;
  final String? format;
  final String? status;
  final int? nextEpisode;
  final int? airingAt;
  final int? episodes;
  final String? duration;
  final int? chapters;
  final int? volumes;
  final String? startDate;
  final String? endDate;
  final String? season;
  final String? averageScore;
  final String? meanScore;
  final int? popularity;
  final List<String> genres;
  final studios = <String, int>{};
  final producers = <String, int>{};
  final tags = <Tag>[];
  final String? source;
  final String? hashtag;
  final String? siteUrl;
  final String? countryOfOrigin;
  final bool isAdult;
  final externalLinks = <ExternalLink>[];

  factory MediaInfo(Map<String, dynamic> map) {
    String? duration;
    if (map['duration'] != null) {
      final time = map['duration'];
      final hours = time ~/ 60;
      final minutes = time % 60;
      duration =
          '${hours != 0 ? '$hours hours ' : ''}${minutes != 0 ? '$minutes mins' : ''}';
    }

    String? season;
    if (map['season'] != null) {
      season = map['season'];
      season = season![0] + season.substring(1).toLowerCase();
      if (map['seasonYear'] != null) season += ' ${map["seasonYear"]}';
    }

    final model = MediaInfo._(
      id: map['id'],
      type: map['type'] == 'ANIME' ? DiscoverType.anime : DiscoverType.manga,
      isFavorite: map['isFavourite'] ?? false,
      favourites: map['favourites'] ?? 0,
      preferredTitle: map['title']['userPreferred'],
      romajiTitle: map['title']['romaji'],
      englishTitle: map['title']['english'],
      nativeTitle: map['title']['native'],
      synonyms: List<String>.from(map['synonyms'] ?? [], growable: false),
      description: Convert.clearHtml(map['description']),
      cover: map['coverImage'][Options().imageQuality.value],
      extraLargeCover: map['coverImage']['extraLarge'],
      banner: map['bannerImage'],
      format: Convert.clarifyEnum(map['format']),
      status: Convert.clarifyEnum(map['status']),
      nextEpisode: map['nextAiringEpisode']?['episode'],
      airingAt: map['nextAiringEpisode']?['airingAt'],
      episodes: map['episodes'],
      duration: duration,
      chapters: map['chapters'],
      volumes: map['volumes'],
      startDate: Convert.mapToDateStr(map['startDate']),
      endDate: Convert.mapToDateStr(map['endDate']),
      season: season,
      averageScore:
          map['averageScore'] != null ? '${map["averageScore"]}%' : null,
      meanScore: map['meanScore'] != null ? '${map["meanScore"]}%' : null,
      popularity: map['popularity'],
      genres: List<String>.from(map['genres'] ?? [], growable: false),
      source: Convert.clarifyEnum(map['source']),
      hashtag: map['hashtag'],
      siteUrl: map['siteUrl'],
      countryOfOrigin: Convert.countryCodes[map['countryOfOrigin']],
      isAdult: map['isAdult'] ?? false,
    );

    if (map['studios'] != null) {
      final List<dynamic> companies = map['studios']['edges'];
      for (final company in companies) {
        if (company['isMain']) {
          model.studios[company['node']['name']] = company['node']['id'];
        } else {
          model.producers[company['node']['name']] = company['node']['id'];
        }
      }
    }

    if (map['tags'] != null) {
      for (final tag in map['tags']) {
        model.tags.add(Tag(tag));
      }
    }

    if (map['externalLinks'] != null) {
      for (final link in map['externalLinks']) {
        model.externalLinks.add(ExternalLink(link));
      }
    }

    return model;
  }
}

class ExternalLink {
  ExternalLink._({required this.url, required this.site, required this.color});

  factory ExternalLink(Map<String, dynamic> map) => ExternalLink._(
        url: map['url'],
        site: map['site'],
        color: map['color'] != null
            ? Color(
                int.parse(map['color'].substring(1, 7), radix: 16) + 0xFF000000)
            : null,
      );

  final String url;
  final String site;
  final Color? color;
}

class MediaStats {
  MediaStats._();

  final rankTexts = <String>[];
  final rankTypes = <bool>[];

  final scoreNames = <int>[];
  final scoreValues = <int>[];

  final statusNames = <String>[];
  final statusValues = <int>[];

  factory MediaStats(Map<String, dynamic> map) {
    final model = MediaStats._();

    // The key is the text and the value signals
    // if the rank is about rating or popularity.
    if (map['rankings'] != null) {
      for (final rank in map['rankings']) {
        final String when = (rank['allTime'] ?? false)
            ? 'Ever'
            : rank['season'] != null
                ? '${Convert.clarifyEnum(rank['season'])} ${rank['year'] ?? ''}'
                : (rank['year'] ?? '').toString();
        if (when.isEmpty) continue;

        if (rank['type'] == 'RATED') {
          model.rankTexts.add('#${rank["rank"]} Highest Rated $when');
          model.rankTypes.add(true);
        } else {
          model.rankTexts.add('#${rank["rank"]} Most Popular $when');
          model.rankTypes.add(false);
        }
      }
    }

    if (map['stats'] != null) {
      if (map['stats']['scoreDistribution'] != null) {
        for (final s in map['stats']['scoreDistribution']) {
          model.scoreNames.add(s['score']);
          model.scoreValues.add(s['amount']);
        }
      }

      if (map['stats']['statusDistribution'] != null) {
        for (final s in map['stats']['statusDistribution']) {
          int index = -1;
          for (int i = 0; i < model.statusValues.length; i++) {
            if (model.statusValues[i] < s['amount']) {
              model.statusValues.insert(i, s['amount']);
              index = i;
              break;
            }
          }

          if (index < 0) {
            index = model.statusValues.length;
            model.statusValues.add(s['amount']);
          }

          model.statusNames.insert(
            index,
            Convert.adaptListStatus(
              EntryStatus.values.byName(s['status']),
              map['type'] == 'ANIME',
            ),
          );
        }
      }
    }

    return model;
  }
}
