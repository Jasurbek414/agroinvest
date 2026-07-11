import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../constants/app_colors.dart';
import '../network/upload_repository.dart';
import '../theme/app_theme.dart';

class DocumentUploadPicker extends StatefulWidget {
  final String category;
  final List<String> urls;
  final ValueChanged<List<String>> onChanged;
  final int maxDocs;

  const DocumentUploadPicker({
    super.key,
    required this.category,
    required this.urls,
    required this.onChanged,
    this.maxDocs = 3,
  });

  @override
  State<DocumentUploadPicker> createState() => _DocumentUploadPickerState();
}

class _DocumentUploadPickerState extends State<DocumentUploadPicker> {
  final _uploadRepository = UploadRepository();
  bool _uploading = false;
  String? _error;

  Future<void> _pickAndUpload() async {
    if (widget.urls.length >= widget.maxDocs) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx'],
    );

    if (result == null || result.files.single.path == null) return;
    final path = result.files.single.path!;

    setState(() {
      _uploading = true;
      _error = null;
    });

    try {
      final url = await _uploadRepository.uploadFile(path, category: widget.category);
      final updatedList = List<String>.from(widget.urls)..add(url);
      widget.onChanged(updatedList);
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('ApiException: ', ''));
    } finally {
      setState(() => _uploading = false);
    }
  }

  void _removeAt(int index) {
    final updatedList = List<String>.from(widget.urls)..removeAt(index);
    widget.onChanged(updatedList);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.urls.isNotEmpty) ...[
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.urls.length,
            itemBuilder: (context, idx) {
              final url = widget.urls[idx];
              final filename = url.split('/').last;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf_rounded, color: Colors.red, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        Uri.decodeComponent(filename),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 18),
                      onPressed: () => _removeAt(idx),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
        if (widget.urls.length < widget.maxDocs)
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _uploading ? null : _pickAndUpload,
            icon: _uploading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  )
                : const Icon(Icons.upload_file_rounded, size: 18),
            label: Text(
              _uploading ? 'Hujjat yuklanmoqda...' : 'Hujjat biriktirish (PDF, Word, Excel)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: Text(
              _error!,
              style: const TextStyle(color: AppColors.danger, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }
}
