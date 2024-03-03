import 'package:flutter/material.dart';
import 'package:otraku/common/utils/extensions.dart';
import 'package:otraku/common/widgets/fields/stateful_tiles.dart';
import 'package:otraku/common/widgets/layouts/top_bar.dart';
import 'package:otraku/modules/settings/settings_model.dart';

class SettingsNotificationsTab extends StatelessWidget {
  const SettingsNotificationsTab(this.scrollCtrl, this.settings);

  final ScrollController scrollCtrl;
  final Settings settings;

  @override
  Widget build(BuildContext context) {
    final listPadding = MediaQuery.paddingOf(context);

    return ListView.builder(
      controller: scrollCtrl,
      padding: EdgeInsets.only(
        top: listPadding.top + TopBar.height + 10,
        bottom: listPadding.bottom + 10,
      ),
      itemCount: settings.notificationOptions.length,
      itemBuilder: (context, i) {
        final e = settings.notificationOptions.entries.elementAt(i);

        return StatefulCheckboxListTile(
          title: Text(e.key.name.noScreamingSnakeCase),
          value: e.value,
          onChanged: (v) => settings.notificationOptions[e.key] = v!,
        );
      },
    );
  }
}
