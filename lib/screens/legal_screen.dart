import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

const _lastUpdated = '25 ກໍລະກົດ 2026';

const _termsSections = [
  (
    '1. ການຍອມຮັບເງື່ອນໄຂ',
    'ການສ້າງບັນຊີ ຫຼື ນຳໃຊ້ແອັບ HomeLao ຖືວ່າທ່ານຍອມຮັບເງື່ອນໄຂການນຳໃຊ້ສະບັບນີ້. '
        'ຖ້າທ່ານບໍ່ຍອມຮັບ ກະລຸນາຢຸດການນຳໃຊ້ບໍລິການ.',
  ),
  (
    '2. ນິຍາມການບໍລິການ',
    'HomeLao ເປັນເວທີກາງທີ່ເຊື່ອມຕໍ່ຜູ້ໃຫ້ເຊົ່າ/ຜູ້ຂາຍຊັບສິນ ກັບຜູ້ຊອກຫາທີ່ຢູ່ອາໄສ. '
        'ພວກເຮົາບໍ່ແມ່ນເຈົ້າຂອງ, ບໍ່ຄຸ້ມຄອງ, ແລະ ບໍ່ແມ່ນຄູ່ສັນຍາໃນການເຊົ່າ/ຊື້-ຂາຍໃດໆ '
        'ທີ່ເກີດຂຶ້ນລະຫວ່າງຜູ້ໃຊ້. ພວກເຮົາເປັນພຽງຊ່ອງທາງໃຫ້ຂໍ້ມູນພົບກັນເທົ່ານັ້ນ.',
  ),
  (
    '3. ໜ້າທີ່ຄວາມຮັບຜິດຊອບຂອງຜູ້ໃຊ້',
    'ທ່ານຕ້ອງໃຫ້ຂໍ້ມູນທີ່ຖືກຕ້ອງ ແລະ ເປັນຈິງໃນການລົງທະບຽນ ແລະ ການລົງປະກາດ. ຫ້າມລົງປະກາດ '
        'ຊັບສິນທີ່ບໍ່ມີຢູ່ຈິງ, ຫຼອກລວງ, ຫຼື ລະເມີດກົດໝາຍ. ທ່ານຮັບຜິດຊອບຕໍ່ຄວາມປອດໄພຂອງຕົນເອງ '
        'ໃນການນັດພົບ ຫຼື ເຂົ້າເບິ່ງຊັບສິນກັບຜູ້ໃຊ້ອື່ນ — ແນະນຳໃຫ້ນັດພົບໃນເວລາກາງເວັນ ແລະ '
        'ແຈ້ງບຸກຄົນທີ່ໄວ້ໃຈໄດ້ຮູ້ກ່ອນໄປ.',
  ),
  (
    '4. ເນື້ອຫາປະກາດ ແລະ ລິຂະສິດ',
    'ທ່ານເປັນເຈົ້າຂອງຮູບພາບ ແລະ ຂໍ້ຄວາມທີ່ທ່ານອັບໂຫລດ ແຕ່ອະນຸຍາດໃຫ້ HomeLao ສະແດງເນື້ອຫາ '
        'ນັ້ນຢູ່ໃນແອັບເພື່ອຈຸດປະສົງໃນການໃຫ້ບໍລິການ. ພວກເຮົາສະຫງວນສິດລຶບ ຫຼື ປະຕິເສດປະກາດໃດໆ '
        'ທີ່ລະເມີດເງື່ອນໄຂນີ້ໂດຍບໍ່ຕ້ອງແຈ້ງລ່ວງໜ້າ.',
  ),
  (
    '5. ຄ່າທຳນຽມການຂຶ້ນເດັ່ນ',
    'ຄ່າທຳນຽມສຳລັບການເຮັດໃຫ້ປະກາດ "ຂຶ້ນເດັ່ນ" ຕ້ອງຊຳລະຜ່ານການໂອນເງິນຕາມຂໍ້ມູນທີ່ໃຫ້ໄວ້ໃນແອັບ '
        'ແລະ ຈະຖືກຢືນຢັນໂດຍທີມງານຫຼັງກວດຫຼັກຖານການໂອນ. ຄ່າທຳນຽມທີ່ຢືນຢັນແລ້ວຈະບໍ່ສາມາດຂໍຄືນໄດ້ '
        'ເວັ້ນເສຍແຕ່ເກີດຄວາມຜິດພາດຈາກຝ່າຍ HomeLao ເອງ.',
  ),
  (
    '6. ຂໍ້ຈຳກັດຄວາມຮັບຜິດຊອບ',
    'HomeLao ໃຫ້ບໍລິການ "ຕາມສະພາບທີ່ເປັນຢູ່" ໂດຍບໍ່ຮັບປະກັນຄວາມຖືກຕ້ອງຂອງຂໍ້ມູນປະກາດ, '
        'ຄຸນນະພາບຊັບສິນ, ຫຼື ຄວາມໜ້າເຊື່ອຖືຂອງຜູ້ໃຊ້ອື່ນ. ພວກເຮົາບໍ່ຮັບຜິດຊອບຕໍ່ຄວາມເສຍຫາຍທີ່ເກີດຈາກ '
        'ຂໍ້ຂັດແຍ່ງ, ການສູນເສຍ, ຫຼື ອຸບັດຕິເຫດທີ່ເກີດຂຶ້ນລະຫວ່າງຜູ້ໃຊ້.',
  ),
  (
    '7. ການລະງັບ ຫຼື ຍົກເລີກບັນຊີ',
    'ພວກເຮົາສະຫງວນສິດລະງັບ ຫຼື ລຶບບັນຊີທີ່ລະເມີດເງື່ອນໄຂເຫຼົ່ານີ້, ລວມທັງການລົງປະກາດຫຼອກລວງ '
        'ຫຼື ພຶດຕິກຳທີ່ເປັນອັນຕະລາຍຕໍ່ຜູ້ໃຊ້ອື່ນ ໂດຍບໍ່ຈຳເປັນຕ້ອງແຈ້ງລ່ວງໜ້າ.',
  ),
  (
    '8. ກົດໝາຍທີ່ນຳໃຊ້',
    'ເງື່ອນໄຂນີ້ຢູ່ພາຍໃຕ້ກົດໝາຍຂອງ ສາທາລະນະລັດ ປະຊາທິປະໄຕ ປະຊາຊົນລາວ.',
  ),
  (
    '9. ການປ່ຽນແປງເງື່ອນໄຂ',
    'ພວກເຮົາອາດປັບປຸງເງື່ອນໄຂນີ້ເປັນບາງຄາວ ການສືບຕໍ່ນຳໃຊ້ແອັບຫຼັງການປັບປຸງຖືວ່າທ່ານຍອມຮັບ '
        'ເງື່ອນໄຂສະບັບໃໝ່.',
  ),
  (
    '10. ຕິດຕໍ່ພວກເຮົາ',
    'ມີຄຳຖາມກ່ຽວກັບເງື່ອນໄຂການນຳໃຊ້ນີ້ ຕິດຕໍ່ support@homelao.la',
  ),
];

