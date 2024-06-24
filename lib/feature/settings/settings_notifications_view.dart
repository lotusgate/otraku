import 'package:flutter/material.dart';
import 'package:otraku/util/theming.dart';
import 'package:otraku/widget/fields/stateful_tiles.dart';
import 'package:otraku/widget/layouts/top_bar.dart';
import 'package:otraku/feature/settings/settings_model.dart';

class SettingsNotificationsSubview extends StatelessWidget {
  const SettingsNotificationsSubview(this.scrollCtrl, this.settings);

  final ScrollController scrollCtrl;
  final Settings settings;

  @override
  Widget build(BuildContext context) {
    final listPadding = MediaQuery.paddingOf(context);

    return ListView.builder(
      controller: scrollCtrl,
      padding: EdgeInsets.only(
        top: listPadding.top + TopBar.height + Theming.offset,
        bottom: listPadding.bottom + Theming.offset,
      ),
      itemCount: settings.notificationOptions.length,
      itemBuilder: (context, i) {
        final e = settings.notificationOptions.entries.elementAt(i);

        return StatefulCheckboxListTile(
          title: Text(e.key.label),
          value: e.value,
          onChanged: (v) => settings.notificationOptions[e.key] = v!,
        );
      },
    );
  }
}
