class OwnerVerification {
  const OwnerVerification({
    required this.id,
    required this.userId,
    required this.status,
    this.idDocumentUrl,
    this.selfieUrl,
    this.ownershipDocumentUrl,
    this.phoneNumber,
    this.adminNotes,
    this.reviewedAt,
    required this.createdAt,
  });

  factory OwnerVerification.fromMap(Map<String, dynamic> map) {
    return OwnerVerification(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      status: map['status'] as String,
      idDocumentUrl: map['id_document_url'] as String?,
      selfieUrl: map['selfie_url'] as String?,
      ownershipDocumentUrl: map['ownership_document_url'] as String?,
      phoneNumber: map['phone_number'] as String?,
      adminNotes: map['admin_notes'] as String?,
      reviewedAt: map['reviewed_at'] != null
          ? DateTime.parse(map['reviewed_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  final String id;
  final String userId;

  /// 'pending' | 'approved' | 'rejected' | 'more_docs_requested'
  final String status;
  final String? idDocumentUrl;
  final String? selfieUrl;
  final String? ownershipDocumentUrl;
  final String? phoneNumber;
  final String? adminNotes;
  final DateTime? reviewedAt;
  final DateTime createdAt;

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get needsMoreDocs => status == 'more_docs_requested';

  /// Whether the owner can (re)submit right now — either they've never
  /// submitted, or their last submission was rejected / needs more docs.
  /// Not true while a submission is still pending review.
  bool get canResubmit => isRejected || needsMoreDocs;
}
