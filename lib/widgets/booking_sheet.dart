import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/analytics_repository.dart';
import '../models/property.dart';
import '../theme/app_theme.dart';

const _weekdayLabels = ['ຈ', 'ອຄ', 'ພ', 'ພຫ', 'ສກ', 'ສ', 'ອາ'];
const _timeSlots = ['09:00', '10:00', '11:00', '14:00', '15:00', '16:00'];

Future<void> showBookingSheet(BuildContext context, Property property) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _BookingSheet(property: property),
  );
}

class _BookingSheet extends StatefulWidget {
  const _BookingSheet({required this.property});

  final Property property;

  @override
  State<_BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<_BookingSheet> {
  late final _days = List.generate(
    7,
    (i) => DateTime.now().add(Duration(days: i)),
  );
  int _dayIndex = 0;
  String? _time;
  bool _submitting = false;

  /// Today's slots exclude times already passed, so a user browsing at
  /// 5pm can't confirm a "today, 09:00" appointment in the past.
  List<String> get _availableTimeSlots {
    if (_dayIndex != 0) return _timeSlots;
    final now = DateTime.now();
    return _timeSlots.where((t) {
      final parts = t.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return hour > now.hour || (hour == now.hour && minute > now.minute);
    }).toList();
  }

  void _selectDay(int index) {
    setState(() {
      _dayIndex = index;
      if (_time != null && !_availableTimeSlots.contains(_time)) {
        _time = null;
      }
    });
  }

  Future<void> _confirm() async {
    final day = _days[_dayIndex];
    final time = _time!;
    final hour = int.parse(time.split(':')[0]);
    final minute = int.parse(time.split(':')[1]);
    final scheduledAt = DateTime(day.year, day.month, day.day, hour, minute);
    final label = '${_weekdayLabels[day.weekday - 1]} ${day.day}/${day.month}';

    final userId = Supabase.instance.client.auth.currentUser?.id;
    setState(() => _submitting = true);
    try {
      if (userId == null) throw StateError('not signed in');
      await Supabase.instance.client.from('bookings').insert({
        'user_id': userId,
        'property_id': widget.property.id,
        // scheduledAt is built from local wall-clock values (the day/hour
        // the user picked); toIso8601String() on a non-UTC DateTime omits
        // any offset, which Postgres then reads as UTC — silently
        // shifting the stored instant by the local UTC offset. Convert
        // explicitly so the stored instant matches what was picked.
        'scheduled_at': scheduledAt.toUtc().toIso8601String(),
      });
      AnalyticsRepository.track('booking_requested', {
        'property_id': widget.property.id,
      });
    } catch (e, st) {
      Sentry.captureException(e, stackTrace: st);
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ນັດໝາຍບໍ່ສຳເລັດ — ກະລຸນາລອງໃໝ່')),
      );
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Icon(
          Icons.check_circle_rounded,
          color: AppColors.primaryGreen,
          size: 40,
        ),
        title: const Text('ນັດໝາຍສຳເລັດ'),
        content: Text(
          'ນັດເບິ່ງ "${widget.property.title}"\nວັນທີ $label ເວລາ $time ໂມງ',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
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
            Text(
              'ນັດເບິ່ງບ້ານ',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.property.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            Text(
              'ເລືອກວັນ',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 68,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _days.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final day = _days[i];
                  final selected = _dayIndex == i;
                  return Material(
                    color: selected
                        ? AppColors.primaryGreen
                        : AppColors.secondaryGreen,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _selectDay(i),
                      child: Container(
                        width: 52,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _weekdayLabels[day.weekday - 1],
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? Colors.white
                                    : AppColors.primaryGreen,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${day.day}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: selected
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'ເລືອກເວລາ',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            if (_availableTimeSlots.isEmpty)
              Text(
                'ບໍ່ມີເວລາຫວ່າງມື້ນີ້ແລ້ວ — ກະລຸນາເລືອກມື້ອື່ນ',
                style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final t in _availableTimeSlots)
                    Material(
                      color: _time == t
                          ? AppColors.primaryGreen
                          : AppColors.secondaryGreen,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => setState(() => _time = t),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 9,
                          ),
                          child: Text(
                            t,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: _time == t
                                  ? Colors.white
                                  : AppColors.primaryGreen,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: Material(
                color: _time == null
                    ? AppColors.cardBorder
                    : AppColors.primaryGreen,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: (_time == null || _submitting) ? null : _confirm,
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
                          : const Text(
                              'ຢືນຢັນນັດໝາຍ',
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
