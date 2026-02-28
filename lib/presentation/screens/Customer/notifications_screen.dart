import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../viewmodels/auth_service.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/language_viewmodel.dart';
import '../../widgets/custom_app_bar.dart';
import 'product_detail_screen.dart';
import '../Seller/seller_questions_screen.dart';
import '../Seller/seller_reviews_screen.dart';
import '../../widgets/custom_bottom_sheets.dart';
import '../../widgets/custom_snackbars.dart';
import '../../../core/constants/app_icons.dart';
import '../../../presentation/widgets/svg_icon.dart';
import '../../widgets/loading_overlay.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _filterType = 'all'; // 'all', 'read', 'unread'

  // Seçim Modu Değişkenleri
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _startSelection(String id) {
    setState(() {
      _isSelectionMode = true;
      _selectedIds.add(id);
    });
  }

  void _cancelSelection() {
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
  }

  Future<void> _deleteSelected(String userId, LanguageViewModel langVM) async {
    final confirm = await CustomBottomSheets.showConfirmation(
      context: context,
      title: langVM.translate('delete_selected_title'),
      message:
          '${_selectedIds.length} ${langVM.translate('delete_selected_confirm_suffix')}',
      confirmText: langVM.translate('yes'),
      cancelText: langVM.translate('no'),
      iconPath: AppIcons.delete,
    );

    if (confirm == true) {
      for (var id in _selectedIds) {
        AuthService.instance.deleteNotification(userId, id);
      }
      _cancelSelection();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVM = Provider.of<AuthViewModel>(context);
    final langVM = Provider.of<LanguageViewModel>(context);
    final user = authVM.currentUser;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (user == null) {
      return Scaffold(
        appBar:
            CustomAppBar(title: Text(langVM.translate('notifications_title'))),
        body: Center(child: Text(langVM.translate('guest_message'))),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: CustomAppBar(
          leading: _isSelectionMode
              ? Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.2)
                          : Colors.black.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.close, color: theme.iconTheme.color),
                      onPressed: _cancelSelection,
                    ),
                  ),
                )
              : null,
          title: _isSelectionMode
              ? Text(
                  '${_selectedIds.length} ${langVM.translate('selected_count_suffix')}')
              : Text(langVM.translate('notifications_title')),
          bottom: TabBar(
            indicatorColor: theme.colorScheme.primary,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
            tabs: [
              Tab(text: langVM.translate('seller_notifications_tab')),
              Tab(text: langVM.translate('marketplace_notifications_tab')),
            ],
          ),
          actions: _isSelectionMode
              ? [
                  Container(
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const SvgIcon(
                          iconPath: AppIcons.delete, color: Colors.red),
                      tooltip: langVM.translate('delete_selected_title'),
                      onPressed: () => _deleteSelected(user.id, langVM),
                    ),
                  ),
                ]
              : [
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: PopupMenuButton<String>(
                      icon: Icon(Icons.filter_list,
                          color: theme.colorScheme.primary),
                      tooltip: 'Filtrele',
                      onSelected: (value) {
                        setState(() {
                          _filterType = value;
                        });
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'all',
                          child: Text(langVM.translate('filter_all')),
                        ),
                        PopupMenuItem(
                          value: 'unread',
                          child: Text(langVM.translate('filter_unread')),
                        ),
                        PopupMenuItem(
                          value: 'read',
                          child: Text(langVM.translate('filter_read')),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.done_all,
                          color: theme.colorScheme.primary),
                      tooltip: langVM.translate('mark_all_read'),
                      onPressed: () async {
                        await AuthService.instance
                            .markAllNotificationsAsRead(user.id);
                      },
                    ),
                  ),
                ],
        ),
        body: Container(
          padding: const EdgeInsets.only(top: 150),
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: AuthService.instance.getUserNotifications(user.id),
            builder: (_, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CustomLoadingIndicator());
              }

              final notifications = snapshot.data ?? [];

              // Filtreleme
              List<Map<String, dynamic>> filteredList = notifications;
              if (_filterType == 'unread') {
                filteredList =
                    notifications.where((n) => n['read'] == false).toList();
              } else if (_filterType == 'read') {
                filteredList =
                    notifications.where((n) => n['read'] == true).toList();
              }

              // Bildirimleri filtrele
              final sellerNotifications =
                  filteredList.where((n) => _isSellerNotification(n)).toList();
              final marketNotifications =
                  filteredList.where((n) => !_isSellerNotification(n)).toList();

              return TabBarView(
                children: [
                  _buildNotificationList(
                      context, sellerNotifications, user.id, langVM),
                  _buildNotificationList(
                      context, marketNotifications, user.id, langVM),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  bool _isSellerNotification(Map<String, dynamic> n) {
    if (n['metadata'] != null && n['metadata'] is Map) {
      final type = n['metadata']['type'];
      return [
        'question_reply',
        'review_reply',
        'new_question',
        'new_review',
        'new_seller_review',
        'product_reply'
      ].contains(type);
    }
    return false;
  }

  Widget _buildNotificationList(
      BuildContext context,
      List<Map<String, dynamic>> notifications,
      String userId,
      LanguageViewModel langVM) {
    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_outlined,
                size: 64, color: Colors.grey.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(langVM.translate('no_notifications'),
                style: TextStyle(color: Colors.grey.withOpacity(0.8))),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notifications.length,
      itemBuilder: (_, index) {
        final notification = notifications[index];
        final id = notification['id'];
        final isSelected = _selectedIds.contains(id);
        final bool isRead = notification['read'] ?? false;
        final Timestamp? timestamp = notification['timestamp'];
        String timeText = '';

        if (timestamp != null) {
          final dt = timestamp.toDate();
          timeText =
              '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
        }

        Color notificationColor = Theme.of(context).colorScheme.primary;
        if (_isSellerNotification(notification)) {
          notificationColor = Theme.of(context).colorScheme.secondary;
        }

        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Dismissible(
          key: Key(id),
          direction: _isSelectionMode
              ? DismissDirection.none
              : DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(16),
            ),
            child:
                const SvgIcon(iconPath: AppIcons.delete, color: Colors.white),
          ),
          onDismissed: (direction) {
            AuthService.instance.deleteNotification(userId, id);
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                  : (isRead
                      ? (isDark ? Theme.of(context).cardColor : Colors.white)
                      : notificationColor.withOpacity(isDark ? 0.15 : 0.05)),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : (isRead
                        ? (isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1))
                        : notificationColor.withOpacity(0.3)),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () async {
                  if (_isSelectionMode) {
                    _toggleSelection(id);
                  } else {
                    if (!isRead) {
                      AuthService.instance.markNotificationAsRead(userId, id);
                    }
                    _showNotificationDetail(
                        context, notification, timeText, langVM);
                  }
                },
                onLongPress: () {
                  if (!_isSelectionMode) {
                    _startSelection(id);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundColor: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : (isRead
                                ? (isDark
                                    ? Colors.grey.withOpacity(0.2)
                                    : Colors.grey.withOpacity(0.1))
                                : notificationColor),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white)
                            : Icon(
                                Icons.notifications,
                                color: isRead
                                    ? (isDark
                                        ? Colors.grey
                                        : Colors.grey.shade600)
                                    : Colors.white,
                              ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notification['title'] ?? '',
                              style: TextStyle(
                                fontWeight: isRead
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notification['body'] ?? '',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color
                                    ?.withOpacity(0.8),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              timeText,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isRead)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0, top: 8.0),
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: notificationColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: notificationColor.withOpacity(0.4),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showNotificationDetail(
    BuildContext context,
    Map<String, dynamic> notification,
    String timeText,
    LanguageViewModel langVM,
  ) {
    String displayTime = timeText;
    if (notification['timestamp'] != null) {
      final Timestamp timestamp = notification['timestamp'];
      displayTime =
          _formatRelativeTime(timestamp.toDate(), langVM.currentLanguage);
    }

    Color iconColor = Theme.of(context).colorScheme.primary;
    final metadata = notification['metadata'];
    final type = metadata is Map ? metadata['type'] : null;

    // Buton metnini belirle
    String buttonText = langVM.translate('view_product_button');
    if (type == 'new_question') {
      buttonText = langVM.translate('view_question_button');
    } else if (type == 'new_review') {
      buttonText = langVM.translate('view_review_button');
    } else if (type == 'question_reply' || type == 'review_reply') {
      buttonText = langVM.translate('view_reply_button');
    } else if (type == 'review_like') {
      buttonText = langVM.translate('view_review_button');
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1E1E1E)
              : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        margin: const EdgeInsets.all(12),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.notifications_active_outlined,
                      size: 32,
                      color: iconColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    notification['title'] ?? '',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? null
                              : Colors.black,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.access_time,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        displayTime,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Theme.of(context).cardColor
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.1)),
                    ),
                    child: Text(
                      notification['body'] ?? '',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? null
                                    : Colors.black,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // İçerik Önizlemesi (Soru veya Yorum)
                  _buildContentPreview(context, notification['metadata']),
                  const SizedBox(height: 32),
                  if (type == 'product_reply' ||
                      type == 'new_review' ||
                      type == 'new_question' ||
                      type == 'question_reply' ||
                      type == 'review_reply' ||
                      type == 'review_like')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.visibility),
                        label: Text(buttonText),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _handleNavigation(context, notification);
                        },
                      ),
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(langVM.translate('close_button')),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon:
                    const SvgIcon(iconPath: AppIcons.delete, color: Colors.red),
                onPressed: () async {
                  final authVM =
                      Provider.of<AuthViewModel>(context, listen: false);
                  if (authVM.currentUser != null) {
                    await AuthService.instance.deleteNotification(
                        authVM.currentUser!.id, notification['id']);
                    if (ctx.mounted) Navigator.pop(ctx);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentPreview(BuildContext context, dynamic metadata) {
    if (metadata == null || metadata is! Map) return const SizedBox.shrink();

    final type = metadata['type'];
    final questionId = metadata['questionId'];
    final reviewId = metadata['reviewId'];
    final langVM = Provider.of<LanguageViewModel>(context, listen: false);

    // Satıcı için: Yeni Soru Detayı
    if (type == 'new_question' && questionId != null) {
      return FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('product_questions')
            .doc(questionId)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const SizedBox.shrink();
          }
          final data = snapshot.data!.data() as Map<String, dynamic>;
          return Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.help_outline,
                        size: 20, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(langVM.translate('question_detail_title'),
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary)),
                  ],
                ),
                const Divider(height: 24),
                Text(data['question'] ?? '',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    )),
              ],
            ),
          );
        },
      );
    }

    // Satıcı veya Kullanıcı için: Değerlendirme Detayı
    if ((type == 'new_review' || type == 'review_like') && reviewId != null) {
      return FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('product_reviews')
            .doc(reviewId)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const SizedBox.shrink();
          }
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final rating = (data['rating'] as num?)?.toDouble() ?? 0.0;

          return Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star_outline,
                        size: 20, color: Colors.amber),
                    const SizedBox(width: 8),
                    Text(langVM.translate('review_detail_title'),
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber[700])),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: List.generate(
                      5,
                      (index) => Icon(
                            index < rating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 16,
                          )),
                ),
                const SizedBox(height: 8),
                Text(data['comment'] ?? '',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    )),
              ],
            ),
          );
        },
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _handleNavigation(
      BuildContext context, Map<String, dynamic> notification) async {
    if (notification['metadata'] == null) return;
    final metadata = notification['metadata'];
    final type = metadata is Map ? metadata['type'] : null;
    final langVM = Provider.of<LanguageViewModel>(context, listen: false);

    // Satıcı için yeni soru bildirimi ise Sorular sayfasına yönlendir
    if (type == 'new_question') {
      final langVM = Provider.of<LanguageViewModel>(context, listen: false);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar:
                CustomAppBar(title: Text(langVM.translate('questions_title'))),
            body: SellerQuestionsScreen(
              highlightQuestionId: metadata['questionId'],
            ),
          ),
        ),
      );
      return;
    }

    // Satıcı için yeni yorum bildirimi ise Değerlendirmeler sayfasına yönlendir
    if (type == 'new_review') {
      final langVM = Provider.of<LanguageViewModel>(context, listen: false);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar:
                CustomAppBar(title: Text(langVM.translate('reviews_title'))),
            body: SellerReviewsScreen(
              highlightReviewId: metadata['reviewId'],
            ),
          ),
        ),
      );
      return;
    }

    // Müşteri için soru/yorum yanıtı veya genel ürün bildirimi
    if (metadata is Map && metadata['productId'] != null) {
      // Yükleniyor göstergesi
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CustomLoadingIndicator()),
      );

      try {
        // Ürün verisini çek
        final doc = await FirebaseFirestore.instance
            .collection('products')
            .doc(metadata['productId'])
            .get();

        if (doc.exists) {
          final productData = doc.data()!;
          productData['id'] = doc.id;

          // Satıcı ismini çek (ProductDetailScreen için gerekli)
          String sellerName = langVM.translate('seller_default_name');
          if (productData['sellerId'] != null) {
            final sellerDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(productData['sellerId'])
                .get();
            if (sellerDoc.exists) {
              final sData = sellerDoc.data()!;
              sellerName = sData['stallName'] ??
                  '${sData['firstName']} ${sData['lastName']}';
            }
          }

          if (context.mounted) {
            // Loading dialogunu kapat
            Navigator.of(context, rootNavigator: true).pop();

            // Highlight ID'lerini belirle
            String? highlightQuestionId;
            String? highlightReviewId;

            if (type == 'question_reply') {
              highlightQuestionId = metadata['questionId'];
            } else if (type == 'review_reply') {
              highlightReviewId = metadata['reviewId'];
            } else if (type == 'review_like') {
              highlightReviewId = metadata['reviewId'];
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductDetailScreen(
                  product: productData,
                  sellerName: sellerName,
                  highlightQuestionId:
                      highlightQuestionId ?? metadata['questionId'],
                  highlightReviewId: highlightReviewId ?? metadata['reviewId'],
                ),
              ),
            );
          }
        } else {
          if (context.mounted) {
            Navigator.of(context, rootNavigator: true).pop();
            CustomSnackbars.showError(
                context, langVM.translate('product_not_found_error'));
          }
        }
      } catch (e) {
        debugPrint('Yönlendirme hatası: $e');
        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).pop();
          CustomSnackbars.showError(context, langVM.translate('generic_error'));
        }
      }
    }
  }

  String _formatRelativeTime(DateTime date, String languageCode) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (languageCode == 'en') {
      if (difference.inDays > 7) {
        return '${date.day}/${date.month}/${date.year}';
      } else if (difference.inDays >= 1) {
        return '${difference.inDays} days ago';
      } else if (difference.inHours >= 1) {
        return '${difference.inHours} hours ago';
      } else if (difference.inMinutes >= 1) {
        return '${difference.inMinutes} minutes ago';
      } else {
        return 'Just now';
      }
    } else {
      if (difference.inDays > 7) {
        return '${date.day}/${date.month}/${date.year}';
      } else if (difference.inDays >= 1) {
        return '${difference.inDays} gün önce';
      } else if (difference.inHours >= 1) {
        return '${difference.inHours} saat önce';
      } else if (difference.inMinutes >= 1) {
        return '${difference.inMinutes} dakika önce';
      } else {
        return 'Az önce';
      }
    }
  }
}
