import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../constants/app_colors.dart';

/// Wraps the `shimmer` package (present in pubspec.yaml since the start, but
/// never actually imported anywhere) into ready-made skeleton placeholders,
/// replacing the bare CircularProgressIndicator used for every list/card
/// loading state across the app.
class ShimmerBox extends StatelessWidget {
  final double height;
  final double? width;
  final BorderRadius borderRadius;

  const ShimmerBox({
    super.key,
    required this.height,
    this.width,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(color: Colors.white, borderRadius: borderRadius),
    );
  }
}

class ShimmerCard extends StatelessWidget {
  const ShimmerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.border,
      highlightColor: Colors.white,
      child: Container(
        margin: const EdgeInsets.only(top: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ShimmerBox(height: 110, borderRadius: BorderRadius.all(Radius.circular(12))),
            SizedBox(height: 14),
            ShimmerBox(height: 16, width: 180),
            SizedBox(height: 8),
            ShimmerBox(height: 12),
            SizedBox(height: 16),
            ShimmerBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class ShimmerList extends StatelessWidget {
  final int count;
  const ShimmerList({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: count,
      itemBuilder: (_, __) => const ShimmerCard(),
    );
  }
}
