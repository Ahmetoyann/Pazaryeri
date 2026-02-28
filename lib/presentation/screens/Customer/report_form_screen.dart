import 'dart:io';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/language_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/auth_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_sheets.dart';
import '../../widgets/custom_snackbars.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/svg_icon.dart';
import '../../../core/constants/app_icons.dart';
import '../../widgets/custom_text_field.dart';

class ReportFormScreen extends StatefulWidget {
  final String? marketId;
  final String? marketName;
  final String? sellerId;
  final String? sellerName;

  const ReportFormScreen({
    super.key,
    this.marketId,
    this.marketName,
    this.sellerId,
    this.sellerName,
  });

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  final _controller = TextEditingController();
  XFile? _selectedImage;
  String? _selectedSubject;
  final List<String> _subjects = [
    'Genel',
    'Hatalı Bilgi',
    'Şikayet',
    'Öneri',
    'Diğer',
  ];
  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            if (mounted) setState(() => _isListening = false);
          }
        },
        onError: (val) => setState(() => _isListening = false),
      );
      if (available) {
        final initialText = _controller.text;
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            setState(() {
              String spokenText = val.recognizedWords;
              if (initialText.isNotEmpty) {
                String prefix =
                    initialText.endsWith(' ') ? initialText : '$initialText ';
                _controller.text = '$prefix$spokenText';
              } else {
                _controller.text = spokenText;
              }
              _controller.selection = TextSelection.fromPosition(
                  TextPosition(offset: _controller.text.length));
            });
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    CustomBottomSheets.showImagePicker(
      context: context,
      onCameraTap: () async {
        final XFile? image = await picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 800,
          maxHeight: 800,
          imageQuality: 70,
        );
        if (image != null) {
          setState(() => _selectedImage = image);
        }
      },
      onGalleryTap: () async {
        final XFile? image = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 800,
          maxHeight: 800,
          imageQuality: 70,
        );
        if (image != null) {
          setState(() => _selectedImage = image);
        }
      },
    );
  }

  Future<void> _sendReport() async {
    final text = _controller.text.trim();
    if (_selectedSubject == null) {
      CustomSnackbars.showWarning(context, 'Lütfen bir konu seçiniz.');
      return;
    }
    if (text.isEmpty) {
      CustomSnackbars.showWarning(context, 'Lütfen mesajınızı yazınız.');
      return;
    }

    final bool? confirm = await CustomBottomSheets.showConfirmation(
      context: context,
      title: 'Bildirim Gönder',
      message: 'Bu bildirimi göndermek istediğinize emin misiniz?',
      confirmText: 'Gönder',
      cancelText: 'İptal',
      icon: Icons.send,
      confirmColor: Theme.of(context).colorScheme.primary,
    );

    if (confirm != true) return;

    try {
      await LoadingOverlay.show(
        context,
        asyncFunction: () async {
          final authVM = Provider.of<AuthViewModel>(context, listen: false);
          final user = authVM.currentUser;

          String? imageUrl;
          if (_selectedImage != null) {
            imageUrl = await AuthService.instance
                .uploadReviewImage(File(_selectedImage!.path));
          }

          // Bildirimi doğrudan Firestore'a kaydediyoruz
          await FirebaseFirestore.instance.collection('reports').add({
            'type': widget.sellerId != null ? 'seller' : 'market',
            'reportedId': widget.sellerId ?? widget.marketId ?? 'unknown',
            'reportedName':
                widget.sellerName ?? widget.marketName ?? 'Bilinmiyor',
            'reason': 'Konu: $_selectedSubject\nMesaj: $text',
            'reporterId': user?.id ?? 'guest',
            'reporterEmail': user?.email ?? 'Misafir Kullanıcı',
            'imageUrl': imageUrl,
            'timestamp': FieldValue.serverTimestamp(),
            'status': 'pending',
          });
        },
      );

      if (!mounted) return;
      CustomSnackbars.showSuccess(
        context,
        'Bildiriminiz başarıyla gönderildi.',
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      CustomSnackbars.showError(context, 'Hata oluştu: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final langVM = context.watch<LanguageViewModel>();
    final isSellerReport = widget.sellerId != null;
    final title = isSellerReport
        ? '${widget.sellerName} - ${langVM.translate('report_tab')}'
        : '${widget.marketName} - ${langVM.translate('report_tab')}';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 110, 16, 16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedSubject,
                style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: 16),
                dropdownColor: Theme.of(context).cardColor,
                decoration: InputDecoration(
                  labelText: 'Konu Seçiniz',
                  prefixIcon: Icon(Icons.subject,
                      color: Theme.of(context).colorScheme.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.grey.shade300,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.grey.shade300,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary, width: 2),
                  ),
                  filled: true,
                  fillColor: isDark
                      ? Theme.of(context).cardColor
                      : Colors.grey.shade100,
                ),
                items: _subjects.map((s) {
                  return DropdownMenuItem(
                    value: s,
                    child: Text(s,
                        style: TextStyle(
                            color:
                                Theme.of(context).textTheme.bodyLarge?.color)),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedSubject = val),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _controller,
                maxLines: 6,
                hintText: 'Sorunuzu/yorumunuzu yazın',
                suffixIcon: IconButton(
                  icon: Icon(_isListening ? Icons.mic : Icons.mic_none,
                      color: _isListening
                          ? Colors.redAccent
                          : Theme.of(context).iconTheme.color),
                  onPressed: _listen,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                child: InkWell(
                  onTap: _pickImage,
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: _selectedImage == null
                        ? null
                        : BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            image: DecorationImage(
                              image: FileImage(File(_selectedImage!.path)),
                              fit: BoxFit.cover,
                            ),
                          ),
                    child: _selectedImage == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo,
                                size: 40,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.4),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Fotoğraf Ekle (İsteğe Bağlı)',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          )
                        : Stack(
                            children: [
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _selectedImage = null),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.9),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const SvgIcon(
                                        iconPath: AppIcons.close,
                                        color: Colors.white,
                                        size: 20),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _sendReport,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                ),
                child: const Text('Gönder',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
