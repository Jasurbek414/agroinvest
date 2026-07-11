import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/upload_repository.dart';
import '../providers/kyc_provider.dart';
import '../widgets/kyc_status_banner.dart';
import '../widgets/kyc_section_header.dart';
import '../widgets/kyc_card_container.dart';
import '../widgets/kyc_photo_upload_box.dart';

class KycPage extends StatefulWidget {
  const KycPage({super.key});

  @override
  State<KycPage> createState() => _KycPageState();
}

class _KycPageState extends State<KycPage> {
  final _formKey = GlobalKey<FormState>();
  final _uploadRepository = UploadRepository();
  final _picker = ImagePicker();

  final _passportController = TextEditingController();
  final _pinflController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _currentAddressController = TextEditingController();
  final _registrationAddressController = TextEditingController();
  final _additionalPhoneController = TextEditingController();
  final _occupationController = TextEditingController();
  final _workExperienceController = TextEditingController();
  final _educationController = TextEditingController();
  DateTime? _birthDate;

  String? _selfieUrl;
  String? _passportPhotoUrl;
  bool _uploadingSelfie = false;
  bool _uploadingPassport = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<KycProvider>(context, listen: false).fetchMe();
    });
  }

  @override
  void dispose() {
    _passportController.dispose();
    _pinflController.dispose();
    _fatherNameController.dispose();
    _currentAddressController.dispose();
    _registrationAddressController.dispose();
    _additionalPhoneController.dispose();
    _occupationController.dispose();
    _workExperienceController.dispose();
    _educationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isSelfie) async {
    final image = await _picker.pickImage(
      source: isSelfie ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1000,
    );
    if (image == null) return;

    setState(() {
      if (isSelfie) {
        _uploadingSelfie = true;
      } else {
        _uploadingPassport = true;
      }
    });

    try {
      final url = await _uploadRepository.uploadFile(image.path, category: 'kyc');
      setState(() {
        if (isSelfie) {
          _selfieUrl = url;
        } else {
          _passportPhotoUrl = url;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rasm yuklashda xatolik: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          if (isSelfie) {
            _uploadingSelfie = false;
          } else {
            _uploadingPassport = false;
          }
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selfieUrl == null || _passportPhotoUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("O'zingizning va pasportingizning rasmi yuklanishi shart"), backgroundColor: AppColors.danger),
      );
      return;
    }

    if (_birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tug'ilgan sana tanlanishi shart"), backgroundColor: AppColors.danger),
      );
      return;
    }

    final provider = Provider.of<KycProvider>(context, listen: false);
    final success = await provider.submit(
      passportNumber: _passportController.text.trim(),
      pinfl: _pinflController.text.trim(),
      birthDate: _birthDate?.toIso8601String().split('T').first,
      selfieUrl: _selfieUrl!,
      passportPhotoUrl: _passportPhotoUrl!,
      currentAddress: _currentAddressController.text.trim(),
      registrationAddress: _registrationAddressController.text.trim(),
      additionalPhone: _additionalPhoneController.text.trim().isEmpty ? null : _additionalPhoneController.text.trim(),
      fatherName: _fatherNameController.text.trim(),
      occupation: _occupationController.text.trim(),
      workExperience: _workExperienceController.text.trim().isEmpty ? null : _workExperienceController.text.trim(),
      education: _educationController.text.trim(),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Hujjatlaringiz tekshiruvga yuborildi' : (provider.error ?? 'Xatolik yuz berdi')),
        backgroundColor: success ? AppColors.primary : AppColors.danger,
      ),
    );
  }

  InputDecoration _customInputDecoration({
    required String labelText,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w500),
      prefixIcon: Icon(prefixIcon, color: AppColors.primary, size: 20),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.border, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<KycProvider>(context);
    final kycStatus = provider.me?['kycStatus'];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Shaxsni tasdiqlash (KYC)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textDark,
        centerTitle: true,
      ),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                children: [
                  KycStatusBanner(status: kycStatus, me: provider.me),
                  const SizedBox(height: 24),

                  if (kycStatus == 'VERIFIED') ...[
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.border, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.verified_rounded, size: 56, color: AppColors.primary),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Shaxsingiz tasdiqlangan!',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textDark),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Platformadagi shartnomalar, sarmoyalar va barcha moliyaviy operatsiyalar to\'liq huquqiy kuchga ega.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.4, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Section 1: Photos
                    const KycSectionHeader(title: '1. Rasmlar (Hujjatlar)', icon: Icons.photo_camera_back_outlined),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: KycPhotoUploadBox(
                            title: "Selfie rasm",
                            subtitle: "Kameradan oling",
                            url: _selfieUrl,
                            uploading: _uploadingSelfie,
                            onTap: () => _pickImage(true),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: KycPhotoUploadBox(
                            title: "Pasport rasmi",
                            subtitle: "Galereyadan tanlang",
                            url: _passportPhotoUrl,
                            uploading: _uploadingPassport,
                            onTap: () => _pickImage(false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Section 2: Personal details
                    const KycSectionHeader(title: '2. Pasport ma\'lumotlari', icon: Icons.badge_outlined),
                    const SizedBox(height: 16),

                    KycCardContainer(children: [
                      TextFormField(
                        controller: _passportController,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark),
                        decoration: _customInputDecoration(labelText: 'Pasport seriyasi va raqami (masalan: AA1234567)', prefixIcon: Icons.badge_outlined),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Pasport ma\'lumotlarini kiriting';
                          final match = RegExp(r'^[A-Z]{2}\d{7}$').hasMatch(val.trim().toUpperCase());
                          if (!match) return 'Format noto\'g\'ri (masalan: AA1234567)';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _pinflController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark),
                        decoration: _customInputDecoration(labelText: 'JSHSHIR (14 xonali PINFL)', prefixIcon: Icons.fingerprint_rounded),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'JSHSHIR kodini kiriting';
                          if (val.trim().length != 14 || int.tryParse(val.trim()) == null) {
                            return 'JSHSHIR 14 xonali raqam bo\'limi bo\'lishi kerak';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _fatherNameController,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark),
                        decoration: _customInputDecoration(labelText: 'Otangizning ismi va familiyasi', prefixIcon: Icons.family_restroom_rounded),
                        validator: (val) => (val == null || val.trim().isEmpty) ? 'Otangizning ismi va familiyasini kiriting' : null,
                      ),
                      const SizedBox(height: 16),

                      InkWell(
                        onTap: () async {
                          final now = DateTime.now();
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime(now.year - 25),
                            firstDate: DateTime(1940),
                            lastDate: now,
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: AppColors.primary,
                                    onPrimary: Colors.white,
                                    onSurface: AppColors.textDark,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) setState(() => _birthDate = picked);
                        },
                        child: InputDecorator(
                          decoration: _customInputDecoration(labelText: "Tug'ilgan sana", prefixIcon: Icons.calendar_today_rounded),
                          child: Text(
                            _birthDate == null ? "Sana tanlanmagan" : _birthDate!.toIso8601String().split('T').first,
                            style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark),
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 28),

                    // Section 3: Addresses
                    const KycSectionHeader(title: '3. Manzillar', icon: Icons.location_on_outlined),
                    const SizedBox(height: 16),

                    KycCardContainer(children: [
                      TextFormField(
                        controller: _registrationAddressController,
                        maxLines: 2,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark),
                        decoration: _customInputDecoration(labelText: 'Pasport bo\'yicha doimiy ro\'yxatdan o\'tgan manzil', prefixIcon: Icons.home_work_outlined),
                        validator: (val) => (val == null || val.trim().isEmpty) ? 'Doimiy ro\'yxatdan o\'tgan manzilni kiriting' : null,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _currentAddressController,
                        maxLines: 2,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark),
                        decoration: _customInputDecoration(labelText: 'Hozirgi aniq yashash manzili', prefixIcon: Icons.location_city_outlined),
                        validator: (val) => (val == null || val.trim().isEmpty) ? 'Hozirgi aniq yashash manzilingizni kiriting' : null,
                      ),
                    ]),
                    const SizedBox(height: 28),

                    // Section 4: Experience & Education
                    const KycSectionHeader(title: '4. Faoliyat turi va Ma\'lumoti', icon: Icons.work_outline_rounded),
                    const SizedBox(height: 16),

                    KycCardContainer(children: [
                      TextFormField(
                        controller: _occupationController,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark),
                        decoration: _customInputDecoration(labelText: 'Hozirgi kasbingiz / faoliyat turi', prefixIcon: Icons.work_outline_rounded),
                        validator: (val) => (val == null || val.trim().isEmpty) ? 'Hozirgi mashg\'ulotingizni kiriting' : null,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _workExperienceController,
                        maxLines: 3,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark),
                        decoration: _customInputDecoration(labelText: 'Oldin qayerda va qancha muddat ishlagansiz', prefixIcon: Icons.history_rounded),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _educationController,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark),
                        decoration: _customInputDecoration(labelText: 'Ma\'lumotingiz (masalan: Oliy, O\'rta-maxsus)', prefixIcon: Icons.school_outlined),
                        validator: (val) => (val == null || val.trim().isEmpty) ? 'Ma\'lumotingiz darajasini kiriting' : null,
                      ),
                    ]),
                    const SizedBox(height: 28),

                    // Section 5: Contact
                    const KycSectionHeader(title: '5. Qo\'shimcha kontakt', icon: Icons.phone_iphone_rounded),
                    const SizedBox(height: 16),

                    KycCardContainer(children: [
                      TextFormField(
                        controller: _additionalPhoneController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark),
                        decoration: _customInputDecoration(labelText: 'Qo\'shimcha telefon raqami (ixtiyoriy)', prefixIcon: Icons.phone_android_rounded),
                      ),
                    ]),
                    const SizedBox(height: 36),

                    // Premium submit button with gradient effect container decoration
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: provider.submitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(
                          provider.submitting ? 'Yuborilmoqda...' : 'Tasdiqlashga yuborish',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 0.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (kycStatus == 'PENDING')
                      const Center(
                        child: Text(
                          'Arizangiz ko\'rib chiqilmoqda. Qayta topshirish oldingisini bekor qiladi.',
                          style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
    );
  }
}
