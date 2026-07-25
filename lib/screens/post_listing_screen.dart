import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/analytics_repository.dart';
import '../data/geolocation.dart';
import '../data/property_repository.dart';
import '../data/storage_repository.dart';
import '../models/property.dart';
import '../theme/app_theme.dart';

class PostListingScreen extends StatefulWidget {
  const PostListingScreen({super.key, this.existing});

  /// When set, the form opens pre-filled for editing this listing instead
  /// of creating a new one — used to let an owner fix and resubmit a
  /// rejected listing rather than leaving them with no way to try again.
  final Property? existing;

  @override
  State<PostListingScreen> createState() => _PostListingScreenState();
}

class _PostListingScreenState extends State<PostListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  final _bedsController = TextEditingController();
  final _bathsController = TextEditingController();
  final _areaController = TextEditingController();
  final _descController = TextEditingController();

  String? _selectedType;
  final List<String> _photos = [];
  bool _submitting = false;
  bool _uploadingPhoto = false;
  double? _lat;
  double? _lng;
  bool _locating = false;

  static const _maxPhotos = 6;

  static const _typeOptions = [
    (Icons.apartment_rounded, 'ອາພາດເມັນ'),
    (Icons.bed_rounded, 'ຫ້ອງເຊົ່າ'),
    (Icons.house_rounded, 'ເຮືອນ'),
    (Icons.location_city_rounded, 'ຄອນໂດ'),
    (Icons.holiday_village_rounded, 'ວິນລາ'),
    (Icons.chair_rounded, 'ຫ້ອງການ'),
    (Icons.map_rounded, 'ທີ່ດິນ'),
  ];

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing == null) return;
    _titleController.text = existing.title;
    _priceController.text = existing.priceLak.toString();
    _locationController.text = existing.location;
    _bedsController.text = existing.beds.toString();
    _bathsController.text = existing.baths.toString();
    _areaController.text = existing.areaSqm.toString();
    _descController.text = existing.description;
    _photos.addAll(existing.photos.isNotEmpty ? existing.photos : [existing.imageUrl]);
    // The listing's category was never persisted when it was first posted,
    // so there's nothing to restore it from — the owner just re-picks it.
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _bedsController.dispose();
    _bathsController.dispose();
    _areaController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _addPhotos() async {
    final remaining = _maxPhotos - _photos.length;
    if (remaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ເພີ່ມຮູບໄດ້ສູງສຸດ $_maxPhotos ໃບ')),
      );
      return;
    }
    // maxWidth/maxHeight/imageQuality make image_picker resize and
    // re-encode each photo client-side (via a canvas, on web) before we
    // ever read its bytes, so every upload is already compressed.
    final files = await ImagePicker().pickMultiImage(
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 82,
      limit: remaining,
    );
    if (files.isEmpty) return;
    final skipped = files.length - remaining;
    final toUpload = files.take(remaining).toList();

    setState(() => _uploadingPhoto = true);
    var failures = 0;
    for (final file in toUpload) {
      try {
        final bytes = await file.readAsBytes();
        final ext = file.name.contains('.')
            ? file.name.split('.').last.toLowerCase()
            : 'jpg';
        final url = await StorageRepository.uploadImage(
          bytes: bytes,
          folder: 'properties',
          extension: ext,
        );
        if (!mounted) return;
        setState(() => _photos.add(url));
      } catch (e, st) {
        Sentry.captureException(e, stackTrace: st);
        failures++;
      }
    }
    if (!mounted) return;
    setState(() => _uploadingPhoto = false);
    if (failures > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ອັບໂຫລດບໍ່ສຳເລັດ $failures ໃບ — ກະລຸນາລອງໃໝ່')),
      );
    } else if (skipped > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ເລືອກຮູບໄດ້ສູງສຸດ $_maxPhotos ໃບ, ຂ້າມໄປ $skipped ໃບ'),
        ),
      );
    }
  }

  void _removePhoto(int i) {
    setState(() => _photos.removeAt(i));
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    try {
      final (lat, lng) = await currentLatLng();
      if (!mounted) return;
      setState(() {
        _lat = lat;
        _lng = lng;
        _locating = false;
      });
    } on GeolocationDenied {
      if (!mounted) return;
      setState(() => _locating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ກະລຸນາອະນຸຍາດການເຂົ້າເຖິງຕຳແໜ່ງ')),
      );
    } on GeolocationUnavailable {
      if (!mounted) return;
      setState(() => _locating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ກະລຸນາເປີດການບໍລິການຕຳແໜ່ງຂອງອຸປະກອນ')),
      );
    } catch (e, st) {
      Sentry.captureException(e, stackTrace: st);
      if (!mounted) return;
      setState(() => _locating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ບັນທຶກຕຳແໜ່ງບໍ່ສຳເລັດ — ກະລຸນາລອງໃໝ່')),
      );
    }
  }

  Future<void> _submit() async {
    final formOk = _formKey.currentState!.validate();
    if (_photos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ກະລຸນາເພີ່ມຮູບຢ່າງໜ້ອຍໜຶ່ງໃບ')),
      );
      return;
    }
    if (_selectedType == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ກະລຸນາເລືອກປະເພດຊັບສິນ')));
      return;
    }
    if (!formOk) return;

    final user = Supabase.instance.client.auth.currentUser;
    final userId = user?.id;
    // Anonymous guests have no name to show, so their listings fall back
    // to Property's generic "unnamed owner" default rather than posting
    // under a guessed identity.
    final landlordName = user?.isAnonymous == false
        ? ((user?.userMetadata?['name'] as String?)?.isNotEmpty == true
              ? user!.userMetadata!['name'] as String
              : user?.email)
        : null;
    final landlordAvatarUrl = user?.userMetadata?['avatar_url'] as String?;
    setState(() => _submitting = true);
    try {
      if (_editing) {
        await PropertyRepository.update(
          id: widget.existing!.id,
          imageUrl: _photos.first,
          photos: _photos,
          priceLak: int.tryParse(_priceController.text.trim()) ?? 0,
          title: _titleController.text.trim(),
          location: _locationController.text.trim(),
          beds: int.tryParse(_bedsController.text.trim()) ?? 0,
          baths: int.tryParse(_bathsController.text.trim()) ?? 0,
          areaSqm: int.tryParse(_areaController.text.trim()) ?? 0,
          description: _descController.text.trim(),
          lat: _lat,
          lng: _lng,
        );
        AnalyticsRepository.track('listing_resubmitted', {
          'category': _selectedType,
        });
      } else if (userId != null) {
        await Supabase.instance.client.from('properties').insert({
          'owner_id': userId,
          'image_url': _photos.first,
          'price_lak': int.tryParse(_priceController.text.trim()) ?? 0,
          'title': _titleController.text.trim(),
          'location': _locationController.text.trim(),
          'beds': int.tryParse(_bedsController.text.trim()) ?? 0,
          'baths': int.tryParse(_bathsController.text.trim()) ?? 0,
          'area_sqm': int.tryParse(_areaController.text.trim()) ?? 0,
          'rating': 0,
          'views': 0,
          'description': _descController.text.trim(),
          'photos': _photos,
          'landlord_name': ?landlordName,
          'landlord_avatar_url': ?landlordAvatarUrl,
          if (_lat != null) 'lat': _lat,
          if (_lng != null) 'lng': _lng,
        });
        AnalyticsRepository.track('listing_posted', {
          'category': _selectedType,
        });
      }
    } catch (e, st) {
      Sentry.captureException(e, stackTrace: st);
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ລົງປະກາດບໍ່ສຳເລັດ: $e')));
      return;
    }
    if (!mounted) return;
    setState(() => _submitting = false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.primaryGreen),
            SizedBox(width: 10),
            Text(_editing ? 'ສົ່ງແກ້ໄຂສຳເລັດ' : 'ລົງປະກາດສຳເລັດ'),
          ],
        ),
        content: Text(
          '"${_titleController.text}" ຖືກສົ່ງໄປແລ້ວ, ລໍຖ້າການອະນຸມັດກ່ອນຈະສະແດງໃຫ້ຜູ້ເຊົ່າເຫັນ.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: Text(
              'ຕົກລົງ',
              style: TextStyle(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
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
                          padding: EdgeInsets.all(10),
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
                    _editing ? 'ແກ້ໄຂປະກາດ' : 'ລົງປະກາດ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _FieldLabel('ຮູບພາບ'),
                      const SizedBox(height: 8),
                      _PhotoRow(
                        photos: _photos,
                        uploading: _uploadingPhoto,
                        onAdd: _addPhotos,
                        onRemove: _removePhoto,
                      ),
                      const SizedBox(height: 20),
                      const _FieldLabel('ປະເພດຊັບສິນ'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final t in _typeOptions)
                            _TypeChip(
                              icon: t.$1,
                              label: t.$2,
                              selected: _selectedType == t.$2,
                              onTap: () => setState(() => _selectedType = t.$2),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const _FieldLabel('ຊື່ລາຍການ'),
                      const SizedBox(height: 8),
                      _FormInput(
                        controller: _titleController,
                        hint: 'ຕົວຢ່າງ: ອາພາດເມັນທັນສະໄໝ ໃກ້ປະຕູໄຊ',
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'ກະລຸນາໃສ່ຊື່ລາຍການ'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      const _FieldLabel('ລາຄາ (ກີບ / ເດືອນ)'),
                      const SizedBox(height: 8),
                      _FormInput(
                        controller: _priceController,
                        hint: 'ຕົວຢ່າງ: 1800000',
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'ກະລຸນາໃສ່ລາຄາ';
                          }
                          if (int.tryParse(v.trim()) == null) {
                            return 'ກະລຸນາໃສ່ຕົວເລກທີ່ຖືກຕ້ອງ';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      const _FieldLabel('ທີ່ຢູ່'),
                      const SizedBox(height: 8),
                      _FormInput(
                        controller: _locationController,
                        hint: 'ຕົວຢ່າງ: ຈັນທະບູລີ, ວຽງຈັນ',
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'ກະລຸນາໃສ່ທີ່ຢູ່'
                            : null,
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _locating ? null : _useCurrentLocation,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _locating
                                  ? SizedBox(
                                      width: 13,
                                      height: 13,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.primaryGreen,
                                      ),
                                    )
                                  : Icon(
                                      _lat != null
                                          ? Icons.check_circle_rounded
                                          : Icons.my_location_rounded,
                                      size: 15,
                                      color: AppColors.primaryGreen,
                                    ),
                              const SizedBox(width: 6),
                              Text(
                                _lat != null
                                    ? 'ບັນທຶກຕຳແໜ່ງແລ້ວ — ຈະໂຊວ໌ໃນຄົ້ນຫາໃກ້ຂ້ອຍ'
                                    : 'ໃຊ້ຕຳແໜ່ງປັດຈຸບັນ (ບໍ່ບັງຄັບ)',
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
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _NumberField(
                              label: 'ຫ້ອງນອນ',
                              controller: _bedsController,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _NumberField(
                              label: 'ຫ້ອງນ້ຳ',
                              controller: _bathsController,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _NumberField(
                              label: 'ເນື້ອທີ່ (ຕມ.)',
                              controller: _areaController,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const _FieldLabel('ລາຍລະອຽດ'),
                      const SizedBox(height: 8),
                      _FormInput(
                        controller: _descController,
                        hint: 'ອະທິບາຍລາຍລະອຽດຊັບສິນ...',
                        maxLines: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                color: AppColors.background,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
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
                              _editing ? 'ສົ່ງແກ້ໄຂອີກຄັ້ງ' : 'ລົງປະກາດ',
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
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
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

class _NumberField extends StatelessWidget {
  const _NumberField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13.5, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: '0',
            hintStyle: TextStyle(color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? Colors.white : AppColors.primaryGreen,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.primaryGreen,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoRow extends StatelessWidget {
  const _PhotoRow({
    required this.photos,
    required this.uploading,
    required this.onAdd,
    required this.onRemove,
  });

  final List<String> photos;
  final bool uploading;
  final Future<void> Function() onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: uploading ? null : onAdd,
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primaryGreen.withValues(alpha: 0.4),
                    width: 1.4,
                  ),
                ),
                child: uploading
                    ? Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo_rounded,
                            color: AppColors.primaryGreen,
                            size: 22,
                          ),
                          SizedBox(height: 6),
                          Text(
                            'ເພີ່ມຮູບ',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          for (var i = 0; i < photos.length; i++)
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    Image.network(
                      photos[i],
                      width: 88,
                      height: 88,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Material(
                        color: Colors.black.withValues(alpha: 0.55),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => onRemove(i),
                          child: const Tooltip(
                            message: 'ລຶບຮູບ',
                            child: Padding(
                              padding: EdgeInsets.all(3),
                              child: Icon(
                                Icons.close_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
