import 'package:otraku/modules/collection/collection_models.dart';
import 'package:otraku/modules/media/media_constants.dart';
import 'package:otraku/modules/notification/notifications_model.dart';

/// Some fields are modifiable to allow for quick and simple edits.
/// But to apply those edits, the [SettingsNotifier] should be used.
class Settings {
  Settings._({
    required this.unreadNotifications,
    required this.scoreFormat,
    required this.defaultSort,
    required this.titleLanguage,
    required this.personNaming,
    required this.activityMergeTime,
    required this.splitCompletedAnime,
    required this.splitCompletedManga,
    required this.displayAdultContent,
    required this.airingNotifications,
    required this.advancedScoringEnabled,
    required this.restrictMessagesToFollowing,
    required this.advancedScores,
    required this.animeCustomLists,
    required this.mangaCustomLists,
    required this.disabledListActivity,
    required this.notificationOptions,
  });

  factory Settings(Map<String, dynamic> map) => Settings._(
        unreadNotifications: map['unreadNotificationCount'] ?? 0,
        scoreFormat: ScoreFormat.values.byName(
          map['mediaListOptions']['scoreFormat'] ?? 'POINT_10',
        ),
        defaultSort: EntrySort.fromRowOrder(
          map['mediaListOptions']['rowOrder'] ?? 'TITLE',
        ),
        titleLanguage: map['options']['titleLanguage'] ?? 'ROMAJI',
        personNaming: PersonNaming.fromText(
          map['options']['staffNameLanguage'],
        ),
        activityMergeTime: map['options']['activityMergeTime'] ?? 720,
        splitCompletedAnime: map['mediaListOptions']['animeList']
                ['splitCompletedSectionByFormat'] ??
            false,
        splitCompletedManga: map['mediaListOptions']['mangaList']
                ['splitCompletedSectionByFormat'] ??
            false,
        displayAdultContent: map['options']['displayAdultContent'] ?? false,
        airingNotifications: map['options']['airingNotifications'] ?? true,
        advancedScoringEnabled: map['mediaListOptions']['animeList']
                ['advancedScoringEnabled'] ??
            false,
        restrictMessagesToFollowing:
            map['options']['restrictMessagesToFollowing'] ?? false,
        advancedScores: List<String>.from(
          map['mediaListOptions']['animeList']['advancedScoring'] ?? <String>[],
        ),
        animeCustomLists: List<String>.from(
          map['mediaListOptions']['animeList']['customLists'] ?? <String>[],
        ),
        mangaCustomLists: List<String>.from(
          map['mediaListOptions']['mangaList']['customLists'] ?? <String>[],
        ),
        disabledListActivity: {
          for (var n in map['options']['disabledListActivity'])
            EntryStatus.values.byName(n['type']): n['disabled']
        },
        notificationOptions: {
          for (var n in map['options']['notificationOptions'])
            NotificationType.values.byName(n['type']): n['enabled']
        },
      );

  factory Settings.empty() => Settings._(
        unreadNotifications: 0,
        scoreFormat: ScoreFormat.POINT_10,
        defaultSort: EntrySort.TITLE,
        titleLanguage: 'ROMAJI',
        personNaming: PersonNaming.ROMAJI_WESTERN,
        activityMergeTime: 720,
        splitCompletedAnime: false,
        splitCompletedManga: false,
        displayAdultContent: false,
        airingNotifications: true,
        advancedScoringEnabled: false,
        restrictMessagesToFollowing: false,
        advancedScores: [],
        animeCustomLists: [],
        mangaCustomLists: [],
        disabledListActivity: {},
        notificationOptions: {},
      );

  ScoreFormat scoreFormat;
  EntrySort defaultSort;
  String titleLanguage;
  PersonNaming personNaming;
  int activityMergeTime;
  bool splitCompletedAnime;
  bool splitCompletedManga;
  bool displayAdultContent;
  bool airingNotifications;
  bool advancedScoringEnabled;
  bool restrictMessagesToFollowing;
  final int unreadNotifications;
  final List<String> advancedScores;
  final List<String> animeCustomLists;
  final List<String> mangaCustomLists;
  final Map<EntryStatus, bool> disabledListActivity;
  final Map<NotificationType, bool> notificationOptions;

  Settings copy({int unreadNotifications = 0}) => Settings._(
        unreadNotifications: unreadNotifications,
        scoreFormat: scoreFormat,
        defaultSort: defaultSort,
        titleLanguage: titleLanguage,
        personNaming: personNaming,
        activityMergeTime: activityMergeTime,
        splitCompletedAnime: splitCompletedAnime,
        splitCompletedManga: splitCompletedManga,
        displayAdultContent: displayAdultContent,
        airingNotifications: airingNotifications,
        advancedScoringEnabled: advancedScoringEnabled,
        restrictMessagesToFollowing: restrictMessagesToFollowing,
        advancedScores: [...advancedScores],
        animeCustomLists: [...animeCustomLists],
        mangaCustomLists: [...mangaCustomLists],
        disabledListActivity: {...disabledListActivity},
        notificationOptions: {...notificationOptions},
      );

  Map<String, dynamic> toMap() => {
        'titleLanguage': titleLanguage,
        'staffNameLanguage': personNaming.name,
        'activityMergeTime': activityMergeTime,
        'displayAdultContent': displayAdultContent,
        'scoreFormat': scoreFormat.name,
        'rowOrder': defaultSort.toRowOrder(),
        'advancedScoring': advancedScores,
        'advancedScoringEnabled': advancedScoringEnabled,
        'splitCompletedAnime': splitCompletedAnime,
        'splitCompletedManga': splitCompletedManga,
        'restrictMessagesToFollowing': restrictMessagesToFollowing,
        'airingNotifications': airingNotifications,
        'disabledListActivity': disabledListActivity.entries
            .map((e) => {'type': e.key.name, 'disabled': e.value})
            .toList(),
        'notificationOptions': notificationOptions.entries
            .map((e) => {'type': e.key.name, 'enabled': e.value})
            .toList(),
      };
}

enum PersonNaming {
  ROMAJI_WESTERN,
  ROMAJI,
  NATIVE;

  static PersonNaming fromText(String? s) => switch (s) {
        'ROMAJI' => ROMAJI,
        'NATIVE' => NATIVE,
        _ => ROMAJI_WESTERN,
      };
}
