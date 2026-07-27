import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../data/review_repository.dart';
import '../data/storage_repository.dart';
import '../models/property.dart';
import '../models/review.dart';
import '../theme/app_theme.dart';

class ReviewFormScreen extends StatefulWidget {
  const ReviewFormScreen({super.key, required this.property, this.existing});

  final Property property;

  /// When set, the form opens pre-filled for editing this review instead
  /// of creating a new one.
  final Review? existing;

  @override
  State<ReviewFormScreen> createState() => _ReviewFormScreenState();
}

class _ReviewFormScreenState extends State<ReviewFormScreen> {
  int _cleanliness = 0;
  int _location = 0;
  int _safety = 0;
  int _internet = 0;
  int _parking = 0;
  int _value = 0;
  final _commentController = TextEditingController();
  final List<String> _photos = [];
  bool _uploadingPhoto = false;
  bool _submitting = false;

  static const _maxPhotos = 4;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing == null) return;
    _cleanliness = existing.cleanliness;
    _location = existing.locationRating;
    _safety = existing.safety;
    _internet = existing.internet;
    _parking = existing.parking;
    _value = existing.value;
    _commentController.text = existing.comment;
    _photos.addAll(existing.photos);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  bool get _allRated =>
      _cleanliness > 0 &&
      _location > 0 &&
      _safety > 0 &&
      _internet > 0 &&
      _parking > 0 &&
      _value > 0;

  Future<void> _addPhotos() async {
    final remaining = _maxPhotos - _photos.length;
    if (remaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ເພີ່ມຮູບໄດ້ສູງສຸດ $_maxPhotos ໃບ')),
      );
      return;
    }
    final files = await ImagePicker().pickMultiImage(
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 82,
      limit: remaining,
    );
    if (files.isEmpty) return;
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
          folder: 'reviews',
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
    }
  }

  void _removePhoto(int i) => setState(() => _photos.removeAt(i));

  Future<void> _submit() async {
    if (!_allRated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ກະລຸນາໃຫ້ຄະແນນທຸກໝວດ')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      if (_editing) {
        await ReviewRepository.update(
          reviewId: widget.existing!.id,
          cleanliness: _cleanliness,
          locationRating: _location,
          safety: _safety,
          internet: _internet,
          parking: _parking,
          value: _value,
          comment: _commentController.text.trim(),
          photos: _photos,
        );
      } else {
        await ReviewRepository.submit(
          propertyId: widget.property.id,
          cleanliness: _cleanliness,
          locationRating: _location,
          safety: _safety,
          internet: _internet,
          parking: _parking,
          value: _value,
          comment: _commentController.text.trim(),
          photos: _photos,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e, st) {
      Sentry.captureException(e, stackTrace: st);
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ສົ່ງຣີວິວບໍ່ສຳເລັດ — ກະລຸນາລອງໃໝ່')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
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
                    _editing ? 'ແກ້ໄຂຣີວິວ' : 'ຂຽນຣີວິວ',
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              widget.property.imageUrl,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.property.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _RatingRow(
                      label: 'ຄວາມສະອາດ',
                      value: _cleanliness,
                      onChanged: (v) => setState(() => _cleanliness = v),
                    ),
                    _RatingRow(
                      label: 'ທຳເລທີ່ຕັ້ງ',
                      value: _location,
                      onChanged: (v) => setState(() => _location = v),
                    ),
                    _RatingRow(
                      label: 'ຄວາມປອດໄພ',
                      value: _safety,
                      onChanged: (v) => setState(() => _safety = v),
                    ),
                    _RatingRow(
                      label: 'ອິນເຕີເນັດ',
                      value: _internet,
                      onChanged: (v) => setState(() => _internet = v),
                    ),
                    _RatingRow(
                      label: 'ບ່ອນຈອດລົດ',
                      value: _parking,
                      onChanged: (v) => setState(() => _parking = v),
                    ),
                    _RatingRow(
                      label: 'ຄຸ້ມຄ່າເງິນ',
                      value: _value,
                      onChanged: (v) => setState(() => _value = v),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'ຄຳເຫັນ',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _commentController,
                      maxLines: 4,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'ແບ່ງປັນປະສົບການຂອງທ່ານກ່ຽວກັບບ້ານຫຼັງນີ້...',
                        hintStyle: TextStyle(
                          fontSize: 13.5,
                          color: AppColors.textSecondary,
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                        contentPadding: const EdgeInsets.all(16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'ຮູບພາບ (ບໍ່ບັງຄັບ)',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _ReviewPhotoRow(
                      photos: _photos,
                      uploading: _uploadingPhoto,
                      onAdd: _addPhotos,
                      onRemove: _removePhoto,
                    ),
                  ],
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
              child: SafeArea(
                top: false,
                child: Material(
                  color: _allRated
                      ? AppColors.primaryGreen
                      : AppColors.primaryGreen.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _submitting ? null : _submit,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      child: Center(
                        child: _submitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _editing ? 'ບັນທຶກການແກ້ໄຂ' : 'ສົ່ງຣີວິວ',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                ),
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

class _RatingRow extends StatelessWidget {
  const _RatingRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Row(
            children: List.generate(5, (i) {
              final filled = i < value;
              return InkWell(
                onTap: () => onChanged(i + 1),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    filled ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 24,
                    color: filled
                        ? AppColors.success
                        : AppColors.textSecondary,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _ReviewPhotoRow extends StatelessWidget {
  const _ReviewPhotoRow({
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
                          const SizedBox(height: 6),
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
