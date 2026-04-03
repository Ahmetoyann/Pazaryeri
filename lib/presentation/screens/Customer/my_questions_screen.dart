import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/auth_service.dart';
import '../../viewmodels/language_viewmodel.dart';
import '../../widgets/custom_app_bar.dart';
import 'product_detail_screen.dart';
import '../../widgets/custom_bottom_sheets.dart';
import '../../widgets/custom_snackbars.dart';
import '../../../core/constants/app_icons.dart';
import '../../widgets/svg_icon.dart';
import '../../widgets/loading_overlay.dart';

class MyQuestionsScreen extends StatefulWidget {
  final String? highlightQuestionId;
  const MyQuestionsScreen({super.key, this.highlightQuestionId});

  @override
  State<MyQuestionsScreen> createState() => _MyQuestionsScreenState();
}

class _MyQuestionsScreenState extends State<MyQuestionsScreen> {
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _questions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final authVM = Provider.of<AuthViewModel>(context, listen: false);
    final userId = authVM.currentUser?.id;

    if (userId != null) {
      final questions =
          await AuthService.instance.getUserProductQuestions(userId);

      // Bildirimden gelindiyse ilgili soruyu en başa taşı
      if (widget.highlightQuestionId != null && questions.isNotEmpty) {
        final index =
            questions.indexWhere((q) => q['id'] == widget.highlightQuestionId);
        if (index != -1) {
          final item = questions.removeAt(index);
          questions.insert(0, item);
        }
      }

      if (mounted) {
        setState(() {
          _questions = questions;
          _isLoading = false;
        });

        // Listeyi en başa kaydır (Görünürlüğü garanti et)
        if (widget.highlightQuestionId != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.jumpTo(0);
            }
          });
        }
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteQuestion(String questionId) async {
    final langVM = Provider.of<LanguageViewModel>(context, listen: false);
    final confirm = await CustomBottomSheets.showConfirmation(
      context: context,
      title: langVM.translate('delete_question_title'),
      message: langVM.translate('delete_question_confirm'),
      confirmText: langVM.translate('yes'),
      cancelText: langVM.translate('no'),
      iconPath: AppIcons.delete,
    );

    if (confirm == true) {
      await AuthService.instance.deleteProductQuestion(questionId);
      // Listeden yerel olarak sil (Tekrar yüklemeye gerek yok)
      setState(() {
        _questions.removeWhere((q) => q['id'] == questionId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final langVM = Provider.of<LanguageViewModel>(context);

    return Scaffold(
        appBar: CustomAppBar(
          title: Text(langVM.translate('my_questions_title')),
        ),
        body: _isLoading
            ? const Center(child: CustomLoadingIndicator())
            : _questions.isEmpty
                ? Center(
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
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _questions.length,
                    itemBuilder: (context, index) {
                      final question = _questions[index];
                      final date = question['date'] != null
                          ? DateTime.tryParse(question['date'].toString())
                          : null;
                      final formattedDate = date != null
                          ? DateFormat('dd MMM yyyy', langVM.currentLanguage)
                              .format(date)
                          : '';
                      final isAnswered = question['sellerReply'] != null &&
                          question['sellerReply'].toString().isNotEmpty;

                      final isDark =
                          Theme.of(context).brightness == Brightness.dark;
                      final isHighlighted =
                          question['id'] == widget.highlightQuestionId;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: isHighlighted
                              ? (isDark
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.15)
                                  : Colors.orange.shade50)
                              : (isDark
                                  ? Theme.of(context).cardColor
                                  : Colors.white),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isHighlighted
                                ? Theme.of(context).colorScheme.primary
                                : (isDark
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.grey.withOpacity(0.1)),
                            width: isHighlighted ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
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
                                CustomSnackbars.showWarning(
                                  context,
                                  'Ürün artık mevcut değil.',
                                );
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).cardColor,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color:
                                                  Colors.grey.withOpacity(0.2)),
                                          image: (question['productImage'] !=
                                                      null &&
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
                                        child: (question['productImage'] ==
                                                    null ||
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
                                            if (question['sellerName'] !=
                                                null) ...[
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
                                                      color:
                                                          Colors.grey.shade600),
                                                ),
                                                if (question['isEdited'] ==
                                                    true) ...[
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '(${langVM.translate('edited')})',
                                                    style: TextStyle(
                                                        fontSize: 10,
                                                        fontStyle:
                                                            FontStyle.italic,
                                                        color: Colors
                                                            .grey.shade400),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: SvgIcon(
                                          iconPath: AppIcons.delete,
                                          size: 20,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .error,
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
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500),
                                  ),
                                  if (isAnswered) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.white.withOpacity(0.05)
                                            : Colors.grey.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Theme.of(context)
                                              .dividerColor
                                              .withOpacity(0.1),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.people,
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
                                            style:
                                                const TextStyle(fontSize: 14),
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
                        ),
                      );
                    },
                  ));
  }
}
