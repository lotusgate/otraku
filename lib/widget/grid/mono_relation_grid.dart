import 'package:flutter/material.dart';
import 'package:otraku/util/theming.dart';
import 'package:otraku/util/tile_modelable.dart';
import 'package:otraku/widget/cached_image.dart';
import 'package:otraku/widget/grid/sliver_grid_delegates.dart';

class MonoRelationGrid extends StatelessWidget {
  const MonoRelationGrid({required this.items, required this.onTap});

  final List<TileModelable> items;
  final void Function(TileModelable item) onTap;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SliverToBoxAdapter();

    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithMinWidthAndFixedHeight(
        minWidth: 240,
        height: 115,
      ),
      delegate: SliverChildBuilderDelegate(
        childCount: items.length,
        (context, i) => _MonoRelationTile(item: items[i], onTap: onTap),
      ),
    );
  }
}

class _MonoRelationTile extends StatelessWidget {
  const _MonoRelationTile({required this.item, required this.onTap});

  final TileModelable item;
  final void Function(TileModelable item) onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(item),
      child: Card(
        child: Row(
          children: [
            ClipRRect(
              borderRadius: Theming.borderRadiusSmall,
              child: CachedImage(item.tileImageUrl, width: 80),
            ),
            Expanded(
              child: Padding(
                padding: Theming.paddingAll,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      child: Text(
                        item.tileTitle,
                        overflow: TextOverflow.fade,
                      ),
                    ),
                    if (item.tileSubtitle != null)
                      Text(
                        item.tileSubtitle!,
                        maxLines: 4,
                        overflow: TextOverflow.fade,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
