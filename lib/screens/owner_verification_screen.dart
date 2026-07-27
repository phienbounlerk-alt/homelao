import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/owner_verification_repository.dart';
import '../data/storage_repository.dart';
import '../models/owner_verification.dart';
import '../theme/app_theme.dart';
import '../widgets/error_state.dart';
import 'help_center_screen.dart';

class OwnerVerificationScreen extends StatefulWidget {
  const OwnerVerificationScreen({super.key});

  @override
  State<OwnerVerificationScreen> createState() =>
      _OwnerVerificationScreenState();
}

class _OwnerVerificationScreenState extends State<OwnerVerificationScreen> {
  final _phoneController = TextEditingController();

  String? _idDocPath;
  String? _selfiePath;
  String? _ownershipDocPath;
  String? _idDocPreviewUrl;
  String? _selfiePreviewUrl;
  String? _ownershipDocPreviewUrl;
  String? _uploadingField;
  bool _submitting = false;
  bool _resendingEmail = false;

  bool _loading = true;
  bool _error = false;
  bool _editing = false;
  OwnerVerification? _existing;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  bool get _emailConfirmed =>
      Supabase.instance.client.auth.currentUser?.emailConfirmedAt != null;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final verification = await OwnerVerificationRepository.fetchMine();
      if (!mounted) return;
      setState(() {
        _existing = verification;
        _loading = false;
      });
    } catch (e, st) {
      Sentry.captureException(e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  Future<void> _pickDocument({
    required String field,
    required String folder,
  }) async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (file == null) return;
    setState(() => _uploadingField = field);
    try {
      final bytes = await file.readAsBytes();
      final ext = file.name.contains('.')
          ? file.name.split('.').last.toLowerCase()
          : 'jpg';
      final path = await StorageRepository.uploadVerificationDocument(
        bytes: bytes,
        folder: folder,
        extension: ext,
      );
      final previewUrl = await StorageRepository.signedVerificationDocUrl(
        path,
      );
      if (!mounted) return;
      setState(() {
        switch (field) {
          case 'id':
            _idDocPath = path;
            _idDocPreviewUrl = previewUrl;
          case 'selfie':
            _selfiePath = path;
            _selfiePreviewUrl = previewUrl;
          case 'ownership':
            _ownershipDocPath = path;
            _ownershipDocPreviewUrl = previewUrl;
        }
        _uploadingField = null;
      });
    } catch (e, st) {
      Sentry.captureException(e, stackTrace: st);
      if (!mounted) return;
      setState(() => _uploadingField = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ອັບໂຫລດເອກະສານບໍ່ສຳເລັດ — ກະລຸນາລອງໃໝ່')),
      );
    }
  }

  Future<void> _startResubmit() async {
    final existing = _existing!;
    _phoneController.text = existing.phoneNumber ?? '';
    setState(() {
      _idDocPath = existing.idDocumentUrl;
      _selfiePath = existing.selfieUrl;
      _ownershipDocPath = existing.ownershipDocumentUrl;
      _editing = true;
    });
    // Refresh signed preview URLs for whatever documents already exist —
    // the ones from the original submission have long since expired.
    if (_idDocPath != null) {
      StorageRepository.signedVerificationDocUrl(_idDocPath!).then((url) {
        if (mounted) setState(() => _idDocPreviewUrl = url);
      });
    }
    if (_selfiePath != null) {
      StorageRepository.signedVerificationDocUrl(_selfiePath!).then((url) {
        if (mounted) setState(() => _selfiePreviewUrl = url);
      });
    }
    if (_ownershipDocPath != null) {
      StorageRepository.signedVerificationDocUrl(
        _ownershipDocPath!,
      ).then((url) {
        if (mounted) setState(() => _ownershipDocPreviewUrl = url);
      });
    }
  }

  Future<void> _resendEmailConfirmation() async {
    setState(() => _resendingEmail = true);
    try {
      await OwnerVerificationRepository.resendEmailConfirmation();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ສົ່ງອີເມວຢືນຢັນອີກຄັ້ງແລ້ວ — ກະລຸນາກວດອີເມວຂອງທ່ານ')),
      );
    } catch (e, st) {
      Sentry.captureException(e, stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ສົ່ງອີເມວບໍ່ສຳເລັດ — ກະລຸນາລອງໃໝ່')),
      );
    } finally {
      if (mounted) setState(() => _resendingEmail = false);
    }
  }

  Future<void> _submit() async {
    if (_idDocPath == null || _selfiePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ກະລຸນາອັບໂຫລດບັດປະຈຳຕົວ ແລະ ຮູບ Selfie')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      if (_editing && _existing != null) {
        await OwnerVerificationRepository.resubmit(
          id: _existing!.id,
          idDocumentUrl: _idDocPath,
          selfieUrl: _selfiePath,
          ownershipDocumentUrl: _ownershipDocPath,
          phoneNumber: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
        );
      } else {
        await OwnerVerificationRepository.submit(
          idDocumentUrl: _idDocPath,
          selfieUrl: _selfiePath,
          ownershipDocumentUrl: _ownershipDocPath,
          phoneNumber: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
        );
      }
      if (!mounted) return;
      setState(() => _editing = false);
      await _load();
    } catch (e, st) {
      Sentry.captureException(e, stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ສົ່ງຄຳຮ້ອງບໍ່ສຳເລັດ — ກະລຸນາລອງໃໝ່')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
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
                    'ຢືນຢັນຕົວຕົນເຈົ້າຂອງ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.primaryGreen),
      );
    }
    if (_error) return ErrorState(onRetry: _load);
    if (_existing != null && !_editing) {
      return _StatusCard(
        verification: _existing!,
        onContactSupport: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const HelpCenterScreen())),
        onResubmit: _startResubmit,
      );
    }
    return _buildForm();
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_editing)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => setState(() => _editing = false),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_back_rounded,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'ຍົກເລີກການແກ້ໄຂ',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Text(
            _editing
                ? 'ແກ້ໄຂເອກະສານແລ້ວສົ່ງອີກຄັ້ງ — ທີມງານຈະກວດສອບໃໝ່.'
                : 'ຢືນຢັນຕົວຕົນເພື່ອຮັບປ້າຍ "ຢືນຢັນແລ້ວ" ເທິງລາຍການຂອງທ່ານ — '
                      'ສ້າງຄວາມໜ້າເຊື່ອຖືໃຫ້ຜູ້ເຊົ່າ. ທີມງານຈະກວດສອບເອກະສານດ້ວຍຕົນເອງ.',
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          _FieldLabel('ບັດປະຈຳຕົວ / ໜັງສືຜ່ານແດນ'),
          const SizedBox(height: 8),
          _DocPicker(
            previewUrl: _idDocPreviewUrl,
            uploading: _uploadingField == 'id',
            label: 'ເພີ່ມຮູບບັດປະຈຳຕົວ',
            onTap: () => _pickDocument(field: 'id', folder: 'id_document'),
          ),
          const SizedBox(height: 18),
          _FieldLabel('ຮູບ Selfie ຖືບັດປະຈຳຕົວ'),
          const SizedBox(height: 8),
          _DocPicker(
            previewUrl: _selfiePreviewUrl,
            uploading: _uploadingField == 'selfie',
            label: 'ເພີ່ມຮູບ Selfie',
            onTap: () => _pickDocument(field: 'selfie', folder: 'selfie'),
          ),
          const SizedBox(height: 18),
          _FieldLabel('ເອກະສານກຳມະສິດຊັບສິນ (ບໍ່ບັງຄັບ)'),
          const SizedBox(height: 8),
          _DocPicker(
            previewUrl: _ownershipDocPreviewUrl,
            uploading: _uploadingField == 'ownership',
            label: 'ເພີ່ມເອກະສານກຳມະສິດ',
            onTap: () =>
                _pickDocument(field: 'ownership', folder: 'ownership'),
          ),
          const SizedBox(height: 18),
          _FieldLabel('ເບີໂທຕິດຕໍ່'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: TextStyle(fontSize: 13.5, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'ຕົວຢ່າງ: 020 5555 5555',
              hintStyle: TextStyle(
                fontSize: 13.5,
                color: AppColors.textSecondary,
              ),
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
            ),
          ),
          const SizedBox(height: 18),
          _FieldLabel('ອີເມວ'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  _emailConfirmed
                      ? Icons.check_circle_rounded
                      : Icons.error_outline_rounded,
                  size: 18,
                  color: _emailConfirmed
                      ? AppColors.primaryGreen
                      : const Color(0xFFD97706),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _emailConfirmed
                        ? '${Supabase.instance.client.auth.currentUser?.email ?? ''} — ຢືນຢັນແລ້ວ'
                        : '${Supabase.instance.client.auth.currentUser?.email ?? ''} — ຍັງບໍ່ໄດ້ຢືນຢັນ',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (!_emailConfirmed)
                  TextButton(
                    onPressed: _resendingEmail
                        ? null
                        : _resendEmailConfirmation,
                    child: _resendingEmail
                        ? SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primaryGreen,
                            ),
                          )
                        : Text(
                            'ສົ່ງອີກຄັ້ງ',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                  ),
              ],
            ),
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
                        : Text(
                            _editing ? 'ສົ່ງຄຳຮ້ອງອີກຄັ້ງ' : 'ສົ່ງຄຳຮ້ອງຢືນຢັນ',
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
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.verification,
    required this.onContactSupport,
    required this.onResubmit,
  });

  final OwnerVerification verification;
  final VoidCallback onContactSupport;
  final VoidCallback onResubmit;

  @override
  Widget build(BuildContext context) {
    final (icon, color, title, body) = switch (verification.status) {
      'approved' => (
        Icons.verified_rounded,
        AppColors.primaryGreen,
        'ຢືນຢັນຕົວຕົນແລ້ວ',
        'ລາຍການຂອງທ່ານຈະສະແດງປ້າຍ "ຢືນຢັນແລ້ວ" ໃຫ້ຜູ້ເຊົ່າເຫັນ.',
      ),
      'rejected' => (
        Icons.cancel_rounded,
        Colors.redAccent,
        'ຖືກປະຕິເສດ',
        'ຄຳຮ້ອງຂອງທ່ານຖືກປະຕິເສດ — ແກ້ໄຂເອກະສານແລ້ວສົ່ງໃໝ່ໄດ້ເລີຍ.',
      ),
      'more_docs_requested' => (
        Icons.description_rounded,
        const Color(0xFFD97706),
        'ຕ້ອງການເອກະສານເພີ່ມ',
        'ທີມງານຕ້ອງການເອກະສານເພີ່ມເຕີມ — ກະລຸນາອັບໂຫລດແລ້ວສົ່ງອີກຄັ້ງ.',
      ),
      _ => (
        Icons.hourglass_top_rounded,
        const Color(0xFFD97706),
        'ລໍຖ້າກວດສອບ',
        'ທີມງານກຳລັງກວດສອບເອກະສານຂອງທ່ານ, ໃຊ້ເວລາບໍ່ດົນ.',
      ),
    };
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(icon, size: 56, color: color),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          if (verification.status == 'rejected' &&
              verification.adminNotes != null &&
              verification.adminNotes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ເຫດຜົນຈາກທີມງານ',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.redAccent,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    verification.adminNotes!,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (verification.needsMoreDocs &&
              verification.adminNotes != null &&
              verification.adminNotes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFD97706).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ເອກະສານທີ່ຕ້ອງການເພີ່ມ',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFD97706),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    verification.adminNotes!,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(
                  label: 'ເບີໂທ',
                  value: verification.phoneNumber ?? '—',
                ),
                _InfoRow(
                  label: 'ສົ່ງເມື່ອ',
                  value:
                      '${verification.createdAt.day}/${verification.createdAt.month}/${verification.createdAt.year}',
                ),
              ],
            ),
          ),
          if (verification.canResubmit) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: Material(
                color: AppColors.primaryGreen,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: onResubmit,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Center(
                      child: Text(
                        'ແກ້ໄຂ ແລະ ສົ່ງໃໝ່',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onContactSupport,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryGreen,
                  side: BorderSide(color: AppColors.primaryGreen),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'ຕິດຕໍ່ທີມງານ',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
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

class _DocPicker extends StatelessWidget {
  const _DocPicker({
    required this.previewUrl,
    required this.uploading,
    required this.label,
    required this.onTap,
  });

  final String? previewUrl;
  final bool uploading;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: uploading ? null : onTap,
        child: Container(
          width: double.infinity,
          height: 140,
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.primaryGreen.withValues(alpha: 0.4),
              width: 1.4,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: uploading
              ? Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryGreen,
                  ),
                )
              : previewUrl != null
              ? Image.network(previewUrl!, fit: BoxFit.cover)
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo_rounded,
                      color: AppColors.primaryGreen,
                      size: 26,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label,
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
    );
  }
}
