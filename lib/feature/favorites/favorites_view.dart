import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';
import 'package:otraku/model/tile_item.dart';
import 'package:otraku/feature/favorites/favorites_model.dart';
import 'package:otraku/feature/studio/studio_model.dart';
import 'package:otraku/feature/favorites/favorites_provider.dart';
import 'package:otraku/feature/studio/studio_grid.dart';
import 'package:otraku/util/paged_controller.dart';
import 'package:otraku/util/theming.dart';
import 'package:otraku/widget/grids/tile_item_grid.dart';
import 'package:otraku/widget/layouts/bottom_bar.dart';
import 'package:otraku/widget/layouts/scaffolds.dart';
import 'package:otraku/widget/layouts/top_bar.dart';
import 'package:otraku/widget/paged_view.dart';

class FavoritesView extends ConsumerStatefulWidget {
  const FavoritesView(this.id);

  final int id;

  @override
  ConsumerState<FavoritesView> createState() => _FavoritesViewState();
}

class _FavoritesViewState extends ConsumerState<FavoritesView>
    with SingleTickerProviderStateMixin {
  late final _tabCtrl = TabController(
    length: FavoritesTab.values.length,
    vsync: this,
  );
  late final _scrollCtrl = PagedController(
    loadMore: () => ref
        .read(favoritesProvider(widget.id).notifier)
        .fetch(FavoritesTab.values[_tabCtrl.index]),
  );

  @override
  void initState() {
    super.initState();
    _tabCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tab = FavoritesTab.values[_tabCtrl.index];

    final count = ref.watch(
      favoritesProvider(widget.id).select(
        (s) => s.valueOrNull?.getCount(tab) ?? 0,
      ),
    );

    final onRefresh = (invalidate) => invalidate(favoritesProvider(widget.id));

    return PageScaffold(
      bottomBar: BottomNavBar(
        current: _tabCtrl.index,
        onChanged: (i) => _tabCtrl.index = i,
        onSame: (_) => _scrollCtrl.scrollToTop(),
        items: const {
          'Anime': Ionicons.film_outline,
          'Manga': Ionicons.book_outline,
          'Characters': Ionicons.man_outline,
          'Staff': Ionicons.briefcase_outline,
          'Studios': Ionicons.business_outline,
        },
      ),
      child: TabScaffold(
        topBar: TopBar(
          title: tab.title,
          trailing: [
            if (count > 0)
              Padding(
                padding: const EdgeInsets.only(right: Theming.offset),
                child: Text(
                  count.toString(),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
          ],
        ),
        child: TabBarView(
          controller: _tabCtrl,
          children: [
            PagedView<TileItem>(
              provider: favoritesProvider(widget.id).select(
                (s) => s.unwrapPrevious().whenData((data) => data.anime),
              ),
              onData: (data) => TileItemGrid(data.items),
              scrollCtrl: _scrollCtrl,
              onRefresh: onRefresh,
            ),
            PagedView<TileItem>(
              provider: favoritesProvider(widget.id).select(
                (s) => s.unwrapPrevious().whenData((data) => data.manga),
              ),
              onData: (data) => TileItemGrid(data.items),
              scrollCtrl: _scrollCtrl,
              onRefresh: onRefresh,
            ),
            PagedView<TileItem>(
              provider: favoritesProvider(widget.id).select(
                (s) => s.unwrapPrevious().whenData((data) => data.characters),
              ),
              onData: (data) => TileItemGrid(data.items),
              scrollCtrl: _scrollCtrl,
              onRefresh: onRefresh,
            ),
            PagedView<TileItem>(
              provider: favoritesProvider(widget.id).select(
                (s) => s.unwrapPrevious().whenData((data) => data.staff),
              ),
              onData: (data) => TileItemGrid(data.items),
              scrollCtrl: _scrollCtrl,
              onRefresh: onRefresh,
            ),
            PagedView<StudioItem>(
              provider: favoritesProvider(widget.id).select(
                (s) => s.unwrapPrevious().whenData((data) => data.studios),
              ),
              onData: (data) => StudioGrid(data.items),
              scrollCtrl: _scrollCtrl,
              onRefresh: onRefresh,
            ),
          ],
        ),
      ),
    );
  }
}
