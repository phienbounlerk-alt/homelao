import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/notification_prefs_repository.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  NotificationPrefs _prefs = const NotificationPrefs();
  bool _loadingPrefs = true;

  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscure = true;
  bool _savingPassword = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await NotificationPrefsRepository.fetchMine();
    if (!mounted) return;
    setState(() {
      _prefs = prefs;
      _loadingPrefs = false;
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _changePassword() async {
    final newPassword = _newPasswordController.text;
    if (newPassword.length < 6) {
      _showMessage('ລະຫັດຜ່ານຕ້ອງມີຢ່າງໜ້ອຍ 6 ໂຕ');
      return;
    }
    if (newPassword != _confirmPasswordController.text) {
      _showMessage('ລະຫັດຜ່ານທັງສອງບໍ່ກົງກັນ');
      return;
    }
    setState(() => _savingPassword = true);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      _showMessage('ປ່ຽນລະຫັດຜ່ານສຳເລັດແລ້ວ');
    } on AuthException catch (e) {
      _showMessage(e.message);
    } finally {
      if (mounted) setState(() => _savingPassword = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final isAnon = user?.isAnonymous ?? true;

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
                    'ຕັ້ງຄ່າ',
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
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
                  Text(
                    'ຮູບແບບສະແດງຜົນ',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const _ThemeModeSelector(),
                  const SizedBox(height: 26),
                  Text(
                    'ການແຈ້ງເຕືອນ',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: _loadingPrefs
                        ? Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primaryGreen,
                              ),
                            ),
                          )
                        : Column(
                            children: [
                              _SwitchTile(
                                label: 'ສະຖານະປະກາດ',
                                value: _prefs.listingUpdates,
                                onChanged: (v) {
                                  setState(
                                    () => _prefs = _prefs.copyWith(
                                      listingUpdates: v,
                                    ),
                                  );
                                  NotificationPrefsRepository.setPref(
                                    column: 'listing_updates',
                                    value: v,
                                  );
                                },
                              ),
                              Divider(
                                height: 1,
                                indent: 16,
                                endIndent: 16,
                                color: AppColors.cardBorder,
                              ),
                              _SwitchTile(
                                label: 'ສະໝັກເປັນຄົນຂັບ',
                                value: _prefs.driverUpdates,
                                onChanged: (v) {
                                  setState(
                                    () => _prefs = _prefs.copyWith(
                                      driverUpdates: v,
                                    ),
                                  );
                                  NotificationPrefsRepository.setPref(
                                    column: 'driver_updates',
                                    value: v,
                                  );
                                },
                              ),
                              Divider(
                                height: 1,
                                indent: 16,
                                endIndent: 16,
                                color: AppColors.cardBorder,
                              ),
                              _SwitchTile(
                                label: 'ບໍລິການຂົນສົ່ງ',
                                value: _prefs.movingUpdates,
                                onChanged: (v) {
                                  setState(
                                    () => _prefs = _prefs.copyWith(
                                      movingUpdates: v,
                                    ),
                                  );
                                  NotificationPrefsRepository.setPref(
                                    column: 'moving_updates',
                                    value: v,
                                  );
                                },
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 26),
                  Text(
                    'ບັນຊີ',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (isAnon)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryGreen,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'ທ່ານກຳລັງເຂົ້າໃຊ້ແບບບໍ່ຕ້ອງລົງທະບຽນ — ສະໝັກສະມາຊິກເພື່ອຕັ້ງລະຫັດຜ່ານ.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.accent,
                          height: 1.5,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ປ່ຽນລະຫັດຜ່ານ',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _newPasswordController,
                            obscureText: _obscure,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: AppColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'ລະຫັດຜ່ານໃໝ່',
                              hintStyle: TextStyle(
                                fontSize: 13.5,
                                color: AppColors.textSecondary,
                              ),
                              filled: true,
                              fillColor: AppColors.surfaceAlt,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              suffixIcon: InkWell(
                                onTap: () =>
                                    setState(() => _obscure = !_obscure),
                                child: Tooltip(
                                  message: _obscure
                                      ? 'ສະແດງລະຫັດຜ່ານ'
                                      : 'ເຊື່ອງລະຫັດຜ່ານ',
                                  child: Icon(
                                    _obscure
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 18,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _confirmPasswordController,
                            obscureText: _obscure,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: AppColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'ຢືນຢັນລະຫັດຜ່ານໃໝ່',
                              hintStyle: TextStyle(
                                fontSize: 13.5,
                                color: AppColors.textSecondary,
                              ),
                              filled: true,
                              fillColor: AppColors.surfaceAlt,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: Material(
                              color: AppColors.primaryGreen,
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: _savingPassword ? null : _changePassword,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 13,
                                  ),
                                  child: Center(
                                    child: _savingPassword
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text(
                                            'ປ່ຽນລະຫັດຜ່ານ',
                                            style: TextStyle(
                                              fontSize: 13.5,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primaryGreen,
          ),
        ],
      ),
    );
  }
}

class _ThemeModeSelector extends StatelessWidget {
  const _ThemeModeSelector();

  static const _options = [
    (ThemeMode.system, 'ລະບົບ', Icons.brightness_auto_rounded),
    (ThemeMode.light, 'ແຈ້ງ', Icons.light_mode_rounded),
    (ThemeMode.dark, 'ມືດ', Icons.dark_mode_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance,
      builder: (context, mode, _) {
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              for (final (value, label, icon) in _options)
                Expanded(
                  child: Material(
                    color: mode == value
                        ? AppColors.primaryGreen
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => ThemeController.instance.setMode(value),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              icon,
                              size: 18,
                              color: mode == value
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: mode == value
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
