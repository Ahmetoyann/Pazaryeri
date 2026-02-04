import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../viewmodels/auth_service.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/language_viewmodel.dart';
import '../../widgets/custom_app_bar.dart';

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
        ],
      ),
      body: Container(
        padding: const EdgeInsets.only(top: 100),
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: AuthService.instance.getUserNotifications(user.id),
          builder: (context, snapshot) {
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
              itemBuilder: (context, index) {
                final notification = notifications[index];
                final bool isRead = notification['read'] ?? false;
                final Timestamp? timestamp = notification['timestamp'];
                String timeText = '';

                if (timestamp != null) {
                  final dt = timestamp.toDate();
                  timeText =
                      '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
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
                        : Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.white.withOpacity(0.3)),
                    ),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isRead
                            ? Colors.grey.withOpacity(0.2)
                            : Theme.of(context).colorScheme.primary,
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
                      onTap: () {
                        if (!isRead) {
                          AuthService.instance.markNotificationAsRead(
                              user.id, notification['id']);
                        }
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
}
