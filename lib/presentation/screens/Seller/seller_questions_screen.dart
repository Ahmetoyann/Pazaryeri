import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/auth_service.dart';
import '../../viewmodels/language_viewmodel.dart';
import '../../widgets/success_dialog.dart';
import 'seller_product_management_screen.dart';
import '../../viewmodels/seller_viewmodel.dart';

class SellerQuestionsScreen extends StatefulWidget {
  final String? highlightQuestionId;
  const SellerQuestionsScreen({super.key, this.highlightQuestionId});

  @override
  State<SellerQuestionsScreen> createState() => _SellerQuestionsScreenState();
}

class _SellerQuestionsScreenState extends State<SellerQuestionsScreen> {
  List<Map<String, dynamic>> _allQuestions = [];
  List<Map<String, dynamic>> _filteredQuestions = [];
  bool _isLoading = true;
  String _filterType = 'unanswered'; // 'all', 'unanswered'
  final Map<String, GlobalKey> _itemKeys = {};

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final sellerId = context.read<AuthViewModel>().currentUser?.id;
    if (sellerId != null) {
      final questions = await AuthService.instance.getSellerQuestions(sellerId);
      if (mounted) {
        setState(() {
          _allQuestions = questions;
          _applyFilter();
          _isLoading = false;
        });

        if (widget.highlightQuestionId != null) {
          // Eğer vurgulanan soru mevcut filtrede yoksa (örn: yanıtlanmışsa), filtreyi 'all' yap
          final existsInFilter = _filteredQuestions
              .any((q) => q['id'] == widget.highlightQuestionId);
          if (!existsInFilter) {
            setState(() {
              _filterType = 'all';
              _applyFilter();
            });
          }

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToHighlightedItem();
          });
        }
      }
    }
  }

  void _scrollToHighlightedItem() {
    final id = widget.highlightQuestionId;
    if (id == null) return;

    Future.delayed(const Duration(milliseconds: 500), () {
      final key = _itemKeys[id];
      if (key?.currentContext != null) {
        Scrollable.ensureVisible(
          key!.currentContext!,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
          alignment: 0.5,
        );
      }
    });
  }

  void _applyFilter() {
    if (_filterType == 'unanswered') {
      _filteredQuestions = _allQuestions.where((q) {
        final reply = q['sellerReply'];
        return reply == null || reply.toString().isEmpty;
      }).toList();
    } else {
      _filteredQuestions = List.from(_allQuestions);
    }
  }

  void _onFilterChanged(String? newValue) {
    if (newValue != null) {
      setState(() {
        _filterType = newValue;
        _applyFilter();
      });
    }
  }

  Future<void> _replyToQuestion(String questionId, String currentReply) async {
    final langVM = Provider.of<LanguageViewModel>(context, listen: false);
    final controller = TextEditingController(text: currentReply);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1E1E1E)
              : Colors.black,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 24,
          right: 24,
          top: 12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              langVM.translate('reply_button'),
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: langVM.translate('answer_hint'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.05),
                contentPadding: const EdgeInsets.all(16),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  if (controller.text.trim().isNotEmpty) {
                    final replyText = controller.text.trim();
                    await AuthService.instance.replyToProductQuestion(
                      questionId,
                      replyText,
                    );
                    if (mounted) {
                      Navigator.pop(context);

                      // Anlık güncelleme: Yerel listeyi güncelle ve filtreyi uygula
                      setState(() {
                        final index = _allQuestions
                            .indexWhere((q) => q['id'] == questionId);
                        if (index != -1) {
                          _allQuestions[index]['sellerReply'] = replyText;
                          _applyFilter();
                        }
                      });

                      await DialogService.showSuccess(
                        context,
                        message: langVM.translate('reply_sent_success'),
                        duration: const Duration(seconds: 3),
                      );
                      _loadQuestions(); // Listeyi güncelle
                    }
                  }
                },
                child: Text(langVM.translate('send_button')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final langVM = context.watch<LanguageViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? Colors.white : Theme.of(context).colorScheme.primary;
    final contentColor = isDark ? Colors.black : Colors.white;

    return Column(
      children: [
        // Filtreleme Alanı
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _filterType,
                isExpanded: true,
                dropdownColor: backgroundColor,
                icon: Icon(Icons.filter_list, color: contentColor),
                style: TextStyle(color: contentColor, fontSize: 16),
                items: [
                  DropdownMenuItem(
                    value: 'all',
                    child: Text(
                      langVM.translate('filter_all'),
                      style: TextStyle(color: contentColor),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'unanswered',
                    child: Text(
                      langVM.translate('filter_unanswered'),
                      style: TextStyle(color: contentColor),
                    ),
                  ),
                ],
                onChanged: _onFilterChanged,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredQuestions.isEmpty
                  ? Center(
                      child: Text(langVM.translate('no_results')),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredQuestions.length,
                      itemBuilder: (context, index) {
                        final question = _filteredQuestions[index];
                        final date = question['date'] != null
                            ? DateTime.tryParse(question['date'].toString())
                            : null;
                        final formattedDate = date != null
                            ? DateFormat('dd MMM yyyy', langVM.currentLanguage)
                                .format(date)
                            : '';
                        final reply = question['sellerReply'];
                        final hasReply =
                            reply != null && reply.toString().isNotEmpty;
                        final isHighlighted =
                            widget.highlightQuestionId == question['id'];
                        final productImage = question['productImage'];

                        if (!_itemKeys.containsKey(question['id'])) {
                          _itemKeys[question['id']] = GlobalKey();
                        }

                        return Card(
                          key: _itemKeys[question['id']],
                          margin: const EdgeInsets.only(bottom: 16),
                          color: isHighlighted
                              ? Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.1)
                              : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: isHighlighted
                                ? BorderSide(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    width: 2)
                                : BorderSide(
                                    color: Colors.white.withOpacity(0.3)),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              if (question['productData'] != null) {
                                try {
                                  final product = SellerProduct.fromMap(
                                      question['productData']);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          SellerProductManagementScreen(
                                              product: product),
                                    ),
                                  );
                                } catch (e) {
                                  debugPrint('Ürün detayları açılamadı: $e');
                                }
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
                                      if (productImage != null &&
                                          productImage.toString().isNotEmpty)
                                        Container(
                                          width: 50,
                                          height: 50,
                                          margin:
                                              const EdgeInsets.only(right: 12),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            color: Colors.grey.withOpacity(0.2),
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: productImage
                                                    .startsWith('http')
                                                ? Image.network(
                                                    productImage,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (_, __,
                                                            ___) =>
                                                        const Icon(Icons.image),
                                                  )
                                                : Image.file(
                                                    File(productImage),
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (_, __,
                                                            ___) =>
                                                        const Icon(Icons.image),
                                                  ),
                                          ),
                                        ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    question['productName'] ??
                                                        'Ürün Bilgisi Yok',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primary,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  formattedDate,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurface
                                                        .withOpacity(0.6),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (question['userName'] != null)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 4.0),
                                                child: Text(
                                                  'Soran: ${question['userName']}',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurface
                                                        .withOpacity(0.7),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    question['question'] ?? '',
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                  const SizedBox(height: 12),
                                  if (hasReply)
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
                                          const SizedBox(height: 4),
                                          Text(reply),
                                        ],
                                      ),
                                    ),
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: () => _replyToQuestion(
                                          question['id'],
                                          hasReply ? reply : ''),
                                      icon: const Icon(Icons.reply),
                                      label: Text(hasReply
                                          ? langVM.translate('update')
                                          : langVM.translate('reply_button')),
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
    );
  }
}
