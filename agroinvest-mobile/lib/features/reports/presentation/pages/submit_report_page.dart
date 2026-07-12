import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/image_upload_picker.dart';
import '../../data/report_repository.dart';

class SubmitReportPage extends StatefulWidget {
  final String projectId;

  const SubmitReportPage({super.key, required this.projectId});

  @override
  State<SubmitReportPage> createState() => _SubmitReportPageState();
}

class _SubmitReportPageState extends State<SubmitReportPage> {
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _reportRepository = ReportRepository();

  // Must match backend ReportType enum values (ROUTINE/EMERGENCY/VERIFICATION/FINAL/COMPLETION) -
  // VERIFICATION and COMPLETION are set by verifiers/admins, not submitted by the farmer here.
  String _selectedReportType = 'ROUTINE';
  bool _fetchingGps = false;
  Position? _currentPosition;
  String? _placemarkAddress;
  bool _submitting = false;
  List<String> _mediaUrls = [];

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    setState(() {
      _fetchingGps = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'GPS xizmati yoqilmagan';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'GPS ruxsati berilmadi';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'GPS ruxsati butunlay bloklangan';
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = pos;
        _placemarkAddress = null;
      });

      // Best-effort: reverse-geocode the raw coordinates into a human-readable
      // address so a reviewer sees "Qashqadaryo viloyati, ..." instead of only
      // a lat/lng pair. Never blocks report submission if it fails (no network,
      // no data for that point, platform without a geocoding backend, etc).
      try {
        final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
        if (placemarks.isNotEmpty && mounted) {
          final p = placemarks.first;
          final parts = [p.administrativeArea, p.locality, p.subLocality]
              .where((s) => s != null && s.isNotEmpty)
              .toList();
          if (parts.isNotEmpty) {
            setState(() => _placemarkAddress = parts.join(', '));
          }
        }
      } catch (_) {
        // Silently keep showing raw coordinates only.
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('GPS xatolik: $e'), backgroundColor: AppColors.danger),
      );
    } finally {
      setState(() {
        _fetchingGps = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Hisobot yuklash'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textDark,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Yangi progress hisoboti',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              const SizedBox(height: 16),

              // Report Type Dropdown
              DropdownButtonFormField<String>(
                value: _selectedReportType,
                decoration: InputDecoration(
                  labelText: 'Hisobot turi',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                items: const [
                  DropdownMenuItem(value: 'ROUTINE', child: Text('Muntazam hisobot')),
                  DropdownMenuItem(value: 'EMERGENCY', child: Text('Favqulodda (Tezkor) xabar')),
                  DropdownMenuItem(value: 'FINAL', child: Text('Yakuniy hisobot')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedReportType = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // GPS section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_rounded, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Geolokatsiya (GPS)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 4),
                          _fetchingGps
                              ? const Text('GPS aniqlanmoqda...', style: TextStyle(fontSize: 11, color: AppColors.textMuted))
                              : _currentPosition == null
                                  ? const Text('GPS topilmadi', style: TextStyle(fontSize: 11, color: AppColors.danger))
                                  : Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (_placemarkAddress != null)
                                          Text(
                                            _placemarkAddress!,
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDark),
                                          ),
                                        Text(
                                          'Lat: ${_currentPosition!.latitude.toStringAsFixed(5)}, Lng: ${_currentPosition!.longitude.toStringAsFixed(5)} (Aniqlik: ${_currentPosition!.accuracy.toStringAsFixed(1)}m)',
                                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                        ),
                                      ],
                                    ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _determinePosition,
                    )
                  ],
                ),
              ),
              const SizedBox(height: 16),

              const Text('Dalil rasmlari va videolari', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
              const SizedBox(height: 8),
              ImageUploadPicker(
                category: 'report',
                maxImages: 30,
                allowVideo: true,
                onChanged: (urls) => setState(() => _mediaUrls = urls),
              ),
              const SizedBox(height: 16),

              // Notes Input
              TextFormField(
                controller: _notesController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Izohlar va Tafsilotlar',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Izoh yozish shart' : null,
              ),
              const SizedBox(height: 24),

              // Submit button
              ElevatedButton(
                onPressed: _submitting ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _submitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Hisobotni yuborish', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitReport() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _submitting = true;
      });

      try {
        await _reportRepository.submitReport(
          projectId: widget.projectId,
          reportType: _selectedReportType,
          mediaUrls: _mediaUrls,
          geoLat: _currentPosition?.latitude,
          geoLng: _currentPosition?.longitude,
          geoAccuracy: _currentPosition?.accuracy,
          notes: _notesController.text,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Hisobotingiz muvaffaqiyatli jo\'natildi!'), backgroundColor: AppColors.primary),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
          );
        }
      } finally {
        setState(() {
          _submitting = false;
        });
      }
    }
  }
}
