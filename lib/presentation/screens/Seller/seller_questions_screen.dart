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
import '../../widgets/custom_bottom_sheets.dart';
import '../../../core/constants/app_icons.dart';
import '../../widgets/svg_icon.dart';
import '../../widgets/custom_snackbars.dart';

class SellerQuestionsScreen extends StatefulWidget {
  final String? highlightQuestionId;
  const SellerQuestionsScreen({super.key, this.highlightQuestionId});

  @override
  State<SellerQuestionsScreen> createState() => _SellerQuestionsScreenState();
}

class _SellerQuestionsScreenState extends State<SellerQuestionsScreen> {
  String _filterType = 'all'; // 'all', 'unanswered'
  final Map<String, GlobalKey> _itemKeys = {};
  Stream<List<Map<String, dynamic>>>? _questionsStream;
  bool _hasScrolledToHighlight = false;

  @override
  void initState() {
    super.initState();
    final sellerId = context.read<AuthViewModel>().currentUser?.id;
    if (sellerId != null) {
      _questionsStream =
          AuthService.instance.getSellerQuestionsStream(sellerId);
    }
  }

  void _scrollToHighlightedItem() {
    final id = widget.highlightQuestionId;
    if (id == null || _hasScrolledToHighlight) return;

    Future.delayed(const Duration(milliseconds: 500), () {
      final key = _itemKeys[id];
      if (key?.currentContext != null) {
        _hasScrolledToHighlight = true;
        Scrollable.ensureVisible(
          key!.currentContext!,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
          alignment: 0.5,
        );
      }
    });
  }

  List<Map<String, dynamic>> _applyFilter(
      List<Map<String, dynamic>> allQuestions) {
    if (_filterType == 'unanswered') {
      return allQuestions.where((q) {
        final reply = q['sellerReply'];
        return reply == null || reply.toString().isEmpty;
      }).toList();
    } else {
      return List.from(allQuestions);
    }
  }

  void _onFilterChanged(String? newValue) {
    if (newValue != null) {
      setState(() {
        _filterType = newValue;
      });
    }
  }

