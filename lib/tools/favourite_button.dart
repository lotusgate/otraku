import 'package:flutter/material.dart';
import 'package:otraku/models/page_item_data.dart';
import 'package:otraku/providers/page_item.dart';
import 'package:provider/provider.dart';

class FavoriteButton extends StatefulWidget {
  final PageItemData data;
  final double shrinkPercentage;

  FavoriteButton(this.data, this.shrinkPercentage);

  @override
  _FavoriteButtonState createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.shrinkPercentage < 0.5)
          Text(
            widget.data.favourites.toString(),
            style: Theme.of(context).textTheme.bodyText1,
          ),
        IconButton(
          icon: Icon(
            widget.data.isFavourite ? Icons.favorite : Icons.favorite_border,
            color: Theme.of(context).dividerColor,
          ),
          onPressed: () => Provider.of<PageItem>(context, listen: false)
              .toggleFavourite(widget.data.id, widget.data.browsable)
              .then((ok) {
            if (ok)
              setState(
                  () => widget.data.isFavourite = !widget.data.isFavourite);
          }),
        ),
      ],
    );
  }
}