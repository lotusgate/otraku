import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otraku/util/persistence.dart';
import 'package:otraku/util/theming.dart';
import 'package:otraku/widget/fields/stateful_tiles.dart';
import 'package:otraku/widget/layouts/bottom_bar.dart';
import 'package:otraku/feature/collection/collection_models.dart';
import 'package:otraku/feature/edit/edit_buttons.dart';
import 'package:otraku/feature/edit/edit_model.dart';
import 'package:otraku/feature/edit/edit_providers.dart';
import 'package:otraku/feature/filter/chip_selector.dart';
import 'package:otraku/feature/media/media_models.dart';
import 'package:otraku/feature/settings/settings_provider.dart';
import 'package:otraku/widget/fields/date_field.dart';
import 'package:otraku/widget/grids/sliver_grid_delegates.dart';
import 'package:otraku/widget/loaders/loaders.dart';
import 'package:otraku/widget/fields/number_field.dart';
import 'package:otraku/feature/edit/score_field.dart';
import 'package:otraku/widget/overlays/dialogs.dart';
import 'package:otraku/widget/overlays/sheets.dart';
import 'package:otraku/util/toast.dart';

/// A sheet for entry editing. Should be opened with [showSheet].
class EditView extends StatelessWidget {
  const EditView(this.tag, {this.callback});

  final EditTag tag;
  final void Function(Edit)? callback;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        ref.listen<AsyncValue<Edit>>(
          oldEditProvider(tag),
          (_, s) => s.whenOrNull(
            error: (err, _) {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (context) => ConfirmationDialog(
                  title: 'Failed to load edit sheet',
                  content: err.toString(),
                ),
              );
            },
          ),
        );

        return ref.watch(oldEditProvider(tag)).maybeWhen(
              data: (oldEdit) => SheetWithButtonRow(
                buttons: EditButtons(tag, oldEdit, callback),
                builder: (context, scrollCtrl) => _EditView(
                  scrollCtrl,
                  tag,
                  oldEdit,
                ),
              ),
              orElse: () => SheetWithButtonRow(
                builder: (context, scrollCtrl) => const Center(child: Loader()),
              ),
            );
      },
    );
  }
}

class _EditView extends StatelessWidget {
  const _EditView(this.scrollCtrl, this.tag, this.oldEdit);

  final ScrollController scrollCtrl;
  final EditTag tag;
  final Edit oldEdit;

