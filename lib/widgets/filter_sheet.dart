import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

const double kFilterMaxPrice = 5000000;

class SearchFilters {
  const SearchFilters({
    this.priceRange = const RangeValues(0, kFilterMaxPrice),
    this.minBeds,
    this.location,
    this.parking = false,
    this.petFriendly = false,
  });

  final RangeValues priceRange;
  final int? minBeds;
  final String? location;
  final bool parking;
  final bool petFriendly;

  SearchFilters copyWith({
    RangeValues? priceRange,
    int? minBeds,
    bool clearMinBeds = false,
    String? location,
    bool clearLocation = false,
    bool? parking,
    bool? petFriendly,
  }) {
    return SearchFilters(
      priceRange: priceRange ?? this.priceRange,
      minBeds: clearMinBeds ? null : (minBeds ?? this.minBeds),
      location: clearLocation ? null : (location ?? this.location),
      parking: parking ?? this.parking,
      petFriendly: petFriendly ?? this.petFriendly,
    );
  }

  bool get isActive =>
      priceRange.start > 0 ||
      priceRange.end < kFilterMaxPrice ||
      minBeds != null ||
      location != null ||
      parking ||
      petFriendly;

  int get activeCount {
    var count = 0;
    if (priceRange.start > 0 || priceRange.end < kFilterMaxPrice) count++;
    if (minBeds != null) count++;
    if (location != null) count++;
    if (parking) count++;
    if (petFriendly) count++;
    return count;
  }
}

Future<SearchFilters?> showFilterSheet(
  BuildContext context, {
  required SearchFilters initial,
  required List<String> locations,
}) {
  return showModalBottomSheet<SearchFilters>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _FilterSheet(initial: initial, locations: locations),
  );
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initial, required this.locations});

  final SearchFilters initial;
  final List<String> locations;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late RangeValues _priceRange = widget.initial.priceRange;
  late int? _minBeds = widget.initial.minBeds;
  late String? _location = widget.initial.location;
  late bool _parking = widget.initial.parking;
  late bool _petFriendly = widget.initial.petFriendly;

  static const _bedOptions = [1, 2, 3, 4];

  String _formatPrice(double v) {
    final s = v.round().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ຕົວກອງ',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                InkWell(
                  onTap: () => setState(() {
                    _priceRange = const RangeValues(0, kFilterMaxPrice);
                    _minBeds = null;
                    _location = null;
                    _parking = false;
                    _petFriendly = false;
                  }),
                  child: Text(
                    'ລ້າງຄ່າ',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'ຊ່ວງລາຄາ (ກີບ/ເດືອນ)',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '${_formatPrice(_priceRange.start)} - ${_formatPrice(_priceRange.end)}',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
            RangeSlider(
              values: _priceRange,
              min: 0,
              max: kFilterMaxPrice,
              divisions: 50,
              activeColor: AppColors.primaryGreen,
              inactiveColor: AppColors.cardBorder,
              onChanged: (v) => setState(() => _priceRange = v),
            ),
            const SizedBox(height: 8),
            Text(
              'ຫ້ອງນອນ',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Chip(
                  label: 'ທັງໝົດ',
                  selected: _minBeds == null,
                  onTap: () => setState(() => _minBeds = null),
                ),
                for (final b in _bedOptions)
                  _Chip(
                    label: b == 4 ? '4+' : '$b',
                    selected: _minBeds == b,
                    onTap: () => setState(() => _minBeds = b),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'ທຳເລ',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Chip(
                  label: 'ທັງໝົດ',
                  selected: _location == null,
                  onTap: () => setState(() => _location = null),
                ),
                for (final loc in widget.locations)
                  _Chip(
                    label: loc,
                    selected: _location == loc,
                    onTap: () => setState(() => _location = loc),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'ສິ່ງອຳນວຍຄວາມສະດວກ',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Chip(
                  label: 'ມີບ່ອນຈອດລົດ',
                  selected: _parking,
                  onTap: () => setState(() => _parking = !_parking),
                ),
                _Chip(
                  label: 'ລ້ຽງສັດໄດ້',
                  selected: _petFriendly,
                  onTap: () => setState(() => _petFriendly = !_petFriendly),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: Material(
                color: AppColors.primaryGreen,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Navigator.of(context).pop(
                    SearchFilters(
                      priceRange: _priceRange,
                      minBeds: _minBeds,
                      location: _location,
                      parking: _parking,
                      petFriendly: _petFriendly,
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    child: Center(
                      child: Text(
                        'ນຳໃຊ້ຕົວກອງ',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
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
