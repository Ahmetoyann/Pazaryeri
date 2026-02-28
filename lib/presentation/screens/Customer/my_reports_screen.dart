import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/auth_service.dart';
import '../../viewmodels/language_viewmodel.dart';
import '../../widgets/custom_app_bar.dart';

class MyReportsScreen extends StatelessWidget {
  const MyReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final langVM = context.watch<LanguageViewModel>();
    final userId = authVM.currentUser?.id;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(title: Text(langVM.translate('report_history'))),
      body: userId == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('reports')
                  .where('reporterId', isEqualTo: userId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Hata: ${snapshot.error}'));
                }

                final docs = snapshot.data?.docs.toList() ?? [];

                // İndeks hatasını önlemek için sıralamayı burada (istemci tarafında) yapıyoruz
                docs.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  final tA = aData['timestamp'] as Timestamp?;
                  final tB = bData['timestamp'] as Timestamp?;
                  if (tA == null) return 1;
                  if (tB == null) return -1;
                  return tB.compareTo(tA); // Yeniden eskiye
                });

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history,
                            size: 80, color: Colors.grey.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        Text(
                          langVM.translate('no_reports_yet'),
                          style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6)),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 110, 16, 16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final report = docs[index].data() as Map<String, dynamic>;
                    final date = report['timestamp'] != null
                        ? (report['timestamp'] as Timestamp).toDate()
                        : DateTime.now();
                    final formattedDate =
                        DateFormat('dd MMM yyyy HH:mm').format(date);

                    String statusKey =
                        'report_status_${report['status'] ?? 'pending'}';
                    String statusText = langVM.translate(statusKey);

                    Color statusColor = Colors.orange;
                    if (report['status'] == 'resolved') {
                      statusColor = Colors.green;
                    } else if (report['status'] == 'reviewed') {
                      statusColor = Colors.blue;
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Chip(
                                  label: Text(
                                    report['type'] == 'seller'
                                        ? langVM.translate('seller_label')
                                        : langVM.translate('all_markets'),
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.white),
                                  ),
                                  backgroundColor: report['type'] == 'seller'
                                      ? Colors.orange
                                      : Colors.blue,
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: statusColor.withOpacity(0.5)),
                                  ),
                                  child: Text(
                                    statusText,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${report['reportedName']}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              report['reason'] ?? '',
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.8)),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              formattedDate,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