const _privacySections = [
  (
    '1. ຂໍ້ມູນທີ່ພວກເຮົາເກັບກຳ',
    'ພວກເຮົາເກັບກຳ: ຂໍ້ມູນບັນຊີ (ອີເມວ, ຊື່, ຮູບໂປຼໄຟລ໌), ເນື້ອຫາປະກາດ ແລະ ຮູບພາບຊັບສິນ, '
        'ຂໍ້ຄວາມແຊັດລະຫວ່າງຜູ້ໃຊ້, ຄຳຂໍນັດເບິ່ງບ້ານ, ຫຼັກຖານການໂອນເງິນສຳລັບຄ່າທຳນຽມຂຶ້ນເດັ່ນ, '
        'ແລະ ຂໍ້ມູນຄວາມຜິດພາດດ້ານເຕັກນິກເມື່ອແອັບເກີດບັນຫາ.',
  ),
  (
    '2. ວິທີການນຳໃຊ້ຂໍ້ມູນ',
    'ຂໍ້ມູນຖືກນຳໃຊ້ເພື່ອດຳເນີນການເວທີກາງ (ຈັບຄູ່ຜູ້ຊື້-ຜູ້ຂາຍ), ອຳນວຍການສື່ສານລະຫວ່າງຜູ້ໃຊ້, '
        'ກວດສອບ/ອະນຸມັດປະກາດ, ປ້ອງກັນການສໍ້ໂກງ, ແລະ ປັບປຸງຄຸນນະພາບການບໍລິການ. ພວກເຮົາບໍ່ຂາຍ '
        'ຂໍ້ມູນສ່ວນຕົວຂອງທ່ານໃຫ້ບຸກຄົນທີສາມເພື່ອຈຸດປະສົງການໂຄສະນາ.',
  ),
  (
    '3. ການແບ່ງປັນຂໍ້ມູນກັບບຸກຄົນທີສາມ',
    'ພວກເຮົາໃຊ້ Supabase ເພື່ອເກັບຮັກສາຖານຂໍ້ມູນ, ໄຟລ໌ຮູບພາບ, ແລະ ຈັດການການເຂົ້າສູ່ລະບົບ, '
        'ແລະ ໃຊ້ Sentry ເພື່ອຕິດຕາມ ແລະ ແກ້ໄຂຂໍ້ຜິດພາດດ້ານເຕັກນິກ (ຂໍ້ມູນທີ່ສົ່ງໃຫ້ Sentry ບໍ່ລວມ '
        'ລະຫັດຜ່ານ ຫຼື ຂໍ້ມູນການຊຳລະເງິນ). ຜູ້ໃຫ້ບໍລິການທັງສອງນີ້ປະມວນຜົນຂໍ້ມູນຕາມນະໂຍບາຍຄວາມ '
        'ປອດໄພຂອງຕົນເອງ ແລະ ຖືກຜູກມັດໃຫ້ນຳໃຊ້ຂໍ້ມູນສະເພາະເພື່ອໃຫ້ບໍລິການແກ່ HomeLao ເທົ່ານັ້ນ.',
  ),
  (
    '4. ຄວາມປອດໄພຂອງຂໍ້ມູນ',
    'ຂໍ້ມູນຖືກເຂົ້າລະຫັດລະຫວ່າງການສົ່ງຜ່ານ ແລະ ຄວບຄຸມການເຂົ້າເຖິງດ້ວຍນະໂຍບາຍລະດັບແຖວຂໍ້ມູນ '
        '(row-level security) — ຜູ້ໃຊ້ແຕ່ລະຄົນເຂົ້າເຖິງໄດ້ສະເພາະຂໍ້ມູນຂອງຕົນເອງ ຫຼື ຂໍ້ມູນທີ່ເປີດເຜີຍ '
        'ຕໍ່ສາທາລະນະ (ເຊັ່ນ ປະກາດທີ່ອະນຸມັດແລ້ວ).',
  ),
  (
    '5. ໄລຍະເວລາເກັບຮັກສາ ແລະ ການລຶບຂໍ້ມູນ',
    'ຂໍ້ມູນຂອງທ່ານຖືກເກັບໄວ້ຕາບໃດທີ່ບັນຊີຍັງເປີດໃຊ້ງານຢູ່. ທ່ານສາມາດຂໍລຶບບັນຊີ ແລະ ຂໍ້ມູນທັງໝົດ '
        'ໄດ້ໂດຍຕິດຕໍ່ support@homelao.la — ພວກເຮົາຈະດຳເນີນການລຶບພາຍໃນເວລາອັນສົມຄວນ '
        'ຍົກເວັ້ນຂໍ້ມູນທີ່ຕ້ອງເກັບໄວ້ຕາມກົດໝາຍ.',
  ),
  (
    '6. ສິດຂອງທ່ານ',
    'ທ່ານມີສິດເຂົ້າເຖິງ, ແກ້ໄຂ, ຫຼື ລຶບຂໍ້ມູນສ່ວນຕົວຂອງທ່ານ — ຂໍ້ມູນໂປຼໄຟລ໌ພື້ນຖານແກ້ໄຂໄດ້ໂດຍກົງ '
        'ໃນແອັບ (ໂປຼໄຟລ໌ > ແກ້ໄຂໂປຼໄຟລ໌), ສ່ວນຄຳຂໍອື່ນໆຕິດຕໍ່ໄດ້ຕາມຊ່ອງທາງລຸ່ມນີ້.',
  ),
  (
    '7. Cookies ແລະ ການເກັບຂໍ້ມູນໃນອຸປະກອນ',
    'ແອັບເກັບຮັກສາ token ການເຂົ້າສູ່ລະບົບ ແລະ ຄ່າຕັ້ງ (ເຊັ່ນ ໂໝດມືດ/ແຈ້ງ) ໄວ້ໃນອຸປະກອນຂອງທ່ານ '
        'ເພື່ອໃຫ້ທ່ານບໍ່ຕ້ອງເຂົ້າສູ່ລະບົບໃໝ່ທຸກຄັ້ງ ແລະ ຈື່ຄວາມມັກຂອງທ່ານ.',
  ),
  (
    '8. ຜູ້ໃຊ້ອາຍຸຕ່ຳກວ່າກຳນົດ',
    'HomeLao ບໍ່ໄດ້ອອກແບບມາສຳລັບຜູ້ໃຊ້ທີ່ອາຍຸຕ່ຳກວ່າ 18 ປີ ພວກເຮົາບໍ່ໄດ້ຕັ້ງໃຈເກັບກຳຂໍ້ມູນຈາກ '
        'ຜູ້ເຍົາທີ່ຮູ້ໂດຍເຈດຕະນາ.',
  ),
  (
    '9. ການປ່ຽນແປງນະໂຍບາຍ',
    'ນະໂຍບາຍນີ້ອາດຖືກປັບປຸງເປັນບາງຄາວ ວັນທີ່ປັບປຸງລ່າສຸດຈະສະແດງຢູ່ເທິງໜ້ານີ້ສະເໝີ.',
  ),
  (
    '10. ຕິດຕໍ່ພວກເຮົາ',
    'ມີຄຳຖາມກ່ຽວກັບຄວາມເປັນສ່ວນຕົວຂອງຂໍ້ມູນ ຕິດຕໍ່ support@homelao.la',
  ),
];

