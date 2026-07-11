import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../constants/app_colors.dart';
import '../constants/asset_type_meta.dart';

/// Swipeable image carousel for a project's mediaUrls, with an AssetType-tinted
/// fallback when there are no images. Previously farmers uploaded photos via
/// ImageUploadPicker but neither the projects list nor the detail page ever
/// rendered them - this was the single biggest visual gap for a platform whose
/// whole pitch is "see the livestock/crop you're investing in".
class ProjectImageCarousel extends StatefulWidget {
  final List<String> imageUrls;
  final String assetType;
  final double height;
  final BorderRadius? borderRadius;

  const ProjectImageCarousel({
    super.key,
    required this.imageUrls,
    required this.assetType,
    this.height = 180,
    this.borderRadius,
  });

  @override
  State<ProjectImageCarousel> createState() => _ProjectImageCarouselState();
}

class _ProjectImageCarouselState extends State<ProjectImageCarousel> {
  int _index = 0;
  final _controller = PageController();

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(16);

    if (widget.imageUrls.isEmpty) {
      return ClipRRect(borderRadius: radius, child: _buildFallback());
    }

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        height: widget.height,
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: widget.imageUrls.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) => GestureDetector(
                onTap: () => _openGallery(context, i),
                child: CachedNetworkImage(
                  imageUrl: widget.imageUrls[i],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: AppColors.border,
                    highlightColor: Colors.white,
                    child: Container(color: Colors.white),
                  ),
                  errorWidget: (context, url, error) => _buildFallback(),
                ),
              ),
            ),
            if (widget.imageUrls.length > 1)
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.imageUrls.length, (i) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _index ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == _index ? Colors.white : Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallback() {
    final meta = getAssetTypeMeta(widget.assetType);
    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            meta.color.withOpacity(0.15),
            meta.color.withOpacity(0.04),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: meta.color.withOpacity(0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(meta.icon, size: 44, color: meta.color),
          ),
          const SizedBox(height: 12),
          Text(
            'Loyihaga oid rasmlar yuklanmagan',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: meta.color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  void _openGallery(BuildContext context, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProjectImageGalleryPage(imageUrls: widget.imageUrls, initialIndex: initialIndex),
        fullscreenDialog: true,
      ),
    );
  }
}

/// Full-screen swipeable + pinch-to-zoom viewer, opened by tapping a carousel
/// image. Uses the built-in InteractiveViewer for zoom rather than adding the
/// separate `photo_view` package.
class ProjectImageGalleryPage extends StatelessWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const ProjectImageGalleryPage({super.key, required this.imageUrls, this.initialIndex = 0});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: PageView.builder(
        controller: PageController(initialPage: initialIndex),
        itemCount: imageUrls.length,
        itemBuilder: (context, i) => InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: Center(
            child: CachedNetworkImage(imageUrl: imageUrls[i], fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
