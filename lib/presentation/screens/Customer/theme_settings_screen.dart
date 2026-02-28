import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/theme_viewmodel.dart';
import '../../viewmodels/language_viewmodel.dart';
import '../../widgets/custom_app_bar.dart';

class ThemeSettingsScreen extends StatefulWidget {
  const ThemeSettingsScreen({super.key});

  @override
  State<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
  final List<Color> _presetColors = const [
    Colors.green,
    Colors.blue,
    Colors.red,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
    Colors.lightBlue,
    Colors.cyan,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.deepOrange,
    Colors.brown,
    Colors.blueGrey,
  ];

  @override
  Widget build(BuildContext context) {
    final themeVM = context.watch<ThemeViewModel>();
    final langVM = context.watch<LanguageViewModel>();

    // Mevcut rengi HSV'ye çevir
    HSVColor currentHSV = HSVColor.fromColor(themeVM.seedColor);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(title: Text(langVM.translate('theme_settings'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 110, 16, 16),
        children: [
          // Tema Modu Seçimi
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  langVM.translate('theme_mode_label') == 'theme_mode_label'
                      ? 'Tema Modu'
                      : langVM.translate('theme_mode_label'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildThemeModeOption(
                        context,
                        icon: Icons.light_mode,
                        label: langVM.translate('light_mode') == 'light_mode'
                            ? 'Açık'
                            : langVM.translate('light_mode'),
                        isSelected: themeVM.themeModeIndex == 1,
                        onTap: () => themeVM.setThemeMode(1),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildThemeModeOption(
                        context,
                        icon: Icons.dark_mode,
                        label: langVM.translate('dark_mode'),
                        isSelected: themeVM.themeModeIndex == 2,
                        onTap: () => themeVM.setThemeMode(2),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Önizleme ve Seçim Kartı
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  langVM.translate('select_color'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 24),
                // Seçili Renk Göstergesi
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: themeVM.seedColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: themeVM.seedColor.withOpacity(0.5),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: Icon(
                    Icons.palette,
                    color: Colors.white.withOpacity(0.8),
                    size: 40,
                  ),
                ),
                const SizedBox(height: 32),
                // Hue Slider (Renk Tayfı)
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFF0000),
                        Color(0xFFFFFF00),
                        Color(0xFF00FF00),
                        Color(0xFF00FFFF),
                        Color(0xFF0000FF),
                        Color(0xFFFF00FF),
                        Color(0xFFFF0000),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 0,
                      thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 16, elevation: 6),
                      overlayShape:
                          const RoundSliderOverlayShape(overlayRadius: 24),
                      thumbColor: Colors.white,
                      overlayColor: Colors.white.withOpacity(0.3),
                      activeTrackColor: Colors.transparent,
                      inactiveTrackColor: Colors.transparent,
                    ),
                    child: Slider(
                      value: currentHSV.hue,
                      min: 0,
                      max: 360,
                      onChanged: (value) {
                        // Canlı renkler için Saturation ve Value değerlerini yüksek tutuyoruz
                        final newColor =
                            HSVColor.fromAHSV(1, value, 0.9, 0.95).toColor();
                        themeVM.changeSeedColor(newColor);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  langVM.translate('slide_to_adjust_color'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.5),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Hazır Renkler Başlığı
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 12),
            child: Text(
              langVM.translate('quick_select_title'),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
          // Hazır Renkler Grid
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
              ),
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: _presetColors.map((color) {
                final isSelected = themeVM.seedColor.value == color.value;
                return GestureDetector(
                  onTap: () => themeVM.changeSeedColor(color),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(
                              color: Theme.of(context).colorScheme.onSurface,
                              width: 3,
                            )
                          : Border.all(
                              color: Colors.transparent,
                              width: 2,
                            ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.4),
                          blurRadius: isSelected ? 8 : 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 24)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeModeOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final color = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withOpacity(0.6);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withOpacity(0.2),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
