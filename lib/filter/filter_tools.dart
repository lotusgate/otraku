import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:otraku/utils/convert.dart';
import 'package:otraku/widgets/fields/drop_down_field.dart';
import 'package:otraku/widgets/fields/search_field.dart';
import 'package:otraku/widgets/layouts/page_layout.dart';

class SortDropDown<T extends Enum> extends StatelessWidget {
  SortDropDown(this.values, this.index, this.onChange);

  final List<T> values;
  final int Function() index;
  final void Function(T) onChange;

  @override
  Widget build(BuildContext context) {
    final items = <String, int>{};
    for (int i = 0; i < values.length; i += 2) {
      final key = Convert.clarifyEnum(values[i].name)!;
      items[key] = i ~/ 2;
    }

    return DropDownField<int>(
      title: 'Sort',
      value: index() ~/ 2,
      items: items,
      onChanged: (val) {
        int i = val * 2;
        if (index() % 2 != 0) i++;
        onChange(values[i]);
      },
    );
  }
}

class OrderDropDown<T extends Enum> extends StatelessWidget {
  OrderDropDown(this.values, this.index, this.onChange);

  final List<T> values;
  final int Function() index;
  final void Function(T) onChange;

  @override
  Widget build(BuildContext context) {
    return DropDownField<bool>(
      title: 'Order',
      value: index() % 2 == 0,
      items: const {'Ascending': true, 'Descending': false},
      onChanged: (val) {
        int i = index();
        if (!val && i % 2 == 0) {
          i++;
        } else if (val && i % 2 != 0) {
          i--;
        }
        onChange(values[i]);
      },
    );
  }
}

class CountryDropDown extends StatelessWidget {
  CountryDropDown(this.value, this.onChanged);

  final String? value;
  final void Function(String?) onChanged;

  @override
  Widget build(BuildContext context) {
    final countries = <String, String?>{'All': null};
    for (final e in Convert.countryCodes.entries) countries[e.value] = e.key;

    return DropDownField<String?>(
      title: 'Country',
      value: value,
      items: countries,
      onChanged: onChanged,
    );
  }
}

class ListPresenceDropDown extends StatelessWidget {
  ListPresenceDropDown({required this.value, required this.onChanged});

  final bool? value;
  final void Function(bool?) onChanged;

  @override
  Widget build(BuildContext context) {
    return DropDownField<bool?>(
      title: 'List Filter',
      value: value,
      items: const {'Everything': null, 'On List': true, 'Not On List': false},
      onChanged: onChanged,
    );
  }
}

class MediaSearchField extends StatefulWidget {
  MediaSearchField({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String? value;

  /// If `null`, search mode cannot be turned on; [value] & [hint] are ignored.
  final void Function(String?)? onChanged;

  @override
  _MediaSearchFieldState createState() => _MediaSearchFieldState();
}

class _MediaSearchFieldState extends State<MediaSearchField> {
  String? _value;

  @override
  void initState() {
    super.initState();
    _value = widget.value;
  }

  @override
  void didUpdateWidget(covariant MediaSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    _value = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_value == null || widget.onChanged == null) ...[
            Expanded(
              child: Text(
                widget.title,
                style: Theme.of(context).textTheme.headline1,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            if (widget.onChanged != null)
              TopBarIcon(
                tooltip: 'Search',
                icon: Ionicons.search_outline,
                onTap: () => widget.onChanged?.call(''),
              ),
          ] else
            Expanded(
              child: SearchField(
                value: _value!,
                hint: widget.title,
                onChange: (val) => widget.onChanged?.call(val),
                onHide: () => widget.onChanged?.call(null),
              ),
            ),
        ],
      ),
    );
  }
}
