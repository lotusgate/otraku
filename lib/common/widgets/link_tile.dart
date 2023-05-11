import 'package:flutter/material.dart';
import 'package:otraku/modules/discover/discover_models.dart';
import 'package:otraku/common/utils/route_arg.dart';
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

  static Future<Object?> openView({
    required BuildContext context,
    required DiscoverType discoverType,
    required int id,
    required String? imageUrl,
  }) {
    final route = switch (discoverType) {
      DiscoverType.anime || DiscoverType.manga => RouteArg.media,
      DiscoverType.character => RouteArg.character,
      DiscoverType.staff => RouteArg.staff,
      DiscoverType.studio => RouteArg.studio,
      DiscoverType.user => RouteArg.user,
      DiscoverType.review => RouteArg.review,
    };

    return Navigator.pushNamed(
      context,
      route,
      arguments: RouteArg(id: id, info: imageUrl),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => openView(
        context: context,
        discoverType: discoverType,
        id: id,
        imageUrl: info,
      ),
      onLongPress: () {
        if (discoverType == DiscoverType.anime ||
            discoverType == DiscoverType.manga) {
          showSheet(context, EditView((id: id, setComplete: false)));
        }
      },
      child: child,
    );
  }
}
