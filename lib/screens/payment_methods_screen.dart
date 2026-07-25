import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// HomeLao doesn't process payments yet — this is an honest "coming soon"
/// screen rather than a card-entry form with nowhere real to send the data.
class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

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
                    'ວິທີການຊຳລະເງິນ',
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
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.secondaryGreen,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.payment_rounded,
                          size: 32,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'ກຳລັງພັດທະນາ',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ຕອນນີ້ HomeLao ຍັງບໍ່ຮອງຮັບການຊຳລະເງິນຜ່ານແອັບ. '
                        'ການນັດເບິ່ງບ້ານ ແລະ ຕົກລົງລາຄາ ແມ່ນເຮັດຜ່ານການແຊັດກັບເຈົ້າຂອງໂດຍກົງ.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                      ),
                    ],
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