  @override
  Widget build(BuildContext context) {
    final provider = newEditProvider(tag);
    final ofAnime = oldEdit.type == 'ANIME';

    final statusField = SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Theming.offset),
        child: Consumer(
          builder: (context, ref, _) {
            final status = ref.watch(provider.select((s) => s.status));

            return ChipSelector(
              title: 'Status',
              items:
                  EntryStatus.values.map((v) => (v.label(ofAnime), v)).toList(),
              value: status,
              onChanged: (status) => ref.read(provider.notifier).update(
                (s) {
                  var startedAt = s.startedAt;
                  var completedAt = s.completedAt;
                  var progress = s.progress;

                  if (oldEdit.status == null &&
                      status == EntryStatus.current &&
                      startedAt == null) {
                    startedAt = DateTime.now();
                    Toast.show(context, 'Start date changed');
                  } else if (oldEdit.status != status &&
                      status == EntryStatus.completed &&
                      completedAt == null) {
                    completedAt = DateTime.now();
                    var text = 'Completed date changed';

                    if (s.progressMax != null && progress < s.progressMax!) {
                      progress = s.progressMax!;
                      text = 'Completed date & progress changed';
                    }

                    Toast.show(context, text);
                  }

                  return s.copyWith(
                    status: status,
                    progress: progress,
                    startedAt: () => startedAt,
                    completedAt: () => completedAt,
                  );
                },
              ),
            );
          },
        ),
      ),
    );

    final progressField = Consumer(
      builder: (context, ref, _) {
        final progress = ref.watch(provider.select((s) => s.progress));

        return NumberField(
          label: 'Progress',
          value: progress,
          maxValue: oldEdit.progressMax ?? 100000,
          onChanged: (progress) {
            ref.read(provider.notifier).update((s) {
              var status = s.status;
              var startedAt = s.startedAt;
              var completedAt = s.completedAt;

              String? text;
              if (progress == s.progressMax && oldEdit.progress != progress) {
                if (oldEdit.status == status &&
                    status != EntryStatus.completed) {
                  status = EntryStatus.completed;
                  text = 'Status changed';
                }

                if (oldEdit.completedAt == completedAt && completedAt == null) {
                  completedAt = DateTime.now();
                  text = text == null
                      ? 'Completed date changed'
                      : 'Status & Completed date changed';
                }

                if (text != null) Toast.show(context, text);
              } else if (oldEdit.progress == 0 &&
                  oldEdit.progress != progress) {
                if (oldEdit.status == status &&
                    (status == null || status == EntryStatus.planning)) {
                  status = EntryStatus.current;
                  text = 'Status changed';
                }

                if (oldEdit.startedAt == null && startedAt == null) {
                  startedAt = DateTime.now();
                  text = text == null
                      ? 'Start date changed'
                      : 'Status & start date changed';
                }
              }
              if (text != null) Toast.show(context, text);

              return s.copyWith(
                progress: progress.toInt(),
                status: status,
                startedAt: () => startedAt,
                completedAt: () => completedAt,
              );
            });
          },
        );
      },
    );

    final volumeProgressField = oldEdit.type != 'ANIME'
        ? Consumer(
            builder: (context, ref, _) => NumberField(
              label: 'Volume Progress',
              value: ref.read(provider).progressVolumes,
              maxValue: oldEdit.progressVolumesMax ?? 100000,
              onChanged: (progressVolumes) =>
                  ref.read(provider.notifier).update(
                        (s) => s.copyWith(
                          progressVolumes: progressVolumes.toInt(),
                        ),
                      ),
            ),
          )
        : null;

    final progressFields = SliverPadding(
      padding: const EdgeInsets.only(
        left: Theming.offset,
        right: Theming.offset,
        bottom: Theming.offset,
      ),
      sliver: SliverToBoxAdapter(
        child: volumeProgressField == null
            ? progressField
            : MediaQuery.sizeOf(context).width <= Theming.compactWidth
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      progressField,
                      const SizedBox(height: 20),
                      volumeProgressField,
                    ],
                  )
                : Row(
                    children: Persistence().leftHanded
                        ? [
                            Expanded(child: progressField),
                            const SizedBox(width: Theming.offset),
                            Expanded(child: volumeProgressField),
                          ]
                        : [
                            Expanded(child: volumeProgressField),
                            const SizedBox(width: Theming.offset),
                            Expanded(child: progressField),
                          ],
                  ),
      ),
    );

    final timelineFields = _FieldGrid(
      minWidth: 195,
      children: [
        Consumer(
          builder: (context, ref, _) {
            final startedAt = ref.watch(provider.select((s) => s.startedAt));

            return DateField(
              label: 'Started',
              value: startedAt,
              onChanged: (startedAt) {
                ref.read(provider.notifier).update((s) {
                  var status = s.status;

                  if (startedAt != null &&
                      oldEdit.status == null &&
                      status == null) {
                    status = EntryStatus.current;
                    Toast.show(context, 'Status changed');
                  }

                  return s.copyWith(
                    status: status,
                    startedAt: () => startedAt,
                  );
                });
              },
            );
          },
        ),
        Consumer(
          builder: (context, ref, _) {
            final completedAt =
                ref.watch(provider.select((s) => s.completedAt));

            return DateField(
              label: 'Completed',
              value: completedAt,
              onChanged: (completedAt) {
                ref.read(provider.notifier).update((s) {
                  var status = s.status;
                  var progress = s.progress;

                  if (completedAt != null &&
                      oldEdit.status != EntryStatus.completed &&
                      oldEdit.status != EntryStatus.repeating &&
                      oldEdit.status == status) {
                    status = EntryStatus.completed;
                    String text = 'Status changed';

                    if (s.progressMax != null && s.progress < s.progressMax!) {
                      progress = s.progressMax!;
                      text = 'Status & progress changed';
                    }

                    Toast.show(context, text);
                  }

                  return s.copyWith(
                    status: status,
                    progress: progress,
                    completedAt: () => completedAt,
                  );
                });
              },
            );
          },
        ),
        Consumer(
          builder: (context, ref, _) => NumberField(
            label: 'Repeat',
            value: ref.read(provider).repeat,
            onChanged: (repeat) => ref
                .read(provider.notifier)
                .update((s) => s.copyWith(repeat: repeat.toInt())),
          ),
        ),
      ],
    );

    final advancedScoring = Consumer(
      builder: (context, ref, _) {
        final settings = ref.watch(
          settingsProvider.select((s) => s.valueOrNull),
        );

        final advancedScoringEnabled =
            settings?.advancedScoringEnabled ?? false;
        final scoreFormat = settings?.scoreFormat ?? ScoreFormat.point10;

        if (!advancedScoringEnabled ||
            scoreFormat != ScoreFormat.point100 &&
                scoreFormat != ScoreFormat.point10Decimal) {
          return const SliverToBoxAdapter(child: SizedBox());
        }

        final scores = ref.watch(provider.notifier).state.advancedScores;
        final isDecimal = scoreFormat == ScoreFormat.point10Decimal;

        final onChanged = (entry, score) {
          scores[entry.key] = score.toDouble();

          int count = 0;
          double avg = 0;
          for (final v in scores.values) {
            if (v > 0) {
              avg += v;
              count++;
            }
          }

          if (count > 0) avg /= count;

          final notifier = ref.read(provider.notifier);
          if (notifier.state.score != avg) {
            notifier.update((s) => s.copyWith(score: avg));
          }
        };

        return _FieldGrid(
          minWidth: 140,
          children: [
            for (final s in scores.entries)
              isDecimal
                  ? NumberField.decimal(
                      label: s.key,
                      value: s.value,
                      maxValue: 10.0,
                      onChanged: (score) => onChanged(s, score),
                    )
                  : NumberField(
                      label: s.key,
                      value: s.value.toInt(),
                      maxValue: 100,
                      onChanged: (score) => onChanged(s, score),
                    ),
          ],
        );
      },
    );

    return Material(
      color: Colors.transparent,
      child: Consumer(
        builder: (context, ref, _) {
          final notifier = ref.watch(provider.notifier);

          return CustomScrollView(
            controller: scrollCtrl,
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              statusField,
              const SliverToBoxAdapter(child: SizedBox(height: 15)),
              progressFields,
              SliverToBoxAdapter(child: ScoreField(tag)),
              const SliverToBoxAdapter(child: SizedBox(height: Theming.offset)),
              advancedScoring,
              const SliverToBoxAdapter(child: SizedBox(height: Theming.offset)),
              _Notes(
                value: notifier.state.notes,
                onChanged: (notes) => notifier.state.notes = notes,
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              timelineFields,
              SliverToBoxAdapter(
                child: StatefulCheckboxListTile(
                  title: const Text('Private'),
                  value: notifier.state.private,
                  onChanged: (v) => notifier.update(
                    (s) => s.copyWith(private: v),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: StatefulCheckboxListTile(
                  title: const Text('Hidden From Status Lists'),
                  value: notifier.state.hiddenFromStatusLists,
                  onChanged: (v) => notifier.update(
                    (s) => s.copyWith(hiddenFromStatusLists: v),
                  ),
                ),
              ),
              if (notifier.state.customLists.isNotEmpty)
                SliverToBoxAdapter(
                  child: ExpansionTile(
                    title: const Text('Custom Lists'),
                    initiallyExpanded: true,
                    children: [
                      for (final e in notifier.state.customLists.entries)
                        StatefulCheckboxListTile(
                          title: Text(e.key),
                          value: e.value,
                          onChanged: (v) =>
                              notifier.state.customLists[e.key] = v!,
                        ),
                    ],
                  ),
                ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.paddingOf(context).bottom +
                      BottomBar.height +
                      10,
                ),
              )
            ],
          );
        },
      ),
    );
  }
}

class _FieldGrid extends StatelessWidget {
  const _FieldGrid({required this.minWidth, required this.children});

  final List<Widget> children;
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: Theming.offset),
      sliver: SliverGrid(
        delegate: SliverChildListDelegate.fixed(children),
        gridDelegate: SliverGridDelegateWithMinWidthAndFixedHeight(
          minWidth: minWidth,
          height: 58,
        ),
      ),
    );
  }
}

class _Notes extends StatefulWidget {
  const _Notes({required this.value, required this.onChanged});

  final String value;
  final void Function(String) onChanged;

  @override
  _NotesState createState() => _NotesState();
}

class _NotesState extends State<_Notes> {
  late final _ctrl = TextEditingController(text: widget.value);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Theming.offset),
          child: TextField(
            minLines: 1,
            maxLines: 10,
            controller: _ctrl,
            style: Theme.of(context).textTheme.bodyMedium,
            decoration: const InputDecoration(
              labelText: 'Notes',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => widget.onChanged(value),
          ),
        ),
      );
}
