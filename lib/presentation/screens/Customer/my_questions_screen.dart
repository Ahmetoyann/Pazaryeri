import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/auth_service.dart';
import '../../viewmodels/language_viewmodel.dart';
import '../../widgets/custom_app_bar.dart';
import 'product_detail_screen.dart';

class MyQuestionsScreen extends StatefulWidget {
  const MyQuestionsScreen({super.key});

  @override
  State<MyQuestionsScreen> createState() => _MyQuestionsScreenState();
}

class _MyQuestionsScreenState extends State<MyQuestionsScreen> {
  Future<void> _deleteQuestion(String questionId) async {
    final langVM = Provider.of<LanguageViewModel>(context, listen: false);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(langVM.translate('delete_question_title')),
        content: Text(langVM.translate('delete_question_confirm')),
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
      await AuthService.instance.deleteProductQuestion(questionId);
      setState(() {});
    }
  }

  Future<void> _editQuestion(Map<String, dynamic> question) async {
    final langVM = Provider.of<LanguageViewModel>(context, listen: false);
    final questionController =
        TextEditingController(text: question['question']);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(langVM.translate('edit_question_title')),
        content: TextField(
          controller: questionController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(langVM.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              await AuthService.instance.updateProductQuestion(
                question['id'],
                questionController.text.trim(),
              );
              if (mounted) {
                Navigator.pop(context);
              }
            },
            child: Text(langVM.translate('update')),
          ),
        ],
      ),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final authVM = Provider.of<AuthViewModel>(context, listen: false);
    final langVM = Provider.of<LanguageViewModel>(context);
    final userId = authVM.currentUser?.id;

    return Scaffold(
      appBar: CustomAppBar(
        title: Text(langVM.translate('my_questions_title')),
      ),
      body: userId == null
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<Map<String, dynamic>>>(
              future: AuthService.instance.getUserProductQuestions(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                      child: Text(
                          '${langVM.translate('error_prefix')}: ${snapshot.error}'));
                }

                final questions = snapshot.data ?? [];

                if (questions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.help_outline,
                            size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          langVM.translate('no_questions_yet'),
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: questions.length,
                  itemBuilder: (context, index) {
                    final question = questions[index];
                    final date = question['date'] != null
                        ? DateTime.tryParse(question['date'].toString())
                        : null;
                    final formattedDate = date != null
                        ? DateFormat('dd MMM yyyy', langVM.currentLanguage)
                            .format(date)
                        : '';
                    final isAnswered = question['sellerReply'] != null &&
                        question['sellerReply'].toString().isNotEmpty;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          if (question['product'] != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProductDetailScreen(
                                  product: question['product'],
                                  sellerName:
                                      question['sellerName'] ?? 'Satıcı',
                                  highlightQuestionId: question['id'],
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Ürün artık mevcut değil.')),
                            );
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).cardColor,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: Colors.grey.withOpacity(0.2)),
                                      image:
                                          (question['productImage'] != null &&
                                                  question['productImage']
                                                      .toString()
                                                      .isNotEmpty)
                                              ? DecorationImage(
                                                  image: NetworkImage(
                                                      question['productImage']),
                                                  fit: BoxFit.cover,
                                                )
                                              : null,
                                    ),
                                    alignment: Alignment.center,
                                    child: (question['productImage'] == null ||
                                            question['productImage']
                                                .toString()
                                                .isEmpty)
                                        ? Icon(Icons.shopping_bag_outlined,
                                            color: Colors.grey.shade400)
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          question['productName'] ?? 'Ürün',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (question['sellerName'] != null) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            question['sellerName'],
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Text(
                                              formattedDate,
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade600),
                                            ),
                                            if (question['isEdited'] ==
                                                true) ...[
                                              const SizedBox(width: 4),
                                              Text(
                                                '(${langVM.translate('edited')})',
                                                style: TextStyle(
                                                    fontSize: 10,
                                                    fontStyle: FontStyle.italic,
                                                    color:
                                                        Colors.grey.shade400),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.edit,
                                      size: 20,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                    onPressed: () => _editQuestion(question),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete_outline,
                                      size: 20,
                                      color:
                                          Theme.of(context).colorScheme.error,
                                    ),
                                    onPressed: () =>
                                        _deleteQuestion(question['id']),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              Text(
                                question['question'] ?? '',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                              if (isAnswered) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.store,
                                            size: 16,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            langVM.translate(
                                                'seller_reply_label'),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        question['sellerReply'],
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.access_time,
                                        size: 14,
                                        color: Colors.orange.shade300),
                                    const SizedBox(width: 4),
                                    Text(
                                      langVM.translate('filter_unanswered'),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange.shade300,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
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
