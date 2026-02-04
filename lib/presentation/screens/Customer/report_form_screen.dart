import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/models/market.dart';
import '../../widgets/custom_app_bar.dart';

class ReportFormScreen extends StatefulWidget {
  final Market market;
  const ReportFormScreen({super.key, required this.market});

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  final _controller = TextEditingController();
  bool _sending = false;
  XFile? _selectedImage;
  String? _selectedSubject;
  final List<String> _subjects = [
    'Genel',
    'Hatalı Bilgi',
    'Şikayet',
    'Öneri',
    'Diğer',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.photo_camera,
                    color: Theme.of(context).iconTheme.color),
                title: const Text('Kamera'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final XFile? image = await picker.pickImage(
                    source: ImageSource.camera,
                  );
                  if (image != null) {
                    setState(() => _selectedImage = image);
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library,
                    color: Theme.of(context).iconTheme.color),
                title: const Text('Galeri'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final XFile? image = await picker.pickImage(
                    source: ImageSource.gallery,
                  );
                  if (image != null) {
                    setState(() => _selectedImage = image);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendReport() async {
    final text = _controller.text.trim();
    if (_selectedSubject == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lütfen bir konu seçiniz.')));
      return;
    }
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen mesajınızı yazınız.')),
      );
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bildirim Gönder'),
        content: const Text(
          'Bu bildirimi göndermek istediğinize emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Gönder'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _sending = true);
    // Simulate sending
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _sending = false);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Bildirim gönderildi')));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.market;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(title: Text('Bildir: ${m.name}')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 110, 16, 16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedSubject,
                dropdownColor: const Color(0xFF1B5E20).withValues(alpha: 0.95),
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Konu Seçiniz',
                  prefixIcon: Icon(Icons.subject,
                      color: Theme.of(context).iconTheme.color),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide:
                          BorderSide(color: Colors.white.withOpacity(0.3))),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide:
                          BorderSide(color: Colors.white.withOpacity(0.3))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.5), width: 2)),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                ),
                items: _subjects.map((s) {
                  return DropdownMenuItem(
                    value: s,
                    child: Text(s, style: const TextStyle(color: Colors.white)),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedSubject = val),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: 'Sorunuzu/yorumunuzu yazın',
                  hintStyle:
                      TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide:
                          BorderSide(color: Colors.white.withOpacity(0.3))),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide:
                          BorderSide(color: Colors.white.withOpacity(0.3))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.5), width: 2)),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
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
                        : null,
                  ),
                ),
              ),
              if (_selectedImage != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => setState(() => _selectedImage = null),
                    icon: Icon(Icons.delete,
                        color: Theme.of(context).colorScheme.error),
                    label: Text(
                      'Fotoğrafı Kaldır',
                      style:
                          TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _sending ? null : _sendReport,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                    side: BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                ),
                child: _sending
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Gönder',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
