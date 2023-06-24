import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';
import 'package:otraku/common/utils/consts.dart';
import 'package:otraku/modules/discover/discover_models.dart';
import 'package:otraku/modules/filter/filter_providers.dart';
import 'package:otraku/modules/home/home_provider.dart';
import 'package:otraku/modules/media/media_models.dart';
import 'package:otraku/common/widgets/layouts/top_bar.dart';
import 'package:otraku/common/widgets/link_tile.dart';
import 'package:otraku/common/widgets/grids/sliver_grid_delegates.dart';
import 'package:otraku/common/widgets/loaders.dart/loaders.dart';
import 'package:otraku/common/widgets/overlays/dialogs.dart';
import 'package:otraku/common/widgets/overlays/toast.dart';

class MediaInfoView extends StatelessWidget {
  const MediaInfoView(this.media, this.scrollCtrl);

  final Media media;
  final ScrollController scrollCtrl;

  @override
  Widget build(BuildContext context) {
    final info = media.info;

    final infoTitles = [
      'Status',
      'Episodes',
      'Duration',
      'Chapters',
      'Volumes',
      'Start Date',
      'End Date',
      'Season',
      'Average Score',
      'Mean Score',
      'Popularity',
      'Favourites',
      'Source',
      'Origin',
    ];

    final infoData = [
      info.status,
      info.episodes,
      info.duration,
      info.chapters,
      info.volumes,
      info.startDate,
      info.endDate,
      info.season,
      info.averageScore,
      info.meanScore,
      info.popularity,
      info.favourites,
      info.source,
      info.countryOfOrigin,
    ];

    for (int i = infoData.length - 1; i >= 0; i--) {
      if (infoData[i] == null) {
        infoData.removeAt(i);
        infoTitles.removeAt(i);
      }
    }

    return Consumer(
      builder: (context, ref, _) => CustomScrollView(
        controller: scrollCtrl,
        slivers: [
          if (info.description.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: Consts.padding,
                child: GestureDetector(
                  child: Card(
                    child: Padding(
                      padding: Consts.padding,
                      child: Text(
                        info.description,
                        maxLines: 4,
                        overflow: TextOverflow.fade,
                      ),
                    ),
                  ),
                  onTap: () => showPopUp(
                    context,
                    TextDialog(title: 'Description', text: info.description),
                  ),
                ),
              ),
            )
          else
            const SliverToBoxAdapter(child: SizedBox(height: 10)),
          SliverPadding(
            padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMinWidthAndFixedHeight(
                height: Consts.tapTargetSize,
                minWidth: 130,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) => Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          infoTitles[i],
                          maxLines: 1,
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        Text(infoData[i].toString(), maxLines: 1),
                      ],
                    ),
                  ),
                ),
                childCount: infoData.length,
              ),
            ),
          ),
          if (info.genres.isNotEmpty)
            _PlainScrollCards(
              title: 'Genres',
              items: info.genres,
              onTap: (i) {
                ref.read(searchProvider(null).notifier).state = null;
                final notifier = ref.read(discoverFilterProvider);
                notifier.type = info.type;

                final filter = notifier.filter.clear();
                filter.genreIn.add(info.genres[i]);
                notifier.filter = filter;

                ref.read(homeProvider).homeTab = HomeTab.discover;
                Navigator.popUntil(context, (r) => r.isFirst);
              },
            ),
          if (info.tags.isNotEmpty) _TagScrollCards(info, ref),
          if (info.studios.isNotEmpty)
            _PlainScrollCards(
              title: 'Studios',
              items: info.studios.keys.toList(),
              onTap: (index) => LinkTile.openView(
                context: context,
                id: info.studios[info.studios.keys.elementAt(index)]!,
                imageUrl: info.studios.keys.elementAt(index),
                discoverType: DiscoverType.studio,
              ),
            ),
          if (info.producers.isNotEmpty)
            _PlainScrollCards(
              title: 'Producers',
              items: info.producers.keys.toList(),
              onTap: (i) => LinkTile.openView(
                context: context,
                id: info.producers[info.producers.keys.elementAt(i)]!,
                imageUrl: info.producers.keys.elementAt(i),
                discoverType: DiscoverType.studio,
              ),
            ),
          if (info.externalLinks.isNotEmpty)
            _ExternalLinkScrollCards(info.externalLinks),
          if (info.hashtag != null) _Title('Hashtag', info.hashtag!),
          if (info.romajiTitle != null) _Title('Romaji', info.romajiTitle!),
          if (info.englishTitle != null) _Title('English', info.englishTitle!),
          if (info.nativeTitle != null) _Title('Native', info.nativeTitle!),
          if (info.synonyms.isNotEmpty)
            _Title('Synonyms', info.synonyms.join(', ')),
          const SliverFooter(),
        ],
      ),
    );
  }
}

