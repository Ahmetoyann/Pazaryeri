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
import '../../widgets/custom_button.dart';

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
      CustomSnackbars.showWarning(context, 'Lütfen bildirim konusunu seçiniz.');
      return;
    }
    if (text.isEmpty) {
      CustomSnackbars.showWarning(
          context, 'Lütfen bildirim mesajınızı yazınız.');
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
      appBar: CustomAppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedSubject,
                style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: 16),
                dropdownColor: isDark ? Colors.black : Colors.white,
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
              if (_selectedImage == null)
                GestureDetector(
                  onTap: _pickImage,
                  child: CustomPaint(
                    painter: _DashedBorderPainter(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.5),
                      borderRadius: 16.0,
                    ),
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.add_a_photo_outlined,
                              color: Theme.of(context).colorScheme.primary,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Fotoğraf Ekle (İsteğe Bağlı)',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                Stack(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          File(_selectedImage!.path),
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          child: Icon(
                            Icons.add_a_photo_outlined,
                            color: Theme.of(context).colorScheme.onPrimary,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedImage = null),
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
              const SizedBox(height: 24),
              CustomButton(
                text: 'Gönder',
                onPressed: _sendReport,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;
  final double borderRadius;

  _DashedBorderPainter({
    required this.color,
    this.strokeWidth = 2.0,
    this.dashWidth = 8.0,
    this.dashSpace = 6.0,
    this.borderRadius = 16.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

    final path = Path()..addRRect(rrect);
    final pathMetrics = path.computeMetrics();
    final dashedPath = Path();

    for (final metric in pathMetrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        dashedPath.addPath(
          metric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }

    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.dashSpace != dashSpace ||
        oldDelegate.borderRadius != borderRadius;
  }
}
