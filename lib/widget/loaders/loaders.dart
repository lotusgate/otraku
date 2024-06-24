import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:otraku/util/theming.dart';
import 'package:otraku/widget/layouts/top_bar.dart';
import 'package:otraku/widget/loaders/shimmer.dart';

class Loader extends StatelessWidget {
  const Loader();

  @override
  Widget build(BuildContext context) => Shimmer(ShimmerItem(
        Container(
          width: 60,
          height: 15,
          decoration: BoxDecoration(
            borderRadius: Theming.borderRadiusSmall,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        ),
      ));
}

class SliverRefreshControl extends StatelessWidget {
  const SliverRefreshControl({
    required this.onRefresh,
    this.withTopOffset = true,
  });

  final void Function() onRefresh;
  final bool withTopOffset;

  @override
  Widget build(BuildContext context) {
    final topOffset =
        withTopOffset ? MediaQuery.paddingOf(context).top + TopBar.height : 0.0;

    return SliverPadding(
      padding: EdgeInsets.only(top: topOffset + Theming.offset),
      sliver: CupertinoSliverRefreshControl(
        refreshIndicatorExtent: 15,
        refreshTriggerPullDistance: 160,
        onRefresh: () {
          onRefresh();
          return Future.value();
        },
        builder: (
          _,
          refreshState,
          pulledExtent,
          refreshTriggerPullDistance,
          refreshIndicatorExtent,
        ) {
          double visibility = 0;
          if (pulledExtent > refreshIndicatorExtent) {
            pulledExtent -= refreshIndicatorExtent;
            refreshTriggerPullDistance -= refreshIndicatorExtent;
            visibility = pulledExtent / refreshTriggerPullDistance;
            if (visibility > 1) visibility = 1;
          }

          return switch (refreshState) {
            RefreshIndicatorMode.inactive => const SizedBox(),
            _ => Opacity(
                opacity: visibility,
                child: const Center(child: Loader()),
              ),
          };
        },
      ),
    );
  }
}

class SliverFooter extends StatelessWidget {
  const SliverFooter({this.loading = false});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Center(
        child: Padding(
          padding: EdgeInsets.only(
            top: Theming.offset,
            bottom: MediaQuery.paddingOf(context).bottom + Theming.offset,
          ),
          child: loading ? const Loader() : null,
        ),
      ),
    );
  }
}
