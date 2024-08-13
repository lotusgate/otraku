import 'package:flutter/material.dart';
import 'package:otraku/util/theming.dart';
import 'package:otraku/extension/snack_bar_extension.dart';

class TableList extends StatelessWidget {
  const TableList(this.items);

  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox();

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: Theming.borderRadiusSmall,
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Theming.offset),
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: items.length,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          separatorBuilder: (context, _) => const Divider(),
          itemBuilder: (context, i) => Row(
            children: [
              const SizedBox(width: Theming.offset),
              Text(items[i].$1),
              const SizedBox(width: Theming.offset),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => SnackBarExtension.copy(context, items[i].$2),
                  child: Text(items[i].$2, textAlign: TextAlign.end),
                ),
              ),
              const SizedBox(width: Theming.offset),
            ],
          ),
        ),
      ),
    );
  }
}

class SliverTableList extends StatelessWidget {
  const SliverTableList(this.items);

  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SliverToBoxAdapter();

    return DecoratedSliver(
      decoration: BoxDecoration(
        borderRadius: Theming.borderRadiusSmall,
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      sliver: SliverPadding(
        padding: const EdgeInsets.symmetric(vertical: Theming.offset),
        sliver: SliverList.separated(
          itemCount: items.length,
          separatorBuilder: (context, _) => const Divider(),
          itemBuilder: (context, i) => Row(
            children: [
              const SizedBox(width: Theming.offset),
              Text(items[i].$1),
              const SizedBox(width: Theming.offset),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => SnackBarExtension.copy(context, items[i].$2),
                  child: Text(items[i].$2, textAlign: TextAlign.end),
                ),
              ),
              const SizedBox(width: Theming.offset),
            ],
          ),
        ),
      ),
    );
  }
}