class LegalScreen extends StatefulWidget {
  const LegalScreen({super.key, this.initialTab = 0});

  /// 0 = ເງື່ອນໄຂການນຳໃຊ້, 1 = ນະໂຍບາຍຄວາມເປັນສ່ວນຕົວ
  final int initialTab;

  @override
  State<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends State<LegalScreen>
    with SingleTickerProviderStateMixin {
  late final _tabController = TabController(
    length: 2,
    vsync: this,
    initialIndex: widget.initialTab,
  );

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
                    'ເງື່ອນໄຂ ແລະ ຄວາມເປັນສ່ວນຕົວ',
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
                Tab(text: 'ເງື່ອນໄຂການນຳໃຊ້'),
                Tab(text: 'ຄວາມເປັນສ່ວນຕົວ'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  _LegalDocument(sections: _termsSections),
                  _LegalDocument(sections: _privacySections),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegalDocument extends StatelessWidget {
  const _LegalDocument({required this.sections});

  final List<(String, String)> sections;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Text(
          'ອັບເດດລ່າສຸດ: $_lastUpdated',
          style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 18),
        for (final section in sections) ...[
          Text(
            section.$1,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            section.$2,
            style: TextStyle(
              fontSize: 13,
              height: 1.6,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ],
    );
  }
}
