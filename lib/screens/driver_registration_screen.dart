import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../data/driver_repository.dart';
import '../data/storage_repository.dart';
import '../models/driver.dart';
import '../theme/app_theme.dart';
import '../widgets/error_state.dart';
import 'driver_jobs_screen.dart';
import 'help_center_screen.dart';

const _vehicleTypes = ['ລົດກະບະ', 'ລົດບັນທຸກກາງ', 'ລົດບັນທຸກໃຫຍ່'];

class DriverRegistrationScreen extends StatefulWidget {
  const DriverRegistrationScreen({super.key});

  @override
  State<DriverRegistrationScreen> createState() =>
      _DriverRegistrationScreenState();
}

class _DriverRegistrationScreenState extends State<DriverRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _plateController = TextEditingController();

  String? _vehicleType;
  String? _photoUrl;
  bool _uploadingPhoto = false;
  bool _submitting = false;

  bool _loading = true;
  bool _error = false;
  bool _editing = false;
  Driver? _existing;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final driver = await DriverRepository.fetchMine();
      if (!mounted) return;
      setState(() {
        _existing = driver;
        _loading = false;
      });
    } catch (e, st) {
      Sentry.captureException(e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  Future<void> _pickPhoto() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 82,
    );
    if (file == null) return;
    setState(() => _uploadingPhoto = true);
    try {
      final bytes = await file.readAsBytes();
      final ext = file.name.contains('.')
          ? file.name.split('.').last.toLowerCase()
          : 'jpg';
      final url = await StorageRepository.uploadImage(
        bytes: bytes,
        folder: 'vehicles',
        extension: ext,
      );
      if (!mounted) return;
      setState(() {
        _photoUrl = url;
        _uploadingPhoto = false;
      });
    } catch (e, st) {
      Sentry.captureException(e, stackTrace: st);
      if (!mounted) return;
      setState(() => _uploadingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ອັບໂຫລດຮູບບໍ່ສຳເລັດ — ກະລຸນາລອງໃໝ່')),
      );
    }
  }

  void _startResubmit() {
    final existing = _existing!;
    _nameController.text = existing.driverName;
    _phoneController.text = existing.phone;
    _plateController.text = existing.vehiclePlate;
    setState(() {
      _vehicleType = existing.vehicleType;
      _photoUrl = existing.vehiclePhotoUrl;
      _editing = true;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_vehicleType == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ກະລຸນາເລືອກປະເພດລົດ')));
      return;
    }
    setState(() => _submitting = true);
    try {
      if (_editing && _existing != null) {
        await DriverRepository.resubmit(
          driverId: _existing!.id,
          driverName: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          vehicleType: _vehicleType!,
          vehiclePlate: _plateController.text.trim(),
          vehiclePhotoUrl: _photoUrl,
        );
      } else {
        await DriverRepository.register(
          driverName: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          vehicleType: _vehicleType!,
          vehiclePlate: _plateController.text.trim(),
          vehiclePhotoUrl: _photoUrl,
        );
      }
      if (!mounted) return;
      setState(() => _editing = false);
      await _load();
    } catch (e, st) {
      Sentry.captureException(e, stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ສະໝັກບໍ່ສຳເລັດ — ກະລຸນາລອງໃໝ່')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 20, 12),
              child: Row(
                children: [
                  Material(
                    color: AppColors.surface,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.of(context).pop(),
                      child: Tooltip(
                        message: 'ກັບຄືນ',
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 18,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'ສະໝັກເປັນຄົນຂັບ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.primaryGreen),
      );
    }
    if (_error) return ErrorState(onRetry: _load);
    if (_existing != null && !_editing) {
      return _StatusCard(
        driver: _existing!,
        onContactSupport: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const HelpCenterScreen())),
        onGoToJobs: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const DriverJobsScreen())),
        onResubmit: _startResubmit,
      );
    }
    return _buildForm();
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_editing)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => setState(() => _editing = false),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.arrow_back_rounded,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'ຍົກເລີກການແກ້ໄຂ',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Text(
              _editing
                  ? 'ແກ້ໄຂຂໍ້ມູນ ແລະ ສົ່ງຄຳຮ້ອງສະໝັກອີກຄັ້ງ — ທີມງານຈະກວດສອບໃໝ່.'
                  : 'ລົງທະບຽນລົດ ແລະ ຂໍ້ມູນຄົນຂັບ ເພື່ອຮັບວຽກຂົນສົ່ງເຄື່ອງຜ່ານແອັບ '
                        'ຂໍ້ມູນຈະຖືກກວດສອບໂດຍທີມງານກ່ອນເລີ່ມຮັບວຽກໄດ້.',
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            _FieldLabel('ຮູບລົດ (ບໍ່ບັງຄັບ)'),
            const SizedBox(height: 8),
            _PhotoPicker(
              photoUrl: _photoUrl,
              uploading: _uploadingPhoto,
              onTap: _pickPhoto,
            ),
            const SizedBox(height: 18),
            _FieldLabel('ຊື່ຄົນຂັບ'),
            const SizedBox(height: 8),
            _FormInput(
              controller: _nameController,
              hint: 'ຕົວຢ່າງ: ບຸນມີ ພົມມະຈັນ',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'ກະລຸນາໃສ່ຊື່' : null,
            ),
            const SizedBox(height: 16),
            _FieldLabel('ເບີໂທຕິດຕໍ່'),
            const SizedBox(height: 8),
            _FormInput(
              controller: _phoneController,
              hint: 'ຕົວຢ່າງ: 020 5555 5555',
              keyboardType: TextInputType.phone,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'ກະລຸນາໃສ່ເບີໂທ' : null,
            ),
            const SizedBox(height: 16),
            _FieldLabel('ປະເພດລົດ'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final type in _vehicleTypes)
                  _Chip(
                    label: type,
                    selected: _vehicleType == type,
                    onTap: () => setState(() => _vehicleType = type),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _FieldLabel('ປ້າຍທະບຽນລົດ'),
            const SizedBox(height: 8),
            _FormInput(
              controller: _plateController,
              hint: 'ຕົວຢ່າງ: ວທ 1234',
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'ກະລຸນາໃສ່ປ້າຍທະບຽນ'
                  : null,
            ),
            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity,
              child: Material(
                color: AppColors.primaryGreen,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: _submitting ? null : _submit,
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    child: Center(
                      child: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _editing ? 'ສົ່ງຄຳຮ້ອງອີກຄັ້ງ' : 'ສົ່ງຄຳຮ້ອງສະໝັກ',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.driver,
    required this.onContactSupport,
    required this.onGoToJobs,
    required this.onResubmit,
  });

  final Driver driver;
  final VoidCallback onContactSupport;
  final VoidCallback onGoToJobs;
  final VoidCallback onResubmit;

  @override
  Widget build(BuildContext context) {
    final (icon, color, title, body) = switch (driver.status) {
      'approved' => (
        Icons.check_circle_rounded,
        AppColors.primaryGreen,
        'ອະນຸມັດແລ້ວ',
        'ທ່ານສາມາດຮັບວຽກຂົນສົ່ງໄດ້ແລ້ວ.',
      ),
      'rejected' => (
        Icons.cancel_rounded,
        Colors.redAccent,
        'ຖືກປະຕິເສດ',
        'ການສະໝັກຂອງທ່ານຖືກປະຕິເສດ — ແກ້ໄຂຂໍ້ມູນແລ້ວສົ່ງໃໝ່ໄດ້ເລີຍ, '
            'ຫຼືຕິດຕໍ່ທີມງານຖ້າຕ້ອງການລາຍລະອຽດ.',
      ),
      _ => (
        Icons.hourglass_top_rounded,
        const Color(0xFFD97706),
        'ລໍຖ້າອະນຸມັດ',
        'ທີມງານກຳລັງກວດສອບຂໍ້ມູນຂອງທ່ານ, ໃຊ້ເວລາບໍ່ດົນ.',
      ),
    };
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(icon, size: 56, color: color),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(label: 'ຊື່', value: driver.driverName),
                _InfoRow(label: 'ເບີໂທ', value: driver.phone),
                _InfoRow(label: 'ປະເພດລົດ', value: driver.vehicleType),
                _InfoRow(label: 'ປ້າຍທະບຽນ', value: driver.vehiclePlate),
              ],
            ),
          ),
          if (driver.status == 'approved') ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: Material(
                color: AppColors.primaryGreen,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: onGoToJobs,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Center(
                      child: Text(
                        'ໄປທີ່ວຽກຂົນສົ່ງ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (driver.status == 'rejected') ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: Material(
                color: AppColors.primaryGreen,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: onResubmit,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Center(
                      child: Text(
                        'ລົງທະບຽນໃໝ່',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onContactSupport,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryGreen,
                  side: BorderSide(color: AppColors.primaryGreen),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'ຕິດຕໍ່ທີມງານ',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _FormInput extends StatelessWidget {
  const _FormInput({
    required this.controller,
    required this.hint,
    this.validator,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      style: TextStyle(fontSize: 13.5, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 13.5, color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primaryGreen : AppColors.secondaryGreen,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.primaryGreen,
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({
    required this.photoUrl,
    required this.uploading,
    required this.onTap,
  });

  final String? photoUrl;
  final bool uploading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: uploading ? null : onTap,
        child: Container(
          width: double.infinity,
          height: 140,
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.primaryGreen.withValues(alpha: 0.4),
              width: 1.4,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: uploading
              ? Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryGreen,
                  ),
                )
              : photoUrl != null
              ? Image.network(photoUrl!, fit: BoxFit.cover)
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo_rounded,
                      color: AppColors.primaryGreen,
                      size: 26,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ເພີ່ມຮູບລົດ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
