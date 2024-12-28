import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otraku/feature/collection/collection_filter_model.dart';
import 'package:otraku/feature/collection/collection_models.dart';
import 'package:otraku/widget/dialogs.dart';
import 'package:otraku/widget/input/chip_selector.dart';
import 'package:otraku/feature/tag/tag_picker.dart';
import 'package:otraku/widget/input/year_range_picker.dart';
import 'package:otraku/feature/media/media_models.dart';
import 'package:otraku/feature/tag/tag_provider.dart';
import 'package:otraku/feature/viewer/persistence_provider.dart';
import 'package:otraku/util/theming.dart';
import 'package:otraku/widget/layout/navigation_tool.dart';
import 'package:otraku/widget/loaders.dart';
import 'package:otraku/widget/sheets.dart';

class CollectionFilterView extends ConsumerStatefulWidget {
  const CollectionFilterView({
    required this.tag,
    required this.filter,
    required this.onChanged,
  });

  final CollectionTag tag;
  final CollectionMediaFilter filter;
  final void Function(CollectionMediaFilter) onChanged;

  @override
  ConsumerState<CollectionFilterView> createState() =>
      _FilterCollectionViewState();
}

class _FilterCollectionViewState extends ConsumerState<CollectionFilterView> {
  late final _filter = widget.filter.copy();

  @override
  Widget build(BuildContext context) {
    final options = ref.watch(persistenceProvider.select((s) => s.options));
    final ofViewer = ref.watch(viewerIdProvider) == widget.tag.userId;

    final applyButton = BottomBarButton(
      text: 'Apply',
      icon: Icons.done_rounded,
      onTap: () {
        widget.onChanged(_filter);
        Navigator.pop(context);
      },
    );

    final revertToDefaultButton = BottomBarButton(
      text: 'Reset',
      icon: Icons.restore_rounded,
      foregroundColor: Theme.of(context).colorScheme.secondary,
      onTap: () {
        final persistence = ref.read(persistenceProvider);
        if (widget.tag.ofAnime) {
          widget.onChanged(persistence.animeCollectionMediaFilter);
        } else {
          widget.onChanged(persistence.mangaCollectionMediaFilter);
        }

        Navigator.pop(context);
      },
    );

    final saveButton = BottomBarButton(
      text: 'Save',
      icon: Icons.save_outlined,
      foregroundColor: Theme.of(context).colorScheme.secondary,
      onTap: () => ConfirmationDialog.show(
        context,
        title: 'Make default?',
        content: 'The current filters and sorting will become the default.',
        primaryAction: 'Yes',
        secondaryAction: 'No',
        onConfirm: () {
          final notifier = ref.read(persistenceProvider.notifier);
          if (widget.tag.ofAnime) {
            notifier.setAnimeCollectionMediaFilter(_filter);
          } else {
            notifier.setMangaCollectionMediaFilter(_filter);
          }

          widget.onChanged(_filter);
          Navigator.pop(context);
        },
      ),
    );

    return SheetWithButtonRow(
      buttons: BottomBar(
        options.leftHanded
            ? [applyButton, revertToDefaultButton, saveButton]
            : [saveButton, revertToDefaultButton, applyButton],
      ),
      builder: (context, scrollCtrl) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: Theming.offset),
        child: ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.only(top: 20),
          children: [
            EntrySortChipSelector(
              title: 'Sorting',
              value: _filter.sort,
              onChanged: (v) => _filter.sort = v,
            ),
            if (ofViewer &&
                _filter.sort == EntrySort.airing &&
                options.airingSortForAnimePreview)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Text(
                  'Note: Airing sort is set to replace your default one for the anime preview. You can turn it off in the settings.',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            ChipMultiSelector(
              title: 'Statuses',
              items: ReleaseStatus.values.map((v) => (v.label, v)).toList(),
              values: _filter.statuses,
            ),
            ChipMultiSelector(
              title: 'Formats',
              items: (widget.tag.ofAnime
                      ? MediaFormat.animeFormats
                      : MediaFormat.mangaFormats)
                  .map((v) => (v.label, v))
                  .toList(),
              values: _filter.formats,
            ),
            const SizedBox(height: 5),
            const Divider(),
            switch (ref.watch(tagsProvider)) {
              AsyncData() => TagPicker(
                  includedGenres: _filter.genreIn,
                  excludedGenres: _filter.genreNotIn,
                  includedTags: _filter.tagIn,
                  excludedTags: _filter.tagNotIn,
                ),
              AsyncError(:final error) => Center(
                  child: Padding(
                    padding: Theming.paddingAll,
                    child: Text('Failed to load tags: $error'),
                  ),
                ),
              _ => const Center(
                  child: Padding(padding: Theming.paddingAll, child: Loader()),
                ),
            },
            const Divider(),
            const SizedBox(height: Theming.offset),
            YearRangePicker(
              title: 'Release Year Range',
              from: _filter.startYearFrom,
              to: _filter.startYearTo,
              onChanged: (from, to) {
                _filter.startYearFrom = from;
                _filter.startYearTo = to;
              },
            ),
            const SizedBox(height: Theming.offset),
            const Divider(),
            ChipSelector(
              title: 'Country',
              items: OriginCountry.values.map((v) => (v.label, v)).toList(),
              value: _filter.country,
              onChanged: (v) => _filter.country = v,
            ),
            if (ofViewer)
              ChipSelector(
                title: 'Visibility',
                items: const [('Private', true), ('Public', false)],
                value: _filter.isPrivate,
                onChanged: (v) => _filter.isPrivate = v,
              ),
            ChipSelector(
              title: 'Notes',
              items: const [('With Notes', true), ('Without Notes', false)],
              value: _filter.hasNotes,
              onChanged: (v) => _filter.hasNotes = v,
            ),
            SizedBox(
              height: MediaQuery.paddingOf(context).bottom +
                  BottomBar.height +
                  Theming.offset,
            ),
          ],
        ),
      ),
    );
  }
}
