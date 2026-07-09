class BannerItem {
  final String id;
  final String title;
  final String imageUrl;
  final String? linkUrl;

  const BannerItem({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.linkUrl,
  });

  factory BannerItem.fromJson(Map<String, dynamic> json) {
    return BannerItem(
      id: json['id'].toString(),
      title: json['title']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      linkUrl: json['linkUrl']?.toString(),
    );
  }
}
