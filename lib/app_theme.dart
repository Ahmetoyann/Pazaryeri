import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Özel constructor, bu sınıfın örneklenmesini engeller
  AppTheme._();

  // --- RENK PALETİ (COLOR PALETTE) ---
  static const Color _primaryColor = Color(0xFF388E3C); // Pazar Yeşili
  static const Color _secondaryColor = Color(0xFFF57C00); // Turuncu
  static const Color _errorColor = Color(0xFFD32F2F); // Hata Kırmızısı
  static const Color _surfaceLight = Colors.white;
  static const Color _surfaceDark = Color(0xFF1E1E1E);

  // --- AYDINLIK TEMA (LIGHT THEME) ---
  static ThemeData lightTheme(Color seedColor) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
      primary: seedColor == Colors.green ? _primaryColor : seedColor,
      secondary: _secondaryColor,
      error: _errorColor,
      surface: _surfaceLight,
    ).copyWith(
      onSurface: Colors.white, // Varsayılan siyah yerine beyaz yapıyoruz
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.transparent, // Arka plan gradient için
      cardColor: Colors.white.withOpacity(0.05), // Kartlar daha şeffaf beyaz
      cardTheme: CardThemeData(
        color: Colors.white.withOpacity(0.05),
        elevation: 8,
        shadowColor: Colors.white.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF1B5E20).withOpacity(0.95),
        elevation: 8,
        shadowColor: Colors.white.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: const TextStyle(
            fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        contentTextStyle: const TextStyle(fontSize: 16, color: Colors.white70),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Colors.white,
        contentTextStyle: const TextStyle(color: Colors.black),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        behavior: SnackBarBehavior.floating,
        elevation: 6,
      ),

      // Sayfa Geçiş Animasyonları
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CustomScaleTransitionBuilder(),
          TargetPlatform.iOS: CustomScaleTransitionBuilder(),
        },
      ),

      // AppBar Teması
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      // Bottom Navigation Bar Teması
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: Colors.white,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // Navigation Bar (Material 3) Teması
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white.withOpacity(0.1),
        indicatorColor: colorScheme.primary.withOpacity(0.2),
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return TextStyle(
                color: colorScheme.primary, fontWeight: FontWeight.bold);
          }
          return const TextStyle(color: Colors.white);
        }),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return IconThemeData(color: colorScheme.primary);
          }
          return const IconThemeData(color: Colors.white);
        }),
      ),

      // Menu Teması
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: MaterialStateProperty.all(
              const Color(0xFF1B5E20).withOpacity(0.95)),
          elevation: MaterialStateProperty.all(8),
          shape: MaterialStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        ),
      ),

      // Dropdown Menu Teması
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: MaterialStateProperty.all(
              const Color(0xFF1B5E20).withOpacity(0.95)),
          elevation: MaterialStateProperty.all(8),
          shape: MaterialStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),

      // SearchBar Teması
      searchBarTheme: SearchBarThemeData(
        backgroundColor:
            MaterialStateProperty.all(Colors.white.withOpacity(0.1)),
        elevation: MaterialStateProperty.all(2.0),
        shadowColor: MaterialStateProperty.all(Colors.white.withOpacity(0.1)),
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        textStyle:
            MaterialStateProperty.all(const TextStyle(color: Colors.white)),
        hintStyle:
            MaterialStateProperty.all(const TextStyle(color: Colors.white70)),
      ),

      // Chip (Filtreler vb.) Teması
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white.withOpacity(0.1),
        side: BorderSide.none,
        shape: const StadiumBorder(),
        labelStyle: const TextStyle(color: Colors.white),
      ),

      // Divider (Ayırıcı) Teması
      dividerTheme: DividerThemeData(
        color: Colors.white.withOpacity(0.1),
        thickness: 1,
        space: 1,
      ),

      // ListTile Teması
      listTileTheme: ListTileThemeData(
        iconColor: Colors.white,
        textColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // Bottom Sheet Teması
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: const Color(0xFF1B5E20).withOpacity(0.95),
        elevation: 8,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      // Popup Menu Teması
      popupMenuTheme: PopupMenuThemeData(
        color: const Color(0xFF1B5E20).withOpacity(0.95),
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(color: Colors.white),
      ),

      // TabBar Teması
      tabBarTheme: TabBarThemeData(
        labelColor: colorScheme.primary,
        unselectedLabelColor: Colors.white60,
        indicatorSize: TabBarIndicatorSize.label,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: colorScheme.primary, width: 3),
        ),
        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
        dividerColor: Colors.transparent,
      ),

      // Switch (Anahtar) Teması
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return Colors.white;
          }
          return Colors.grey.shade400;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return colorScheme.primary;
          }
          return Colors.grey.shade700;
        }),
        trackOutlineColor: MaterialStateProperty.all(Colors.transparent),
      ),

      // Checkbox Teması
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return colorScheme.primary;
          }
          return Colors.transparent;
        }),
        checkColor: MaterialStateProperty.all(Colors.white),
        side: BorderSide(color: Colors.grey.shade400, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      // Slider Teması
      sliderTheme: SliderThemeData(
        trackHeight: 4,
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: colorScheme.primary.withOpacity(0.2),
        thumbColor: colorScheme.primary,
        overlayColor: colorScheme.primary.withOpacity(0.1),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
      ),

      // Date Picker Teması
      datePickerTheme: DatePickerThemeData(
        backgroundColor: const Color(0xFF1B5E20).withOpacity(0.95),
        headerBackgroundColor: colorScheme.primary,
        headerForegroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        dayForegroundColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return Colors.white;
          }
          return Colors.white;
        }),
        todayForegroundColor: MaterialStateProperty.all(colorScheme.primary),
        todayBorder: BorderSide(color: colorScheme.primary),
        yearStyle: const TextStyle(color: Colors.white),
      ),

      // Progress Indicator Teması
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.primary.withOpacity(0.2),
        circularTrackColor: Colors.transparent,
      ),

      // Tooltip Teması
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(color: Colors.black, fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        waitDuration: const Duration(milliseconds: 500),
      ),

      // Segmented Button Teması
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          textStyle: MaterialStateProperty.all(
            const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return colorScheme.primary;
            }
            return Colors.transparent;
          }),
          foregroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return Colors.white;
            }
            return Colors.white;
          }),
          side: MaterialStateProperty.all(
            BorderSide(color: colorScheme.primary),
          ),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
      ),

      // Buton Temaları
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 6,
          shadowColor: colorScheme.primary.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          textStyle: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          backgroundColor: Colors.transparent,
          side: BorderSide(color: colorScheme.primary, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        ),
      ),

      // Input (TextField) Teması
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: seedColor, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        labelStyle: const TextStyle(color: Colors.white70),
      ),

      // İkon Teması
      iconTheme: IconThemeData(
        color: Colors.white,
      ),

      // Metin Teması
      textTheme: GoogleFonts.poppinsTextTheme(
        ThemeData.light()
            .textTheme
            .apply(bodyColor: Colors.white, displayColor: Colors.white),
      ),
    );
  }

  // --- KARANLIK TEMA (DARK THEME) ---
  static ThemeData darkTheme(Color seedColor) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
      primary: seedColor == Colors.green ? _primaryColor : seedColor,
      secondary: _secondaryColor,
      error: _errorColor,
      surface: _surfaceDark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.transparent,
      cardColor: _surfaceDark.withOpacity(0.8),
      cardTheme: CardThemeData(
        color: _surfaceDark.withOpacity(0.8),
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _surfaceDark.withOpacity(0.9),
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: const TextStyle(
            fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        contentTextStyle: const TextStyle(fontSize: 16, color: Colors.white70),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Colors.white.withOpacity(0.9),
        contentTextStyle: const TextStyle(color: Colors.black87),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        behavior: SnackBarBehavior.floating,
        elevation: 6,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CustomScaleTransitionBuilder(),
          TargetPlatform.iOS: CustomScaleTransitionBuilder(),
        },
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // Navigation Bar (Material 3) Teması
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _surfaceDark.withOpacity(0.9),
        indicatorColor: colorScheme.primary.withOpacity(0.2),
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return TextStyle(
                color: colorScheme.primary, fontWeight: FontWeight.bold);
          }
          return const TextStyle(color: Colors.grey);
        }),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return IconThemeData(color: colorScheme.primary);
          }
          return const IconThemeData(color: Colors.grey);
        }),
      ),

      // Menu Teması
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor:
              MaterialStateProperty.all(_surfaceDark.withOpacity(0.9)),
          elevation: MaterialStateProperty.all(8),
          shape: MaterialStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        ),
      ),

      // Dropdown Menu Teması
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor:
              MaterialStateProperty.all(_surfaceDark.withOpacity(0.9)),
          elevation: MaterialStateProperty.all(8),
          shape: MaterialStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _surfaceDark.withOpacity(0.8),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),

      // SearchBar Teması
      searchBarTheme: SearchBarThemeData(
        backgroundColor:
            MaterialStateProperty.all(_surfaceDark.withOpacity(0.8)),
        elevation: MaterialStateProperty.all(2.0),
        shadowColor: MaterialStateProperty.all(Colors.black.withOpacity(0.4)),
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        textStyle:
            MaterialStateProperty.all(const TextStyle(color: Colors.white)),
        hintStyle:
            MaterialStateProperty.all(const TextStyle(color: Colors.white70)),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey.withOpacity(0.2),
        side: BorderSide.none,
        shape: const StadiumBorder(),
        labelStyle: const TextStyle(color: Colors.white),
      ),

      // Divider (Ayırıcı) Teması
      dividerTheme: DividerThemeData(
        color: Colors.white.withOpacity(0.1),
        thickness: 1,
        space: 1,
      ),

      // ListTile Teması
      listTileTheme: ListTileThemeData(
        iconColor: Colors.grey.shade300,
        textColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // Bottom Sheet Teması
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: _surfaceDark.withOpacity(0.9),
        elevation: 8,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      // Popup Menu Teması
      popupMenuTheme: PopupMenuThemeData(
        color: _surfaceDark.withOpacity(0.9),
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(color: Colors.white),
      ),

      // TabBar Teması
      tabBarTheme: TabBarThemeData(
        labelColor: colorScheme.primary,
        unselectedLabelColor: Colors.grey,
        indicatorSize: TabBarIndicatorSize.label,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: colorScheme.primary, width: 3),
        ),
        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
        dividerColor: Colors.transparent,
      ),

      // Switch (Anahtar) Teması
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return Colors.white;
          }
          return Colors.grey.shade400;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return colorScheme.primary;
          }
          return Colors.grey.shade700;
        }),
        trackOutlineColor: MaterialStateProperty.all(Colors.transparent),
      ),

      // Checkbox Teması
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return colorScheme.primary;
          }
          return Colors.transparent;
        }),
        checkColor: MaterialStateProperty.all(Colors.white),
        side: BorderSide(color: Colors.grey.shade400, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      // Slider Teması
      sliderTheme: SliderThemeData(
        trackHeight: 4,
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: colorScheme.primary.withOpacity(0.3),
        thumbColor: colorScheme.primary,
        overlayColor: colorScheme.primary.withOpacity(0.2),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
      ),

      // Date Picker Teması
      datePickerTheme: DatePickerThemeData(
        backgroundColor: _surfaceDark.withOpacity(0.9),
        headerBackgroundColor: colorScheme.primary,
        headerForegroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        dayForegroundColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return Colors.white;
          }
          return Colors.white;
        }),
        todayForegroundColor: MaterialStateProperty.all(colorScheme.primary),
        todayBorder: BorderSide(color: colorScheme.primary),
        yearStyle: const TextStyle(color: Colors.white),
      ),

      // Progress Indicator Teması
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.primary.withOpacity(0.3),
        circularTrackColor: Colors.transparent,
      ),

      // Tooltip Teması
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(color: Colors.black87, fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        waitDuration: const Duration(milliseconds: 500),
      ),

      // Segmented Button Teması
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          textStyle: MaterialStateProperty.all(
            const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return colorScheme.primary;
            }
            return Colors.transparent;
          }),
          foregroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return Colors.white;
            }
            return Colors.white;
          }),
          side: MaterialStateProperty.all(
            BorderSide(color: colorScheme.primary),
          ),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          textStyle: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          backgroundColor: Colors.transparent,
          side: BorderSide(color: colorScheme.primary, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.withOpacity(0.8), // Koyu modda input arka planı
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white54),
      ),
      iconTheme: IconThemeData(
        color: Colors.white,
        shadows: [
          Shadow(
            offset: const Offset(1, 1),
            blurRadius: 2,
            color: Colors.black.withOpacity(0.5),
          )
        ],
      ),
      textTheme: GoogleFonts.poppinsTextTheme(
        _buildTextTheme(
            ThemeData.dark().textTheme, Colors.black.withOpacity(0.5)),
      ),
    );
  }

  // Metinlere hafif gölge ekleyen yardımcı metot
  static TextTheme _buildTextTheme(TextTheme base, Color shadowColor) {
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        shadows: [
          Shadow(offset: const Offset(1, 1), blurRadius: 2, color: shadowColor)
        ],
      ),
      displayMedium: base.displayMedium?.copyWith(
        shadows: [
          Shadow(offset: const Offset(1, 1), blurRadius: 2, color: shadowColor)
        ],
      ),
      displaySmall: base.displaySmall?.copyWith(
        shadows: [
          Shadow(offset: const Offset(1, 1), blurRadius: 2, color: shadowColor)
        ],
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        shadows: [
          Shadow(offset: const Offset(1, 1), blurRadius: 2, color: shadowColor)
        ],
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        shadows: [
          Shadow(offset: const Offset(1, 1), blurRadius: 2, color: shadowColor)
        ],
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        shadows: [
          Shadow(offset: const Offset(1, 1), blurRadius: 2, color: shadowColor)
        ],
      ),
      titleLarge: base.titleLarge?.copyWith(
        shadows: [
          Shadow(offset: const Offset(1, 1), blurRadius: 2, color: shadowColor)
        ],
      ),
      titleMedium: base.titleMedium?.copyWith(
        shadows: [
          Shadow(offset: const Offset(1, 1), blurRadius: 2, color: shadowColor)
        ],
      ),
      titleSmall: base.titleSmall?.copyWith(
        shadows: [
          Shadow(offset: const Offset(1, 1), blurRadius: 2, color: shadowColor)
        ],
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        shadows: [
          Shadow(
              offset: const Offset(0.5, 0.5), blurRadius: 1, color: shadowColor)
        ],
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        shadows: [
          Shadow(
              offset: const Offset(0.5, 0.5), blurRadius: 1, color: shadowColor)
        ],
      ),
      bodySmall: base.bodySmall?.copyWith(
        shadows: [
          Shadow(
              offset: const Offset(0.5, 0.5), blurRadius: 1, color: shadowColor)
        ],
      ),
      labelLarge: base.labelLarge?.copyWith(
        shadows: [
          Shadow(
              offset: const Offset(0.5, 0.5), blurRadius: 1, color: shadowColor)
        ],
      ),
    );
  }
}

// Sayfa geçiş animasyonu
class CustomScaleTransitionBuilder extends PageTransitionsBuilder {
  const CustomScaleTransitionBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.92, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        child: child,
      ),
    );
  }
}
