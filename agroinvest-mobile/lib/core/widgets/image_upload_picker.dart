import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_colors.dart';
import '../network/upload_repository.dart';

/// Reusable multi-media picker: lets the user pick photos and videos from the gallery/camera,
/// uploads each to real object storage, and reports the resulting public URLs back.
class ImageUploadPicker extends StatefulWidget {
  final String category;
  final ValueChanged<List<String>> onChanged;
  final int maxImages;
  final bool allowVideo;

  const ImageUploadPicker({
    super.key,
    required this.category,
    required this.onChanged,
    this.maxImages = 20,
    this.allowVideo = false,
  });

  @override
  State<ImageUploadPicker> createState() => _ImageUploadPickerState();
}

class _ImageUploadPickerState extends State<ImageUploadPicker> {
  final _picker = ImagePicker();
  final _uploadRepository = UploadRepository();
  final List<String> _urls = [];
  bool _uploading = false;
  String? _error;

  Future<void> _pickAndUpload(bool isVideo) async {
    if (_urls.length >= widget.maxImages) return;
    
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded, color: AppColors.primary),
              title: Text(isVideo ? 'Kameradan video olish' : 'Kameradan suratga olish', style: const TextStyle(fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
              title: Text(isVideo ? 'Galereyadan video tanlash' : 'Galereyadan rasm tanlash', style: const TextStyle(fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    
    if (source == null) return;
    
    XFile? file;
    if (isVideo) {
      file = await _picker.pickVideo(source: source);
    } else {
      file = await _picker.pickImage(source: source, imageQuality: 85);
    }
    if (file == null) return;

    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      final url = await _uploadRepository.uploadFile(file.path, category: widget.category);
      setState(() => _urls.add(url));
      widget.onChanged(List.unmodifiable(_urls));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _uploading = false);
    }
  }

  void _showTypeSelection() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image_outlined, color: AppColors.primary),
              title: const Text('Rasm yuklash', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _pickAndUpload(false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.video_collection_outlined, color: AppColors.primary),
              title: const Text('Video yuklash', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _pickAndUpload(true);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _removeAt(int index) {
    setState(() => _urls.removeAt(index));
    widget.onChanged(List.unmodifiable(_urls));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ..._urls.asMap().entries.map((entry) => _buildThumbnail(entry.key, entry.value)),
            if (_urls.length < widget.maxImages) _buildAddTile(),
          ],
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
          ),
      ],
    );
  }

  Widget _buildThumbnail(int index, String url) {
    final isVideo = url.endsWith('.mp4') || url.endsWith('.mov') || url.endsWith('.3gp') || url.endsWith('.webm');
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: isVideo 
              ? Container(
                  width: 84,
                  height: 84,
                  color: Colors.black87,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 28),
                      SizedBox(height: 4),
                      Text('Video', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              : Image.network(url, width: 84, height: 84, fit: BoxFit.cover),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: IconButton(
            icon: const Icon(Icons.cancel_rounded, color: AppColors.danger, size: 20),
            onPressed: () => _removeAt(index),
          ),
        ),
      ],
    );
  }

  Widget _buildAddTile() {
    return InkWell(
      onTap: _uploading 
          ? null 
          : (widget.allowVideo ? _showTypeSelection : () => _pickAndUpload(false)),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 1.5, style: BorderStyle.solid),
          color: AppColors.background,
        ),
        child: _uploading
            ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)))
            : Icon(widget.allowVideo ? Icons.add_to_photos_outlined : Icons.add_a_photo_outlined, color: AppColors.textMuted, size: 24),
      ),
    );
  }
}
