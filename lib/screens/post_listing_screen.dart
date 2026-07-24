import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PostListingScreen extends StatefulWidget {
  const PostListingScreen({super.key});

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

  static const _typeOptions = [
    (Icons.apartment_rounded, 'ອາພາດເມັນ'),
    (Icons.bed_rounded, 'ຫ້ອງເຊົ່າ'),
    (Icons.house_rounded, 'ເຮືອນ'),
    (Icons.location_city_rounded, 'ຄອນໂດ'),
    (Icons.holiday_village_rounded, 'ວິນລາ'),
    (Icons.chair_rounded, 'ຫ້ອງການ'),
    (Icons.map_rounded, 'ທີ່ດິນ'),
  ];

  static const _photoPool = [
    'https://images.unsplash.com/photo-1493809842364-78817add7ffb?w=300&q=80',
    'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=300&q=80',
    'https://images.unsplash.com/photo-1484154218962-a197022b5858?w=300&q=80',
    'https://images.unsplash.com/photo-1568605114967-8130f3a36994?w=300&q=80',
    'https://images.unsplash.com/photo-1560184897-ae75f418493e?w=300&q=80',
    'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=300&q=80',
  ];

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

  void _addPhoto() {
    if (_photos.length >= _photoPool.length) return;
    setState(() => _photos.add(_photoPool[_photos.length]));
  }

  void _removePhoto(int i) {
    setState(() => _photos.removeAt(i));
  }

  void _submit() {
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.check_circle_rounded, color: AppColors.primaryGreen),
            SizedBox(width: 10),
            Text('ລົງປະກາດສຳເລັດ'),
          ],
        ),
        content: Text('"${_titleController.text}" ພ້ອມໃຫ້ຜູ້ເຊົ່າເຫັນແລ້ວ.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text(
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
                    color: const Color(0xFFF9FAFB),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.of(context).pop(),
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'ລົງປະກາດ',
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
                        onAdd: _addPhoto,
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
                      const SizedBox(height: 16),
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
                color: Colors.white,
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
                  onTap: _submit,
                  borderRadius: BorderRadius.circular(14),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    child: Center(
                      child: Text(
                        'ລົງປະກາດ',
                        style: TextStyle(
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
      style: const TextStyle(
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
      style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontSize: 13.5,
          color: AppColors.textSecondary,
        ),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
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
          style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: '0',
            hintStyle: const TextStyle(color: AppColors.textSecondary),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
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
    required this.onAdd,
    required this.onRemove,
  });

  final List<String> photos;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          Material(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onAdd,
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
                child: const Column(
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
                          child: const Padding(
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
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
