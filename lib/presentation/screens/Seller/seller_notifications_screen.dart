import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../viewmodels/auth_service.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/language_viewmodel.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/success_dialog.dart';
import 'seller_questions_screen.dart';
import 'seller_reviews_screen.dart';
import '../../widgets/custom_bottom_sheets.dart';
import '../../../core/constants/app_icons.dart';
import '../../../presentation/widgets/svg_icon.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/custom_button.dart';

class SellerNotificationsScreen extends StatelessWidget {
  const SellerNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authVM = Provider.of<AuthViewModel>(context);
    final langVM = Provider.of<LanguageViewModel>(context);
    final user = authVM.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: Text(langVM.translate('notifications_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: langVM.translate('mark_all_read'),
            onPressed: () async {
              await AuthService.instance.markAllNotificationsAsRead(user.id);
            },
          ),
          IconButton(
            icon: const SvgIcon(
                iconPath: AppIcons.delete, size: 28, color: Colors.red),
            tooltip: 'Tümünü Sil',
            onPressed: () async {
              final confirm = await CustomBottomSheets.showConfirmation(
                context: context,
                title: 'Tümünü Sil',
                message: 'Tüm bildirimleri silmek istediğinize emin misiniz?',
                confirmText: langVM.translate('yes'),
                cancelText: langVM.translate('no'),
                iconPath: AppIcons.delete,
                confirmColor: Theme.of(context).colorScheme.error,
              );

              if (confirm == true) {
                await AuthService.instance.deleteAllNotifications(user.id);
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: AuthService.instance.getUserNotifications(user.id),
        builder: (_, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CustomLoadingIndicator());
          }

          final notifications = snapshot.data ?? [];
          final unreadNotifications =
              notifications.where((n) => n['read'] == false).toList();

          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TabBar(
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: Theme.of(context).colorScheme.primary,
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                      splashBorderRadius: BorderRadius.circular(30),
                      padding: const EdgeInsets.all(4),
                      tabs: [
                        Tab(text: 'Tümü (${notifications.length})'),
                        Tab(text: 'Okunmamış (${unreadNotifications.length})'),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildNotificationList(
                          context, notifications, langVM, user),
                      _buildNotificationList(
                          context, unreadNotifications, langVM, user,
                          emptyMessage: 'Okunmamış bildirim yok'),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationList(
    BuildContext context,
    List<Map<String, dynamic>> notifications,
    LanguageViewModel langVM,
    dynamic user, {
    String? emptyMessage,
  }) {
    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_outlined,
                size: 72, color: Colors.grey.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(emptyMessage ?? langVM.translate('no_notifications'),
                style: TextStyle(color: Colors.grey.withOpacity(0.8))),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
      itemCount: notifications.length,
      itemBuilder: (_, index) {
        final notification = notifications[index];
        final bool isRead = notification['read'] ?? false;
        final Timestamp? timestamp = notification['timestamp'];
        String timeText = '';

        if (timestamp != null) {
          final dt = timestamp.toDate();
          timeText =
              '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
        }

        // Satıcı için önemli bildirim renkleri
        Color notificationColor = Theme.of(context).colorScheme.primary;
        if (notification['metadata'] != null &&
            notification['metadata'] is Map &&
            (notification['metadata']['type'] == 'new_question' ||
                notification['metadata']['type'] == 'new_review')) {
          notificationColor = Theme.of(context).colorScheme.secondary;
        }

        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Dismissible(
          key: Key(notification['id']),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            return await CustomBottomSheets.showConfirmation(
              context: context,
              title: langVM.translate('delete_notification_title'),
              message: langVM.translate('delete_notification_confirm'),
              confirmText: langVM.translate('yes'),
              cancelText: langVM.translate('no'),
              iconPath: AppIcons.delete,
            );
          },
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            margin: const EdgeInsets.only(bottom: 16),
            color: Colors.red,
            child:
                const SvgIcon(iconPath: AppIcons.delete, color: Colors.white),
          ),
          onDismissed: (direction) {
            AuthService.instance
                .deleteNotification(user.id, notification['id']);
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: isRead
                  ? (isDark ? Theme.of(context).cardColor : Colors.white)
                  : notificationColor.withOpacity(isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isRead
                    ? (isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1))
                    : notificationColor.withOpacity(0.5),
                width: isRead ? 1 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isRead
                      ? Colors.black.withOpacity(0.04)
                      : notificationColor.withOpacity(0.1),
                  blurRadius: isRead ? 8 : 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () async {
                  if (!isRead) {
                    AuthService.instance
                        .markNotificationAsRead(user.id, notification['id']);
                  }
                  _showNotificationDetail(
                      context, notification, timeText, langVM);
                },
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                backgroundColor: isRead
                                    ? (isDark
                                        ? Colors.grey.withOpacity(0.2)
                                        : Colors.grey.withOpacity(0.1))
                                    : notificationColor,
                                child: Icon(
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
    Color iconColor = Theme.of(context).colorScheme.primary;
    final metadata = notification['metadata'];
    final type = metadata is Map ? metadata['type'] : null;

    String buttonText = 'Görüntüle';
    if (type == 'new_question') {
      buttonText = 'Soruyu Gör';
    } else if (type == 'new_review') {
      buttonText = 'Yorumu Gör';
    }

    if (type == 'new_question' || type == 'new_review') {
      iconColor = Theme.of(context).colorScheme.secondary;
    }

    CustomBottomSheets.showContent(
      context: context,
      title: notification['title'] ?? '',
      icon: Icons.notifications_active_outlined,
      iconColor: iconColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            timeText,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontSize: 12),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color:
                      Theme.of(context).colorScheme.primary.withOpacity(0.5)),
            ),
            child: Text(
              notification['body'] ?? '',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ),

          // İçerik Önizlemesi
          _buildContentPreview(context, notification['metadata']),

          const SizedBox(height: 24),

          // Hızlı Yanıt Butonu (Sadece Yeni Sorular İçin)
          if (type == 'new_question')
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CustomButton(
                text: 'Hızlı Yanıtla',
                icon: Icons.reply,
                backgroundColor: Colors.green,
                onPressed: () {
                  Navigator.pop(context);
                  _showQuickReplyDialog(context, metadata['questionId']);
                },
              ),
            ),

          // Detaya Git Butonu
          if (type == 'new_question' || type == 'new_review')
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.visibility),
                label: Text(buttonText),
                onPressed: () {
                  Navigator.pop(context);
                  _handleNavigation(context, notification);
                },
              ),
            ),

          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kapat'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showQuickReplyDialog(
      BuildContext context, String questionId) async {
    final controller = TextEditingController();
    final theme = Theme.of(context);
    final langVM = Provider.of<LanguageViewModel>(context, listen: false);

    await CustomBottomSheets.showContent(
      context: context,
      title: 'Hızlı Yanıt',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: langVM.translate('answer_hint'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: theme.colorScheme.primary.withOpacity(0.5)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: theme.colorScheme.primary.withOpacity(0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: theme.colorScheme.primary, width: 2),
              ),
              filled: true,
              fillColor: theme.cardColor,
              contentPadding: const EdgeInsets.all(16),
            ),
            maxLines: 4,
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: langVM.translate('send_button'),
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                final replyText = controller.text.trim();
                await AuthService.instance.replyToProductQuestion(
                  questionId,
                  replyText,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  await DialogService.showSuccess(
                    context,
                    message: langVM.translate('reply_sent_success'),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContentPreview(BuildContext context, dynamic metadata) {
    if (metadata == null || metadata is! Map) return const SizedBox.shrink();

    final type = metadata['type'];
    final questionId = metadata['questionId'];
    final reviewId = metadata['reviewId'];

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
              border: Border.all(
                  color:
                      Theme.of(context).colorScheme.primary.withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.help_outline,
                        size: 20, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('Soru Detayı',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary)),
                  ],
                ),
                const Divider(height: 12),
                Text(data['question'] ?? '',
                    style: const TextStyle(fontSize: 15)),
              ],
            ),
          );
        },
      );
    }

    if (type == 'new_review' && reviewId != null) {
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
              border: Border.all(
                  color:
                      Theme.of(context).colorScheme.primary.withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star_outline,
                        size: 20, color: Colors.amber),
                    const SizedBox(width: 8),
                    Text('Değerlendirme',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber[700])),
                  ],
                ),
                const Divider(height: 12),
                Row(
                  children: List.generate(
                      5,
                      (index) => Icon(
                            index < rating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 16,
                          )),
                ),
                const SizedBox(height: 4),
                Text(data['comment'] ?? '',
                    style: const TextStyle(fontSize: 15)),
              ],
            ),
          );
        },
      );
    }

    return const SizedBox.shrink();
  }

  void _handleNavigation(
      BuildContext context, Map<String, dynamic> notification) {
    if (notification['metadata'] == null) return;
    final metadata = notification['metadata'];
    final type = metadata is Map ? metadata['type'] : null;

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
    } else if (type == 'new_review') {
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
    }
  }
}
