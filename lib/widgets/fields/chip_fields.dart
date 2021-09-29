import 'package:flutter/material.dart';
import 'package:otraku/widgets/overlays/dialogs.dart';

// A static chip.
class ChipField extends StatelessWidget {
  final String name;
  final void Function() onRemoved;

  ChipField({required this.name, required this.onRemoved, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) => Chip(
        label: Text(name, style: Theme.of(context).textTheme.button),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        deleteIconColor: Theme.of(context).colorScheme.onSecondary,
        onDeleted: onRemoved,
      );
}

// A chip that switches state when tapped.
class ChipToggleField extends StatefulWidget {
  final String name;
  final void Function() onRemoved;
  final void Function(bool) onChanged;
  final bool initial;

  ChipToggleField({
    required this.name,
    required this.onRemoved,
    required this.onChanged,
    required this.initial,
    Key? key,
  }) : super(key: key);

  @override
  _ChipToggleFieldState createState() => _ChipToggleFieldState();
}

class _ChipToggleFieldState extends State<ChipToggleField> {
  late bool _on;

  @override
  void initState() {
    super.initState();
    _on = widget.initial;
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () {
          setState(() => _on = !_on);
          widget.onChanged(_on);
        },
        child: Chip(
          label: Text(widget.name, style: Theme.of(context).textTheme.button),
          backgroundColor: _on
              ? Theme.of(context).colorScheme.secondary
              : Theme.of(context).colorScheme.error,
          deleteIconColor: _on
              ? Theme.of(context).colorScheme.onSecondary
              : Theme.of(context).colorScheme.onError,
          onDeleted: widget.onRemoved,
        ),
      );
}

// A chip that can be renamed when tapped. It's a statelessWidget, because the
// state is managed by it's parent (likely ChipNamingGrid).
class ChipNamingField extends StatelessWidget {
  final String name;
  final void Function() onRemoved;
  final void Function(String) onChanged;

  ChipNamingField({
    required this.name,
    required this.onRemoved,
    required this.onChanged,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => showPopUp(
          context,
          InputDialog(
            initial: name,
            onChanged: (n) => n.isNotEmpty ? onChanged(n) : null,
          ),
        ),
        child: Chip(
          label: Text(name, style: Theme.of(context).textTheme.button),
          backgroundColor: Theme.of(context).colorScheme.secondary,
          deleteIconColor: Theme.of(context).colorScheme.onSecondary,
          onDeleted: onRemoved,
        ),
      );
}