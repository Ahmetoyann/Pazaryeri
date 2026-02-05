import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../viewmodels/auth_service.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/language_viewmodel.dart';
import '../../widgets/custom_app_bar.dart';
import 'product_detail_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authVM = Provider.of<AuthViewModel>(context);
    final langVM = Provider.of<LanguageViewModel>(context);
    final user = authVM.currentUser;

    if (user == null) {
      return Scaffold(
        appBar:
            CustomAppBar(title: Text(langVM.translate('notifications_title'))),
        body: Center(child: Text(langVM.translate('guest_message'))),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
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
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Tümünü Sil',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Tümünü Sil'),
                  content: const Text(
                      'Tüm bildirimleri silmek istediğinize emin misiniz?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(langVM.translate('no')),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(
                        langVM.translate('yes'),
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await AuthService.instance.deleteAllNotifications(user.id);
              }
            },
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.only(top: 100),
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: AuthService.instance.getUserNotifications(user.id),
          builder: (_, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
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

            final notifications = snapshot.data!;

            return ListView.builder(
              padding: const EdgeInsets.all(16),
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

                Color notificationColor = Theme.of(context).colorScheme.primary;
                if (notification['metadata'] != null &&
                    notification['metadata'] is Map &&
                    notification['metadata']['type'] == 'product_reply') {
                  notificationColor = Theme.of(context).colorScheme.secondary;
                }

                return Dismissible(
                  key: Key(notification['id']),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: Colors.red,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    AuthService.instance
                        .deleteNotification(user.id, notification['id']);
                  },
                  child: Card(
                    color: isRead
                        ? Theme.of(context).cardColor
                        : notificationColor.withOpacity(0.15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                          color: isRead
                              ? Colors.white.withOpacity(0.3)
                              : notificationColor.withOpacity(0.5)),
                    ),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isRead
                            ? Colors.grey.withOpacity(0.2)
                            : notificationColor,
                        child: Icon(
                          Icons.notifications,
                          color: isRead ? Colors.grey : Colors.white,
                        ),
                      ),
                      title: Text(
                        notification['title'] ?? '',
                        style: TextStyle(
                          fontWeight:
                              isRead ? FontWeight.normal : FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(notification['body'] ?? ''),
                          const SizedBox(height: 8),
                          Text(
                            timeText,
                            style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                      trailing: !isRead
                          ? Container(
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
                            )
                          : null,
                      onTap: () async {
                        if (!isRead) {
                          AuthService.instance.markNotificationAsRead(
                              user.id, notification['id']);
                        }
                        _showNotificationDetail(
                            context, notification, timeText, langVM);
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
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
    if (notification['metadata'] != null &&
        notification['metadata'] is Map &&
        notification['metadata']['type'] == 'product_reply') {
      iconColor = Theme.of(context).colorScheme.secondary;
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
                  const SizedBox(height: 32),
                  if (notification['metadata'] != null &&
                      notification['metadata']['type'] == 'product_reply')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.secondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.visibility),
                        label: const Text('Ürünü Görüntüle'),
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
                      child: const Text('Kapat'),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
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

  Future<void> _handleNavigation(
      BuildContext context, Map<String, dynamic> notification) async {
    if (notification['metadata'] == null) return;
    final metadata = notification['metadata'];

    if (metadata is Map &&
        metadata['type'] == 'product_reply' &&
        metadata['productId'] != null) {
      // Yükleniyor göstergesi
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
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
          String sellerName = 'Satıcı';
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

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductDetailScreen(
                  product: productData,
                  sellerName: sellerName,
                ),
              ),
            );
          }
        } else {
          if (context.mounted) {
            Navigator.of(context, rootNavigator: true).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ürün bulunamadı veya silinmiş.')),
            );
          }
        }
      } catch (e) {
        debugPrint('Yönlendirme hatası: $e');
        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bir hata oluştu.')),
          );
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
