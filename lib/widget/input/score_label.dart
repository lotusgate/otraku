import 'package:flutter/material.dart';
import 'package:otraku/feature/media/media_models.dart';
import 'package:otraku/util/theming.dart';

class ScoreLabel extends StatelessWidget {
  const ScoreLabel(this.score, this.scoreFormat);

  final double score;
  final ScoreFormat scoreFormat;

  @override
  Widget build(BuildContext context) {
    if (score == 0) return const SizedBox();

    Widget content;
    switch (scoreFormat) {
      case ScoreFormat.point3:
        if (score == 3) {
          content = const Icon(
            Icons.sentiment_very_satisfied,
            size: Theming.iconSmall,
          );
        } else if (score == 2) {
          content = const Icon(
            Icons.sentiment_neutral,
            size: Theming.iconSmall,
          );
        } else {
          content = const Icon(
            Icons.sentiment_very_dissatisfied,
            size: Theming.iconSmall,
          );
        }
      case ScoreFormat.point5:
        content = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              score.toStringAsFixed(0),
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(width: 3),
            const Icon(Icons.star_rounded, size: Theming.iconSmall),
          ],
        );
      case ScoreFormat.point10Decimal:
        content = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_half_rounded, size: Theming.iconSmall),
            const SizedBox(width: 3),
            Text(
              score.toStringAsFixed(1),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        );
      default:
        content = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_half_rounded, size: Theming.iconSmall),
            const SizedBox(width: 3),
            Text(
              score.toStringAsFixed(0),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        );
    }

    return Tooltip(message: 'Score', child: content);
  }
}
