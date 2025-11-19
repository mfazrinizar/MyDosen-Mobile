import 'package:flutter/material.dart';

typedef DragOverCallback = void Function(bool inside);

class DragDetector extends StatelessWidget {
  final Widget child;
  final GlobalKey targetKey;
  final DragOverCallback onOver;

  const DragDetector({
    super.key,
    required this.child,
    required this.targetKey,
    required this.onOver,
  });

  void _checkDrag(BuildContext context, Offset position, bool up) {
    if (up) {
      onOver(false);
      return;
    }
    try {
      final ctx = targetKey.currentContext;
      if (ctx == null) return;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null) return;
      final boxOffset = box.localToGlobal(Offset.zero);
      final size = box.size;
      final inside = position.dx > boxOffset.dx &&
          position.dx < boxOffset.dx + size.width &&
          position.dy > boxOffset.dy &&
          position.dy < boxOffset.dy + size.height;
      onOver(inside);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    // Solution for Map widget, in this case OSMFlutter, to be interactive
    // When becoming a child widget of a ScrollView:
    // Wrap with Listener to detect pointer position relative to the map
    // and disable parent scrolling while dragging over the map.
    return Listener(
      onPointerDown: (ev) => _checkDrag(context, ev.position, false),
      onPointerMove: (ev) => _checkDrag(context, ev.position, false),
      onPointerUp: (ev) => _checkDrag(context, ev.position, true),
      behavior: HitTestBehavior.translucent,
      child: child,
    );
  }
}
