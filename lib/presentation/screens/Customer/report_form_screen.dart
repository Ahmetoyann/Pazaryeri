import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/models/market.dart';

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
                leading: const Icon(Icons.photo_camera),
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
                leading: const Icon(Icons.photo_library),
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
      appBar: AppBar(title: Text('Bildir: ${m.name}')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Pazar: ${m.name}'),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedSubject,
                hint: const Text('Konu Seçiniz'),
                items: _subjects.map((s) {
                  return DropdownMenuItem(value: s, child: Text(s));
                }).toList(),
                onChanged: (val) => setState(() => _selectedSubject = val),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText: 'Sorunuzu/yorumunuzu yazın',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(_selectedImage!.path),
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.add_a_photo,
                              size: 40,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Fotoğraf Ekle (İsteğe Bağlı)',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                ),
              ),
              if (_selectedImage != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => setState(() => _selectedImage = null),
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text(
                      'Fotoğrafı Kaldır',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _sending ? null : _sendReport,
                child: _sending
                    ? const CircularProgressIndicator()
                    : const Text('Gönder'),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
