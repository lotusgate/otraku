import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:otraku/common/utils/routing.dart';
import 'package:otraku/modules/discover/discover_models.dart';
import 'package:otraku/modules/edit/edit_view.dart';
import 'package:otraku/common/widgets/overlays/sheets.dart';

class LinkTile extends StatelessWidget {
  const LinkTile({
    required this.id,
    required this.info,
    required this.discoverType,
    required this.child,
    super.key,
  });

  final DiscoverType discoverType;
  final int id;
  final String? info;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push(switch (discoverType) {
        DiscoverType.Anime || DiscoverType.Manga => Routes.media(id, info),
        DiscoverType.Character => Routes.character(id, info),
        DiscoverType.Staff => Routes.staff(id, info),
        DiscoverType.Studio => Routes.studio(id, info),
        DiscoverType.User => Routes.user(id, info),
        DiscoverType.Review => Routes.review(id, info),
      }),
      onLongPress: () {
        if (discoverType == DiscoverType.Anime ||
            discoverType == DiscoverType.Manga) {
          showSheet(context, EditView((id: id, setComplete: false)));
        }
      },
      child: child,
    );
  }
}
