import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';
import 'package:otraku/extension/snack_bar_extension.dart';
import 'package:otraku/feature/collection/collection_provider.dart';
import 'package:otraku/feature/edit/edit_model.dart';
import 'package:otraku/feature/edit/edit_providers.dart';
import 'package:otraku/util/persistence.dart';
import 'package:otraku/widget/layout/navigation_tool.dart';
import 'package:otraku/widget/loaders.dart';
import 'package:otraku/widget/dialogs.dart';

class EditButtons extends ConsumerStatefulWidget {
  const EditButtons(this.tag, this.oldEdit, this.callback);

  final EditTag tag;
  final Edit oldEdit;
  final void Function(Edit)? callback;

  @override
  ConsumerState<EditButtons> createState() => _EditButtonsState();
}

class _EditButtonsState extends ConsumerState<EditButtons> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, __) {
        final saveButton = _loading
            ? const Expanded(child: Center(child: Loader()))
            : _saveButton();
        final removeButton =
            widget.oldEdit.entryId == null ? const Spacer() : _removeButton();

        return BottomBar(
          Persistence().leftHanded
              ? [saveButton, removeButton]
              : [removeButton, saveButton],
        );
      },
    );
  }

  Widget _saveButton() => BottomBarButton(
        text: 'Save',
        icon: Ionicons.save_outline,
        onTap: () async {
          final oldEdit = widget.oldEdit;
          final newEdit = ref.read(newEditProvider(widget.tag));
          setState(() => _loading = true);

          final tag =
              (userId: Persistence().id!, ofAnime: oldEdit.type == 'ANIME');
          final err = await ref
              .read(collectionProvider(tag).notifier)
              .saveEntry(oldEdit, newEdit);

          if (err == null) {
            widget.callback?.call(newEdit);
            if (mounted) Navigator.pop(context);
            return;
          }

          if (mounted) {
            Navigator.pop(context);
            SnackBarExtension.show(context, 'Could not update entry');
          }
        },
      );

  Widget _removeButton() => BottomBarButton(
        text: 'Remove',
        icon: Ionicons.trash_bin_outline,
        warning: true,
        onTap: () => showDialog(
          context: context,
          builder: (_) => ConfirmationDialog(
            title: 'Remove entry?',
            mainAction: 'Yes',
            secondaryAction: 'No',
            onConfirm: () async {
              setState(() => _loading = true);

              final oldEdit = widget.oldEdit;
              final tag = (
                userId: Persistence().id!,
                ofAnime: oldEdit.type == 'ANIME',
              );

              final err = await ref
                  .read(collectionProvider(tag).notifier)
                  .removeEntry(oldEdit);

              if (err == null) {
                widget.callback?.call(oldEdit.emptyCopy());
                if (mounted) Navigator.pop(context);
                return;
              }

              if (mounted) {
                Navigator.pop(context);
                SnackBarExtension.show(context, 'Could not remove entry');
              }
            },
          ),
        ),
      );
}
