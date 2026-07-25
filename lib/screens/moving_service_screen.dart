import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/driver_repository.dart';
import '../models/moving_request.dart';
import '../theme/app_theme.dart';
import 'driver_tracking_screen.dart';

const _vehicleTypes = ['ລົດກະບະ', 'ລົດບັນທຸກກາງ', 'ລົດບັນທຸກໃຫຍ່'];

class MovingServiceScreen extends StatefulWidget {
  const MovingServiceScreen({super.key});

  @override
  State<MovingServiceScreen> createState() => _MovingServiceScreenState();
}

class _MovingServiceScreenState extends State<MovingServiceScreen>
    with SingleTickerProviderStateMixin {
  late final _tabController = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _goToMyRequests() => _tabController.animateTo(1);

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
                    'ບໍລິການຮັບຂົນສົ່ງເຄື່ອງ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              labelColor: AppColors.primaryGreen,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primaryGreen,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              tabs: const [
                Tab(text: 'ສົ່ງຄຳຮ້ອງ'),
                Tab(text: 'ຄຳຮ້ອງຂອງຂ້ອຍ'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _NewRequestTab(onSubmitted: _goToMyRequests),
                  const _MyRequestsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewRequestTab extends StatefulWidget {
  const _NewRequestTab({required this.onSubmitted});

  final VoidCallback onSubmitted;

  @override
  State<_NewRequestTab> createState() => _NewRequestTabState();
}

class _NewRequestTabState extends State<_NewRequestTab> {
  final _formKey = GlobalKey<FormState>();
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();
  final _notesController = TextEditingController();

  String? _vehicleType;
  DateTime? _date;
  bool _submitting = false;

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_vehicleType == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ກະລຸນາເລືອກຂະໜາດລົດ')));
      return;
    }
    if (_date == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ກະລຸນາເລືອກວັນທີ')));
      return;
    }
    setState(() => _submitting = true);
    try {
      await DriverRepository.submitRequest(
        pickupLocation: _pickupController.text.trim(),
        dropoffLocation: _dropoffController.text.trim(),
        vehicleType: _vehicleType!,
        preferredDate: _date!,
        notes: _notesController.text.trim(),
      );
      if (!mounted) return;
      _pickupController.clear();
      _dropoffController.clear();
      _notesController.clear();
      setState(() {
        _vehicleType = null;
        _date = null;
        _submitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ສົ່ງຄຳຮ້ອງແລ້ວ — ລໍຖ້າຄົນຂັບຮັບວຽກ')),
      );
      widget.onSubmitted();
    } catch (e, st) {
      Sentry.captureException(e, stackTrace: st);
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ສົ່ງຄຳຮ້ອງບໍ່ສຳເລັດ — ກະລຸນາລອງໃໝ່')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FieldLabel('ຈຸດຮັບເຄື່ອງ'),
            const SizedBox(height: 8),
            _FormInput(
              controller: _pickupController,
              hint: 'ຕົວຢ່າງ: ຈັນທະບູລີ, ວຽງຈັນ',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'ກະລຸນາໃສ່ຈຸດຮັບ' : null,
            ),
            const SizedBox(height: 16),
            _FieldLabel('ຈຸດສົ່ງເຄື່ອງ'),
            const SizedBox(height: 8),
            _FormInput(
              controller: _dropoffController,
              hint: 'ຕົວຢ່າງ: ສີສັດຕະນາກ, ວຽງຈັນ',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'ກະລຸນາໃສ່ຈຸດສົ່ງ' : null,
            ),
            const SizedBox(height: 16),
            _FieldLabel('ຂະໜາດລົດທີ່ຕ້ອງການ'),
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
            _FieldLabel('ວັນທີ່ຕ້ອງການ'),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_month_rounded,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _date == null
                          ? 'ເລືອກວັນທີ່'
                          : '${_date!.day}/${_date!.month}/${_date!.year}',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: _date == null
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _FieldLabel('ໝາຍເຫດ (ບໍ່ບັງຄັບ)'),
            const SizedBox(height: 8),
            _FormInput(
              controller: _notesController,
              hint: 'ຕົວຢ່າງ: ມີເຄື່ອງໃຫຍ່, ຂຶ້ນຊັ້ນ 3...',
              maxLines: 3,
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
                          : const Text(
                              'ສົ່ງຄຳຮ້ອງ',
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

class _MyRequestsTab extends StatelessWidget {
  const _MyRequestsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MovingRequest>>(
      stream: DriverRepository.streamMyRequests(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.primaryGreen),
          );
        }
        final requests = snapshot.data!;
        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.local_shipping_outlined,
                  size: 48,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 12),
                Text(
                  'ຍັງບໍ່ມີຄຳຮ້ອງຂົນສົ່ງ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          itemCount: requests.length,
          separatorBuilder: (_, _) => const SizedBox(height: 14),
          itemBuilder: (context, i) => _RequestCard(request: requests[i]),
        );
      },
    );
  }
}

class _RequestCard extends StatefulWidget {
  const _RequestCard({required this.request});

  final MovingRequest request;

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  bool _loadingDriver = false;

  Future<void> _callDriver(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    try {
      await launchUrl(uri);
    } catch (e, st) {
      Sentry.captureException(e, stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ໂທອອກບໍ່ສຳເລັດ — ກະລຸນາລອງໃໝ່')),
      );
    }
  }

  Future<void> _showDriverContact() async {
    final driverId = widget.request.driverId;
    if (driverId == null) return;
    setState(() => _loadingDriver = true);
    try {
      final driver = await DriverRepository.fetchById(driverId);
      if (!mounted) return;
      setState(() => _loadingDriver = false);
      if (driver == null || !mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('ຂໍ້ມູນຄົນຂັບ'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ຊື່: ${driver.driverName}'),
              const SizedBox(height: 6),
              InkWell(
                onTap: () => _callDriver(driver.phone),
                borderRadius: BorderRadius.circular(6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('ເບີໂທ: ${driver.phone}'),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.call_rounded,
                      size: 15,
                      color: AppColors.primaryGreen,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text('ລົດ: ${driver.vehicleType} (${driver.vehiclePlate})'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'ປິດ',
                style: TextStyle(color: AppColors.primaryGreen),
              ),
            ),
          ],
        ),
      );
    } catch (e, st) {
      Sentry.captureException(e, stackTrace: st);
      if (!mounted) return;
      setState(() => _loadingDriver = false);
    }
  }

  Future<void> _cancel() async {
    try {
      await DriverRepository.cancelRequest(widget.request);
    } catch (e, st) {
      Sentry.captureException(e, stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ຍົກເລີກບໍ່ສຳເລັດ — ກະລຸນາລອງໃໝ່')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    final (label, color) = switch (request.status) {
      'accepted' => ('ຄົນຂັບຮັບແລ້ວ', const Color(0xFF2563EB)),
      'in_progress' => ('ກຳລັງດຳເນີນການ', AppColors.primaryGreen),
      'completed' => ('ສຳເລັດແລ້ວ', AppColors.textSecondary),
      'cancelled' => ('ຍົກເລີກແລ້ວ', Colors.redAccent),
      _ => ('ລໍຖ້າຄົນຂັບຮັບ', const Color(0xFFD97706)),
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                request.vehicleType,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _RouteRow(
            icon: Icons.trip_origin_rounded,
            label: request.pickupLocation,
          ),
          const SizedBox(height: 4),
          _RouteRow(
            icon: Icons.location_on_rounded,
            label: request.dropoffLocation,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 13,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                '${request.preferredDate.day}/${request.preferredDate.month}/${request.preferredDate.year}',
                style: TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          if (request.driverId != null &&
              (request.status == 'accepted' ||
                  request.status == 'in_progress')) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: Material(
                color: AppColors.primaryGreen,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          DriverTrackingScreen(driverId: request.driverId!),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.map_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'ເບິ່ງແຜນທີ່',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (request.driverId != null || request.status == 'pending') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (request.driverId != null)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _loadingDriver ? null : _showDriverContact,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryGreen,
                        side: BorderSide(color: AppColors.primaryGreen),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _loadingDriver
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('ຕິດຕໍ່ຄົນຂັບ'),
                    ),
                  ),
                if (request.driverId != null && request.status == 'pending')
                  const SizedBox(width: 10),
                if (request.status == 'pending')
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _cancel,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('ຍົກເລີກ'),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  const _RouteRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: AppColors.primaryGreen),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 12.5, color: AppColors.textPrimary),
          ),
        ),
      ],
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
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String hint;
  final String? Function(String?)? validator;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
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
