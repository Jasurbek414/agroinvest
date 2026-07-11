import 'package:flutter/material.dart';

/// Generic fixed-height pinned header for CustomScrollView pages - keeps a
/// widget (filter bar, segmented control) glued below the app bar while the
/// rest of the content scrolls away underneath it.
class PinnedSliverHeader extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;

  const PinnedSliverHeader({required this.height, required this.child});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(covariant PinnedSliverHeader oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}
