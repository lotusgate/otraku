import 'package:flutter/material.dart';
import 'package:otraku/discover/discover_models.dart';
import 'package:otraku/studio/studio_models.dart';
import 'package:otraku/widgets/link_tile.dart';
import 'package:otraku/widgets/grids/sliver_grid_delegates.dart';

class StudioGrid extends StatelessWidget {
  const StudioGrid(this.items);

  final List<StudioItem> items;

  @override
  Widget build(BuildContext context) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithMinWidthAndFixedHeight(
        minWidth: 230,
        height: 50,
      ),
      delegate: SliverChildBuilderDelegate(
        childCount: items.length,
        (_, i) => LinkTile(
          id: items[i].id,
          info: items[i].name,
          discoverType: DiscoverType.studio,
          child: Hero(
            tag: items[i].id,
            child: Text(
              items[i].name,
              maxLines: 2,
              overflow: TextOverflow.fade,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),
      ),
    );
  }
}
