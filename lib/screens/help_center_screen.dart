import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

const _whatsappNumber = '+856 20 1234 5678';
const _supportEmail = 'support@homelao.la';

const _faqs = [
  (
    'ຂ້ອຍຈະລົງປະກາດຊັບສິນແນວໃດ?',
    'ກົດປຸ່ມ "+" ຢູ່ແຖບລຸ່ມ, ຕື່ມຂໍ້ມູນຊັບສິນ, ເລືອກປະເພດ ແລະ ເພີ່ມຮູບຢ່າງໜ້ອຍໜຶ່ງໃບ ແລ້ວກົດລົງປະກາດ.',
  ),
  (
    'ຂ້ອຍຈະນັດເບິ່ງບ້ານແນວໃດ?',
    'ເປີດໜ້າລາຍລະອຽດຊັບສິນ ແລ້ວກົດ "ນັດເບິ່ງບ້ານ", ເລືອກວັນ ແລະ ເວລາທີ່ສະດວກ.',
  ),
  (
    'ຂ້ອຍຈະຕິດຕໍ່ເຈົ້າຂອງຊັບສິນແນວໃດ?',
    'ກົດ "ແຊັດເຈົ້າຂອງ" ຢູ່ໜ້າລາຍລະອຽດຊັບສິນ ເພື່ອເປີດການສົນທະນາໂດຍກົງ.',
  ),
  (
    'ຂໍ້ມູນຊັບສິນທີ່ບັນທຶກໄວ້ຢູ່ໃສ?',
    'ໄປທີ່ ໂປຼໄຟລ໌ > ຊັບສິນທີ່ບັນທຶກ ເພື່ອເບິ່ງລາຍການທັງໝົດທີ່ທ່ານກົດຫົວໃຈໄວ້.',
  ),
  (
    'ຂ້ອຍລືມລະຫັດຜ່ານ ຄວນເຮັດແນວໃດ?',
    'ຕິດຕໍ່ທີມງານຜ່ານຊ່ອງທາງດ້ານລຸ່ມນີ້ ເພື່ອຂໍຄວາມຊ່ວຍເຫຼືອໃນການຕັ້ງລະຫັດຜ່ານໃໝ່.',
  ),
];

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  int? _expanded;

  Future<void> _launch(Uri uri, String failureMessage) async {
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e, st) {
      Sentry.captureException(e, stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failureMessage)));
    }
  }

  Future<void> _openWhatsApp() {
    final digits = _whatsappNumber.replaceAll(RegExp(r'[^0-9]'), '');
    return _launch(
      Uri.parse('https://wa.me/$digits'),
      'ເປີດ WhatsApp ບໍ່ສຳເລັດ — ກະລຸນາລອງໃໝ່',
    );
  }

  Future<void> _sendEmail() {
    return _launch(
      Uri(scheme: 'mailto', path: _supportEmail),
      'ເປີດແອັບອີເມວບໍ່ສຳເລັດ — ກະລຸນາລອງໃໝ່',
    );
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
                    'ສູນຊ່ວຍເຫຼືອ',
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
                    'ຄຳຖາມທີ່ພົບເລື້ອຍ',
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
                    child: Column(
                      children: [
                        for (var i = 0; i < _faqs.length; i++) ...[
                          _FaqTile(
                            question: _faqs[i].$1,
                            answer: _faqs[i].$2,
                            expanded: _expanded == i,
                            onTap: () => setState(
                              () => _expanded = _expanded == i ? null : i,
                            ),
                          ),
                          if (i != _faqs.length - 1)
                            Divider(
                              height: 1,
                              indent: 16,
                              endIndent: 16,
                              color: AppColors.cardBorder,
                            ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  Text(
                    'ຕິດຕໍ່ພວກເຮົາ',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        _ContactRow(
                          icon: Icons.chat_bubble_rounded,
                          label: 'WhatsApp / WeChat',
                          value: _whatsappNumber,
                          onTap: _openWhatsApp,
                        ),
                        const SizedBox(height: 14),
                        _ContactRow(
                          icon: Icons.email_rounded,
                          label: 'ອີເມວ',
                          value: _supportEmail,
                          onTap: _sendEmail,
                        ),
                        const SizedBox(height: 14),
                        const _ContactRow(
                          icon: Icons.access_time_rounded,
                          label: 'ເວລາເຮັດວຽກ',
                          value: 'ຈັນ - ສຸກ, 8:00 - 18:00',
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

class _FaqTile extends StatelessWidget {
  const _FaqTile({
    required this.question,
    required this.answer,
    required this.expanded,
    required this.onTap,
  });

  final String question;
  final String answer;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      question,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.remove_circle_outline_rounded
                        : Icons.add_circle_outline_rounded,
                    size: 20,
                    color: AppColors.primaryGreen,
                  ),
                ],
              ),
              if (expanded) ...[
                const SizedBox(height: 8),
                Text(
                  answer,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primaryGreen),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: onTap != null
                      ? AppColors.primaryGreen
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        if (onTap != null)
          Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: AppColors.textSecondary,
          ),
      ],
    );
    if (onTap == null) return row;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: row,
        ),
      ),
    );
  }
}
