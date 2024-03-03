import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:otraku/common/utils/consts.dart';
import 'package:url_launcher/url_launcher.dart';

class Toast {
  Toast._();

  static OverlayEntry? _entry;
  static bool _busy = false;

  /// Present a toast message.
  static void show(BuildContext context, String text) {
    _busy = true;
    _entry?.remove();

    final bottomOffset = 70 +
        MediaQuery.viewPaddingOf(context).bottom +
        MediaQuery.viewInsetsOf(context).bottom;

    _entry = OverlayEntry(
      builder: (context) => Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          margin: EdgeInsets.only(
            bottom: bottomOffset,
          ),
          padding: Consts.padding,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: Consts.borderRadiusMin,
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.background,
                blurRadius: 10,
              ),
            ],
          ),
          child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
        ),
      ),
    );

    Overlay.of(context).insert(_entry!);

    Future.delayed(const Duration(seconds: 2)).then((_) {
      if (!_busy) {
        _entry?.remove();
        _entry = null;
      }
    });

    _busy = false;
  }

  /// Copy [text] to clipboard and notify with a toast.
  static void copy(BuildContext context, String text) =>
      Clipboard.setData(ClipboardData(text: text))
          .then((_) => show(context, 'Copied'));

  /// Launch [link] in the browser or show a toast if unsuccessful.
  static Future<bool> launch(BuildContext context, String link) async =>
      launchUrl(
        Uri.parse(link),
        mode: LaunchMode.externalApplication,
      ).onError((_, __) {
        show(context, 'Could not open link');
        return false;
      });
}