  Future<void> _replyToQuestion(String questionId, String currentReply) async {
    final langVM = Provider.of<LanguageViewModel>(context, listen: false);
    final sellerVM = Provider.of<SellerViewModel>(context, listen: false);
    final controller = TextEditingController(text: currentReply);
    final theme = Theme.of(context);

    await CustomBottomSheets.showContent(
      context: context,
      title: langVM.translate('reply_button'),
      child: StatefulBuilder(
        builder: (context, setState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hazır Şablonlar',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ActionChip(
                      avatar: Icon(Icons.add,
                          size: 18, color: theme.colorScheme.primary),
                      label: Text('Oluştur',
                          style: TextStyle(
                              color: theme.colorScheme.primary, fontSize: 12)),
                      backgroundColor: theme.cardColor,
                      side: BorderSide(
                          color: theme.colorScheme.primary.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      onPressed: () async {
                        final String? result =
                            await _showAddTemplateDialog(context);
                        if (result != null && result.isNotEmpty) {
                          await sellerVM.addReplyTemplate(result);
                          setState(() {});
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    ...sellerVM.replyTemplates.map((template) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InputChip(
                          label: Text(template,
                              style: const TextStyle(fontSize: 12)),
                          onPressed: () {
                            controller.text = template;
                            controller.selection = TextSelection.fromPosition(
                                TextPosition(offset: controller.text.length));
                          },
                          onDeleted: () async {
                            await sellerVM.removeReplyTemplate(template);
                            setState(() {});
                          },
                          backgroundColor: theme.cardColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(color: theme.dividerColor),
                          ),
                          padding: EdgeInsets.zero,
                          labelPadding:
                              const EdgeInsets.symmetric(horizontal: 8),
                          deleteIcon: const Icon(Icons.close,
                              size: 16, color: Colors.grey),
                        ),
                      );
                    }),
                  ],
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
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor:
                        Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    elevation: 0,
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

                        await DialogService.showSuccess(
                          context,
                          message: langVM.translate('reply_sent_success'),
                          duration: const Duration(seconds: 3),
                        );
                      }
                    }
                  },
                  child: Text(langVM.translate('send_button')),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<String?> _showAddTemplateDialog(BuildContext context) async {
    final controller = TextEditingController();
    return await CustomBottomSheets.showContent<String>(
      context: context,
      title: 'Yeni Şablon Oluştur',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Şablon metni...',
              filled: true,
              fillColor: Theme.of(context).cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
            autofocus: true,
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: const Text('Ekle',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final langVM = context.watch<LanguageViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = Theme.of(context).cardColor;
    final contentColor = Theme.of(context).colorScheme.onSurface;

    return Column(
      children: [
        // Filtreleme Alanı
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _filterType,
                      dropdownColor: isDark
                          ? Colors.black
                          : Colors.white, // Dropdown arka plan rengi
                      isExpanded: true,
                      icon: Icon(Icons.filter_list, color: contentColor),
                      style: TextStyle(color: contentColor, fontSize: 17),
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
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(Icons.post_add,
                      color: Theme.of(context).colorScheme.primary),
                  tooltip: 'Hızlı Şablon Oluştur',
                  onPressed: () async {
                    final sellerVM =
                        Provider.of<SellerViewModel>(context, listen: false);
                    final String? result =
                        await _showAddTemplateDialog(context);
                    if (result != null && result.isNotEmpty) {
                      await sellerVM.addReplyTemplate(result);
                      setState(() {});
                      if (mounted) {
                        CustomSnackbars.showSuccess(
                            context, 'Şablon başarıyla eklendi');
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _questionsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text(langVM.translate('no_results')));
              }

              final allQuestions = snapshot.data!;
              final filteredQuestions = _applyFilter(allQuestions);

              // Highlight işlemi için kontrol (Sadece ilk yüklemede)
              if (widget.highlightQuestionId != null &&
                  !_hasScrolledToHighlight) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToHighlightedItem();
                });
              }

              if (filteredQuestions.isEmpty) {
                return Center(child: Text(langVM.translate('no_results')));
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                itemCount: filteredQuestions.length,
                itemBuilder: (context, index) {
                  final question = filteredQuestions[index];
                  final date = question['date'] != null
                      ? DateTime.tryParse(question['date'].toString())
                      : null;
                  final formattedDate = date != null
                      ? DateFormat('dd MMM yyyy', langVM.currentLanguage)
                          .format(date)
                      : '';
                  final reply = question['sellerReply'];
                  final hasReply = reply != null && reply.toString().isNotEmpty;
                  final isHighlighted =
                      widget.highlightQuestionId == question['id'];
                  final productImage = question['productImage'];

                  if (!_itemKeys.containsKey(question['id'])) {
                    _itemKeys[question['id']] = GlobalKey();
                  }

                  return Container(
                    key: _itemKeys[question['id']],
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: isHighlighted
                          ? Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1)
                          : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: isHighlighted
                          ? Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2)
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (productImage != null &&
                                      productImage.toString().isNotEmpty)
                                    Container(
                                      width: 50,
                                      height: 50,
                                      margin: const EdgeInsets.only(right: 12),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: Colors.grey.withOpacity(0.2),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: productImage.startsWith('http')
                                            ? Image.network(
                                                productImage,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    const Icon(Icons.image,
                                                        size: 28),
                                              )
                                            : Image.file(
                                                File(productImage),
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    const Icon(Icons.image,
                                                        size: 28),
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
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                question['productName'] ??
                                                    'Ürün Bilgisi Yok',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 17,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              formattedDate,
                                              style: TextStyle(
                                                fontSize: 13,
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
                                            padding:
                                                const EdgeInsets.only(top: 4.0),
                                            child: Text(
                                              'Soran: ${question['userName']}',
                                              style: TextStyle(
                                                fontSize: 14,
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
                                style: const TextStyle(fontSize: 16),
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
                                        langVM.translate('seller_reply_label'),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
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
                                      question['id'], hasReply ? reply : ''),
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
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
