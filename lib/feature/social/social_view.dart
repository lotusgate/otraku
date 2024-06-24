import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';
import 'package:otraku/feature/social/social_model.dart';
import 'package:otraku/feature/user/user_models.dart';
import 'package:otraku/feature/social/social_provider.dart';
import 'package:otraku/feature/user/user_grid.dart';
import 'package:otraku/util/paged_controller.dart';
import 'package:otraku/util/theming.dart';
import 'package:otraku/widget/layouts/bottom_bar.dart';
import 'package:otraku/widget/layouts/scaffolds.dart';
import 'package:otraku/widget/layouts/top_bar.dart';
import 'package:otraku/widget/paged_view.dart';

class SocialView extends ConsumerStatefulWidget {
  const SocialView(this.id);

  final int id;

  @override
  ConsumerState<SocialView> createState() => _SocialViewState();
}

class _SocialViewState extends ConsumerState<SocialView>
    with SingleTickerProviderStateMixin {
  late final _tabCtrl = TabController(length: 2, vsync: this);
  late final _scrollCtrl = PagedController(
    loadMore: () => ref
        .read(socialProvider(widget.id).notifier)
        .fetch(SocialTab.values[_tabCtrl.index]),
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
    final tab = SocialTab.values[_tabCtrl.index];

    final count = ref.watch(
      socialProvider(widget.id).select(
        (s) => s.valueOrNull?.getCount(tab) ?? 0,
      ),
    );

    final onRefresh = (invalidate) => invalidate(socialProvider(widget.id));

    return PageScaffold(
      bottomBar: BottomNavBar(
        current: _tabCtrl.index,
        onChanged: (i) => _tabCtrl.index = i,
        onSame: (_) => _scrollCtrl.scrollToTop(),
        items: const {
          'Following': Ionicons.people_circle,
          'Followers': Ionicons.person_circle,
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
            PagedView<UserItem>(
              scrollCtrl: _scrollCtrl,
              onRefresh: onRefresh,
              provider: socialProvider(widget.id).select(
                (s) => s.unwrapPrevious().whenData((data) => data.following),
              ),
              onData: (data) => UserGrid(data.items),
            ),
            PagedView<UserItem>(
              scrollCtrl: _scrollCtrl,
              onRefresh: onRefresh,
              provider: socialProvider(widget.id).select(
                (s) => s.unwrapPrevious().whenData((data) => data.followers),
              ),
              onData: (data) => UserGrid(data.items),
            ),
          ],
        ),
      ),
    );
  }
}
