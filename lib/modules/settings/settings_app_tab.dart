import 'package:flutter/material.dart';
import 'package:otraku/modules/discover/discover_models.dart';
import 'package:otraku/modules/filter/chip_selector.dart';
import 'package:otraku/common/utils/consts.dart';
import 'package:otraku/modules/home/home_provider.dart';
import 'package:otraku/modules/media/media_constants.dart';
import 'package:otraku/common/utils/convert.dart';
import 'package:otraku/common/utils/options.dart';
import 'package:otraku/common/widgets/fields/checkbox_field.dart';
import 'package:otraku/common/widgets/fields/drop_down_field.dart';
import 'package:otraku/common/widgets/grids/sliver_grid_delegates.dart';
import 'package:otraku/common/widgets/layouts/scaffolds.dart';
import 'package:otraku/common/widgets/layouts/segment_switcher.dart';
import 'package:otraku/common/widgets/loaders.dart/loaders.dart';
import 'package:otraku/modules/settings/theme_preview.dart';
import 'package:otraku/common/widgets/overlays/sheets.dart';

class SettingsAppTab extends StatelessWidget {
  const SettingsAppTab(this.scrollCtrl);

  final ScrollController scrollCtrl;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: scrollCtrl,
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(height: scaffoldOffsets(context).top),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              'Theme',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 5, bottom: 10),
            child: SegmentSwitcher(
              current: Options().themeMode.index,
              items: const ['System', 'Light', 'Dark'],
              onChanged: (i) =>
                  Options().themeMode = ThemeMode.values.elementAt(i),
            ),
          ),
        ),
        const ThemePreview(),
        SliverToBoxAdapter(
          child: CheckBoxField(
            title: 'Pure Black Dark Theme',
            initial: Options().pureBlackDarkTheme,
            onChanged: (v) => Options().pureBlackDarkTheme = v,
          ),
        ),
        _SheetExpandButton(
          title: 'Default Sortings',
          initialSheetHeight: 250,
          sheetContentBuilder: (context, scrollCtrl) => ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.symmetric(vertical: 10),
            children: [
              EntrySortChipSelector(
                title: 'Collection Anime Sorting',
                current: Options().defaultAnimeSort,
                onChanged: (v) => Options().defaultAnimeSort = v,
              ),
              EntrySortChipSelector(
                title: 'Collection Manga Sorting',
                current: Options().defaultMangaSort,
                onChanged: (v) => Options().defaultMangaSort = v,
              ),
              ChipSelector(
                title: 'Discover Media Sorting',
                options: MediaSort.values.map((s) => s.label).toList(),
                current: Options().defaultDiscoverSort.index,
                mustHaveSelected: true,
                onChanged: (i) => Options().defaultDiscoverSort =
                    MediaSort.values.elementAt(i!),
              ),
            ],
          ),
        ),
        _SheetExpandButton(
          title: 'Collection Previews',
          initialSheetHeight: Consts.tapTargetSize * 3 + 150,
          sheetContentBuilder: (context, scrollCtrl) => ListView(
            controller: scrollCtrl,
            padding: Consts.padding,
            children: [
              CheckBoxField(
                title: 'Anime Collection Preview',
                initial: Options().animeCollectionPreview,
                onChanged: (v) => Options().animeCollectionPreview = v,
              ),
              CheckBoxField(
                title: 'Manga Collection Preview',
                initial: Options().mangaCollectionPreview,
                onChanged: (v) => Options().mangaCollectionPreview = v,
              ),
              const SizedBox(height: 5),
              Text(
                'Collection previews only load your current and repeated '
                'media, which results in faster loading times. Disabling '
                'a preview means the whole collection will be loaded at once.',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              CheckBoxField(
                title: 'Exclusive Airing Sort for Anime Preview',
                initial: Options().airingSortForPreview,
                onChanged: (v) => Options().airingSortForPreview = v,
              ),
              const SizedBox(height: 5),
              Text(
                'Anime collection preview will sort anime by '
                'airing time, instead of the default sort.',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
        ),
        _SheetExpandButton(
          title: 'Grid Views',
          initialSheetHeight: 250,
          sheetContentBuilder: (context, scrollCtrl) => ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.symmetric(vertical: 10),
            children: [
              ChipSelector(
                title: 'Discover View',
                options: const ['Detailed List', 'Simple Grid'],
                current: Options().discoverItemView,
                onChanged: (val) => Options().discoverItemView = val!,
                mustHaveSelected: true,
              ),
              ChipSelector(
                title: 'Collection View',
                options: const ['Detailed List', 'Simple Grid'],
                current: Options().collectionItemView,
                onChanged: (val) => Options().collectionItemView = val!,
                mustHaveSelected: true,
              ),
              ChipSelector(
                title: 'Collection Preview View',
                options: const ['Detailed List', 'Simple Grid'],
                current: Options().collectionPreviewItemView,
                onChanged: (val) => Options().collectionPreviewItemView = val!,
                mustHaveSelected: true,
              ),
            ],
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 10)),
        SliverGrid(
          gridDelegate: const SliverGridDelegateWithMinWidthAndFixedHeight(
            minWidth: 160,
            height: 75,
          ),
          delegate: SliverChildListDelegate.fixed([
            DropDownField<int>(
              title: 'Startup Page',
              value: Options().defaultHomeTab.index,
              items: {
                for (final t in HomeTab.values) t.title: t.index,
              },
              onChanged: (v) => Options().defaultHomeTab = HomeTab.values[v],
            ),
            DropDownField<DiscoverType>(
              title: 'Default Discover Type',
              value: Options().defaultDiscoverType,
              items: Map.fromIterable(
                DiscoverType.values,
                key: (v) => Convert.clarifyEnum((v as DiscoverType).name)!,
              ),
              onChanged: (v) => Options().defaultDiscoverType = v,
            ),
            DropDownField<ImageQuality>(
              title: 'Image Quality',
              value: Options().imageQuality,
              items: const {
                'Very High': ImageQuality.VeryHigh,
                'High': ImageQuality.High,
                'Medium': ImageQuality.Medium,
              },
              onChanged: (v) => Options().imageQuality = v,
            ),
          ]),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 10)),
        SliverGrid(
          gridDelegate: const SliverGridDelegateWithMinWidthAndFixedHeight(
            minWidth: 200,
            mainAxisSpacing: 0,
            crossAxisSpacing: 20,
            height: Consts.tapTargetSize,
          ),
          delegate: SliverChildListDelegate.fixed([
            CheckBoxField(
              title: 'Left-Handed Mode',
              initial: Options().leftHanded,
              onChanged: (val) => Options().leftHanded = val,
            ),
            CheckBoxField(
              title: '12 Hour Clock',
              initial: Options().analogueClock,
              onChanged: (val) => Options().analogueClock = val,
            ),
            CheckBoxField(
              title: 'Confirm Exit',
              initial: Options().confirmExit,
              onChanged: (val) => Options().confirmExit = val,
            ),
          ]),
        ),
        const SliverFooter(),
      ],
    );
  }
}

class _SheetExpandButton extends StatelessWidget {
  const _SheetExpandButton({
    required this.title,
    required this.initialSheetHeight,
    required this.sheetContentBuilder,
  });

  final String title;
  final double initialSheetHeight;
  final Widget Function(BuildContext, ScrollController) sheetContentBuilder;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: ListTile(
        title: Text(title),
        trailing: const Icon(Icons.chevron_right_outlined),
        textColor: Theme.of(context).colorScheme.onBackground,
        iconColor: Theme.of(context).colorScheme.onBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
        visualDensity: VisualDensity.compact,
        onTap: () => showSheet(
          context,
          OpaqueSheet(
            builder: sheetContentBuilder,
            initialHeight: initialSheetHeight,
          ),
        ),
      ),
    );
  }
}
