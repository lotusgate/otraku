import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:ionicons/ionicons.dart';
import 'package:otraku/feature/character/character_model.dart';
import 'package:otraku/util/theming.dart';
import 'package:otraku/widget/table_list.dart';
import 'package:otraku/widget/html_content.dart';
import 'package:otraku/widget/layouts/constrained_view.dart';
import 'package:otraku/widget/loaders/loaders.dart';

class CharacterOverviewSubview extends StatelessWidget {
  const CharacterOverviewSubview({
    required this.character,
    required this.scrollCtrl,
    required this.invalidate,
  });

  final Character character;
  final ScrollController scrollCtrl;
  final void Function() invalidate;

  @override
  Widget build(BuildContext context) {
    return ConstrainedView(
      child: CustomScrollView(
        physics: Theming.bouncyPhysics,
        controller: scrollCtrl,
        slivers: [
          SliverRefreshControl(onRefresh: invalidate),
          _NameTable(character),
          const SliverToBoxAdapter(child: SizedBox(height: Theming.offset)),
          SliverTableList([
            if (character.dateOfBirth != null)
              ('Birth', character.dateOfBirth!),
            if (character.age != null) ('Age', character.age!),
            if (character.bloodType != null)
              ('Blood Type', character.bloodType!),
          ]),
          if (character.description.isNotEmpty) ...[
            const SliverToBoxAdapter(child: SizedBox(height: 15)),
            HtmlContent(
              character.description,
              renderMode: RenderMode.sliverList,
            ),
          ],
          const SliverFooter(),
        ],
      ),
    );
  }
}

class _NameTable extends StatefulWidget {
  const _NameTable(this.character);

  final Character character;

  @override
  State<_NameTable> createState() => __NameTableState();
}

class __NameTableState extends State<_NameTable> {
  var _showSpoilers = false;

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        SliverTableList([
          ('Full', widget.character.fullName),
          if (widget.character.nativeName != null)
            ('Native', widget.character.nativeName!),
          ...widget.character.altNames.map((s) => ('Alternative', s)),
          if (_showSpoilers)
            ...widget.character.altNamesSpoilers.map(
              (s) => ('Alternative Spoiler', s),
            ),
        ]),
        if (widget.character.altNamesSpoilers.isNotEmpty && !_showSpoilers)
          SliverToBoxAdapter(
            child: TextButton.icon(
              label: const Text('Show Spoilers'),
              icon: const Icon(Ionicons.eye_outline),
              onPressed: () => setState(() => _showSpoilers = true),
            ),
          ),
      ],
    );
  }
}
