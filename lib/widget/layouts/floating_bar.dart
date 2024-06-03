import 'package:flutter/material.dart';
import 'package:otraku/util/persistence.dart';
import 'package:otraku/util/theming.dart';
import 'package:otraku/widget/drag_detector.dart';

/// Hides the [child] on scroll-down and reveals it on scroll-up.
class FloatingBar extends StatefulWidget {
  const FloatingBar({required this.scrollCtrl, required this.children});

  final List<Widget> children;
  final ScrollController scrollCtrl;

  @override
  FloatingBarState createState() => FloatingBarState();
}

class FloatingBarState extends State<FloatingBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationCtrl;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  bool _visible = true;
  double _lastOffset = 0;

  void _visibility() {
    final pos = widget.scrollCtrl.positions.last;
    final dif = pos.pixels - _lastOffset;

    // If the position has moved enough from the last
    // spot or is out of bounds, update visibility.
    if (dif > 15 || pos.pixels > pos.maxScrollExtent) {
      _lastOffset = pos.pixels;
      _animationCtrl.forward().then((_) => setState(() => _visible = false));
    } else if (dif < -15 || pos.pixels < pos.minScrollExtent) {
      _lastOffset = pos.pixels;
      setState(() => _visible = true);
      _animationCtrl.reverse();
    }
  }

  @override
  void initState() {
    super.initState();
    _animationCtrl = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _slideAnimation = Tween(
      begin: Offset.zero,
      end: const Offset(0, 0.2),
    ).animate(_animationCtrl);
    _fadeAnimation = Tween(begin: 1.0, end: 0.3).animate(_animationCtrl);

    widget.scrollCtrl.addListener(_visibility);
  }

  @override
  void dispose() {
    widget.scrollCtrl.removeListener(_visibility);
    _animationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox();

    final children = Persistence().leftHanded
        ? widget.children
        : widget.children.reversed.toList();

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.paddingOf(context).bottom + 16,
      ),
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Row(
            mainAxisAlignment: Persistence().leftHanded
                ? MainAxisAlignment.start
                : MainAxisAlignment.end,
            children: [
              for (int i = 0; i < children.length; i++) ...[
                const SizedBox(width: 10),
                children[i],
              ]
            ],
          ),
        ),
      ),
    );
  }
}

const floatingBarItemHeight = 56.0;

/// A [FloatingActionButton] implementation.
class ActionButton extends StatelessWidget {
  const ActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.onSwipe,
  });

  final IconData icon;
  final String tooltip;
  final void Function() onTap;

  /// If not null, it will signal when the user swipes on the action button.
  /// Passing `true` means 'go right', while `false` means 'go left'. If the
  /// return value is not `null` the new [IconData] will replace the old one
  /// through an animation.
  final IconData? Function(bool)? onSwipe;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: floatingBarItemHeight,
      height: floatingBarItemHeight,
      child: Tooltip(
        message: tooltip,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: Theming.borderRadiusBig,
            boxShadow: [
              BoxShadow(
                blurRadius: 5,
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withAlpha(50),
              ),
            ],
          ),
          child: Material(
            color: Theme.of(context).colorScheme.primary,
            shape: const RoundedRectangleBorder(
              borderRadius: Theming.borderRadiusBig,
            ),
            child: InkWell(
              onTap: onTap,
              borderRadius: Theming.borderRadiusBig,
              splashColor:
                  Theme.of(context).colorScheme.onPrimary.withAlpha(50),
              child: onSwipe == null
                  ? Icon(icon, color: Theme.of(context).colorScheme.onPrimary)
                  : _DraggableIcon(icon: icon, onSwipe: onSwipe!),
            ),
          ),
        ),
      ),
    );
  }
}

// Detects swiping and animates the icon switching.
class _DraggableIcon extends StatefulWidget {
  const _DraggableIcon({
    required this.icon,
    required this.onSwipe,
  });

  final IconData icon;
  final IconData? Function(bool) onSwipe;

  @override
  State<_DraggableIcon> createState() => _DraggableIconState();
}

class _DraggableIconState extends State<_DraggableIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late IconData _icon;

  // The icon fades out on exit and fades in on entrance.
  late Animation<double> _opacity;

  // For when the icon exits/enters from the left.
  late Animation<Offset> _left;

  // For when the icon exits/enters from the right.
  late Animation<Offset> _right;

  bool _onRight = false;

  @override
  void initState() {
    super.initState();
    _icon = widget.icon;
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _opacity = Tween(begin: 1.0, end: 0.0).animate(_ctrl);

    _left = Tween(
      begin: Offset.zero,
      end: const Offset(-0.25, 0),
    ).animate(_ctrl);

    _right = Tween(
      begin: Offset.zero,
      end: const Offset(0.25, 0),
    ).animate(_ctrl);
  }

  @override
  void didUpdateWidget(covariant _DraggableIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    _icon = widget.icon;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DragDetector(
      triggerOffset: 10,
      onSwipe: (goRight) {
        // The previous transition must have finished.
        if (_ctrl.isAnimating) return;

        if (_onRight == goRight) setState(() => _onRight = !goRight);

        _ctrl.forward().then((_) {
          setState(() {
            _icon = widget.onSwipe(goRight) ?? _icon;
            _onRight = goRight;
          });
          _ctrl.reverse();
        });
      },
      child: SlideTransition(
        position: _onRight ? _right : _left,
        child: FadeTransition(
          opacity: _opacity,
          child: Icon(
            _icon,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }
}
