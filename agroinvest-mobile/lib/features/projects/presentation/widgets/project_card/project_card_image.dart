import 'package:flutter/material.dart';
import '../../../../../core/constants/asset_type_meta.dart';
import '../../../../../core/constants/risk_level_meta.dart';
import '../../../../../core/widgets/project_image_gallery.dart';
import 'project_card_badge.dart';

/// Card image block: swipeable photo carousel with the asset-type and
/// risk-level badges floated on top. Overlaying the badges on the photo (the
/// old card stacked them in their own row below it) buys back a full row of
/// card height.
class ProjectCardImage extends StatelessWidget {
  final Map<String, dynamic> project;
  final double height;

  const ProjectCardImage({
    super.key,
    required this.project,
    this.height = 150,
  });

  @override
  Widget build(BuildContext context) {
    final assetType = project['assetType']?.toString() ?? 'OTHER';
    final assetMeta = getAssetTypeMeta(assetType);
    final riskMeta = getRiskLevelMeta(project['riskLevel']?.toString());
    final mediaUrls =
        (project['mediaUrls'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];

    return Stack(
      children: [
        ProjectImageCarousel(
          imageUrls: mediaUrls,
          assetType: assetType,
          height: height,
          borderRadius: BorderRadius.zero,
        ),
        Positioned(
          top: 10,
          left: 10,
          child: ProjectCardBadge(
            label: assetMeta.label,
            icon: assetMeta.icon,
            color: assetMeta.color,
          ),
        ),
        Positioned(
          top: 10,
          right: 10,
          child: ProjectCardBadge(
            label: riskMeta.label,
            color: riskMeta.color,
          ),
        ),
      ],
    );
  }
}
