import 'package:flutter/widgets.dart';

/// Anchor rect for the iPad share popover, which share_plus requires on iPad.
/// Returns null when the widget isn't laid out yet.
Rect? shareOriginOf(BuildContext context) {
  final box = context.findRenderObject();
  if (box is! RenderBox || !box.hasSize) return null;
  return box.localToGlobal(Offset.zero) & box.size;
}
