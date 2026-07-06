import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_colors.dart';
import '../network/upload_repository.dart';

/// Reusable multi-image picker: lets the user pick photos from the gallery, uploads
/// each to real object storage, and reports the resulting public URLs back to the
/// parent form. Used by CreateProjectPage and SubmitReportPage, both of which
/// previously submitted a hardcoded mock image URL / empty media list instead of
/// whatever the farmer actually photographed.
class ImageUploadPicker extends StatefulWidget {
  final String category;
  final ValueChanged<List<String>> onChanged;
  final int maxImages;

  const ImageUploadPicker({
    super.key,
    required this.category,
    required this.onChanged,
    this.maxImages = 5,
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

  Future<void> _pickAndUpload() async {
    if (_urls.length >= widget.maxImages) return;
    final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image == null) return;

    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      final url = await _uploadRepository.uploadImage(image.path, category: widget.category);
      setState(() => _urls.add(url));
      widget.onChanged(List.unmodifiable(_urls));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _uploading = false);
    }
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
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(url, width: 84, height: 84, fit: BoxFit.cover),
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
      onTap: _uploading ? null : _pickAndUpload,
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
            : const Icon(Icons.add_a_photo_outlined, color: AppColors.textMuted, size: 24),
      ),
    );
  }
}
