import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/theme_viewmodel.dart';
import '../../viewmodels/language_viewmodel.dart';

class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

  final List<Color> _colors = const [
    Colors.green,
    Colors.blue,
    Colors.red,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
  ];

  @override
  Widget build(BuildContext context) {
    final themeVM = context.watch<ThemeViewModel>();
    final langVM = context.watch<LanguageViewModel>();

    return Scaffold(
      appBar: AppBar(title: Text(langVM.translate('theme_settings'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            langVM.translate('theme_mode'),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SegmentedButton<int>(
            segments: [
              ButtonSegment<int>(
                value: 0,
                label: Text(langVM.translate('system')),
                icon: const Icon(Icons.brightness_auto),
              ),
              ButtonSegment<int>(
                value: 1,
                label: Text(langVM.translate('light')),
                icon: const Icon(Icons.light_mode),
              ),
              ButtonSegment<int>(
                value: 2,
                label: Text(langVM.translate('dark')),
                icon: const Icon(Icons.dark_mode),
              ),
            ],
            selected: {themeVM.themeModeIndex},
            onSelectionChanged: (Set<int> newSelection) {
              themeVM.setThemeMode(newSelection.first);
            },
          ),
          const SizedBox(height: 32),
          Text(
            langVM.translate('select_color'),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: _colors.map((color) {
              final isSelected = themeVM.seedColor.value == color.value;
              return GestureDetector(
                onTap: () => themeVM.changeSeedColor(color),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(
                            color: Theme.of(context).colorScheme.onSurface,
                            width: 3,
                          )
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
