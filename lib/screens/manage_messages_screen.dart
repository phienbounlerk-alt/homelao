import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../data/conversation_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/error_state.dart';
import 'messages_screen.dart';

const _defaultAvatarUrl =
    'https://images.unsplash.com/photo-1633332755192-727a05c4013d?w=100&q=80';

/// Owner-side inbox: conversations renters have started about the current
/// owner's listings. Opens the same [ChatDetailScreen] used on the renter
/// side — its bubbles are already sender_id-aware, so either party sees
/// their own messages on the right regardless of who started the thread.
class ManageMessagesScreen extends StatefulWidget {
  const ManageMessagesScreen({super.key});

  @override
  State<ManageMessagesScreen> createState() => _ManageMessagesScreenState();
}

class _ManageMessagesScreenState extends State<ManageMessagesScreen> {
  List<Map<String, dynamic>> _conversations = [];
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final rows = await ConversationRepository.fetchOwnerConversations();
      if (!mounted) return;
      setState(() {
        _conversations = rows;
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
                    'ຂໍ້ຄວາມຈາກຜູ້ເຊົ່າ',
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
              child: _loading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryGreen,
                      ),
                    )
                  : _error
                  ? ErrorState(onRetry: _load)
                  : _conversations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 48,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'ຍັງບໍ່ມີຂໍ້ຄວາມ',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _conversations.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        indent: 76,
                        color: AppColors.cardBorder,
                      ),
                      itemBuilder: (context, i) {
                        final c = _conversations[i];
                        final propertyTitle = c['property_title'] as String?;
                        final propertyImageUrl =
                            c['property_image_url'] as String?;
                        final propertyPriceLak =
                            c['property_price_lak'] as int?;
                        final lastMessage =
                            c['latest_message_text'] as String? ??
                            'ເລີ່ມການສົນທະນາ';
                        final avatarUrl =
                            c['renter_avatar_url'] as String? ??
                            _defaultAvatarUrl;
                        final rawName = c['renter_name'] as String?;
                        final name = rawName?.isNotEmpty == true
                            ? rawName!
                            : 'ຜູ້ໃຊ້';

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.of(context)
                                  .push(
                                    MaterialPageRoute(
                                      builder: (_) => ChatDetailScreen(
                                        conversationId: c['id'] as String,
                                        name: name,
                                        avatarUrl: avatarUrl,
                                        propertyTitle: propertyTitle,
                                        propertyImageUrl: propertyImageUrl,
                                        propertyPriceLak: propertyPriceLak,
                                      ),
                                    ),
                                  )
                                  .then((_) => _load());
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 26,
                                    backgroundImage: NetworkImage(avatarUrl),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        if (propertyTitle != null) ...[
                                          const SizedBox(height: 3),
                                          Row(
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                child: Image.network(
                                                  propertyImageUrl ?? '',
                                                  width: 16,
                                                  height: 16,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  propertyTitle,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        AppColors.primaryGreen,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                        const SizedBox(height: 4),
                                        Text(
                                          lastMessage,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
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
          ],
        ),
      ),
    );
  }
}