class _ScrollCards extends StatelessWidget {
  const _ScrollCards({
    required this.title,
    required this.itemCount,
    required this.builder,
    required this.onTap,
    required this.onLongPress,
    this.trailingAction,
  });

  final String title;
  final int itemCount;
  final Widget Function(BuildContext, int) builder;
  final void Function(int) onTap;
  final void Function(int) onLongPress;
  final Widget? trailingAction;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
              const Spacer(),
              if (trailingAction != null) trailingAction!,
            ],
          ),
          if (trailingAction == null) const SizedBox(height: 10),
          SizedBox(
            height: 42,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 10, bottom: 2),
              itemCount: itemCount,
              itemBuilder: (context, i) => GestureDetector(
                onTap: () => onTap(i),
                onLongPress: () => onLongPress(i),
                child: Card(
                  margin: const EdgeInsets.only(right: 10),
                  child: Padding(
                    padding: Consts.padding,
                    child: builder(context, i),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _PlainScrollCards extends StatelessWidget {
  const _PlainScrollCards({
    required this.title,
    required this.items,
    required this.onTap,
  });

  final String title;
  final List<String> items;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    return _ScrollCards(
      title: title,
      itemCount: items.length,
      onTap: onTap,
      onLongPress: (i) => Toast.copy(context, items[i]),
      builder: (context, i) => Text(items[i]),
    );
  }
}

class _ExternalLinkScrollCards extends StatelessWidget {
  const _ExternalLinkScrollCards(this.items);

  final List<ExternalLink> items;

  @override
  Widget build(BuildContext context) {
    return _ScrollCards(
      title: "External Links",
      itemCount: items.length,
      onTap: (i) => Toast.launch(context, items[i].url),
      onLongPress: (i) => Toast.copy(context, items[i].url),
      builder: (context, i) => Row(
        children: [
          if (items[i].color != null)
            Container(
              padding: Consts.padding,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                borderRadius: Consts.borderRadiusMin,
                color: items[i].color,
              ),
            ),
          Text(items[i].site)
        ],
      ),
    );
  }
}

class _TagScrollCards extends StatefulWidget {
  const _TagScrollCards(this.info, this.ref);

  final MediaInfo info;
  final WidgetRef ref;

  @override
  State<_TagScrollCards> createState() => _TagScrollCardsState();
}

class _TagScrollCardsState extends State<_TagScrollCards> {
  bool? _showSpoilers;

  @override
  void initState() {
    super.initState();
    for (final t in widget.info.tags) {
      if (t.isSpoiler) {
        _showSpoilers = false;
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tags = _showSpoilers == null || _showSpoilers!
        ? widget.info.tags
        : widget.info.tags.where((t) => !t.isSpoiler).toList();

    final spoilerTextStyle = Theme.of(context)
        .textTheme
        .bodyLarge
        ?.copyWith(color: Theme.of(context).colorScheme.error);

    return _ScrollCards(
      title: 'Tags',
      itemCount: tags.length,
      onTap: (i) {
        widget.ref.read(searchProvider(null).notifier).state = null;
        final notifier = widget.ref.read(discoverFilterProvider);
        notifier.type = widget.info.type;

        final filter = notifier.filter.clear();
        filter.tagIn.add(tags[i].name);
        notifier.filter = filter;

        widget.ref.read(homeProvider).homeTab = HomeTab.discover;
        Navigator.popUntil(context, (r) => r.isFirst);
      },
      onLongPress: (i) => showPopUp(
        context,
        TextDialog(title: tags[i].name, text: tags[i].desciption),
      ),
      trailingAction: _showSpoilers != null
          ? TopBarIcon(
              icon: _showSpoilers!
                  ? Ionicons.eye_off_outline
                  : Ionicons.eye_outline,
              tooltip: _showSpoilers! ? 'Hide Spoilers' : 'Show Spoilers',
              onTap: () => setState(() => _showSpoilers = !_showSpoilers!),
            )
          : null,
      builder: (context, i) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tags[i].name,
            style: tags[i].isSpoiler ? spoilerTextStyle : null,
          ),
          const SizedBox(width: 5),
          Text(
            '${tags[i].rank}%',
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.label, this.title);

  final String label;
  final String title;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: 90,
              child:
                  Text(label, style: Theme.of(context).textTheme.labelMedium),
            ),
            Flexible(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Toast.copy(context, title),
                child: Text(
                  title,
                  maxLines: null,
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
