class AppStrings {
  static const Map<String, Map<String, String>> _localizedValues = {
    'tr': {
      'home_title': 'PAZARYERİ',
      'account_title': 'Hesabım',
      'login': 'Giriş Yap',
      'logout': 'Çıkış Yap',
      'register': 'Kayıt Ol',
      'dark_mode': 'Karanlık Mod',
      'language': 'Dil / Language',
      'welcome': 'Hoş geldin',
      'guest_message':
          'Hesabım alanını görüntülemek ve kişisel avantajlardan yararlanmak için lütfen giriş yapın.',
      'edit_profile': 'Profili Düzenle',
      'create_account': 'Hesap Oluştur',
      'search_hint': 'Ürün ara (ör: elma)',
      'nearby_markets': 'En Yakın Semt Pazarları',
      'all_markets': 'Tüm Pazarlar',
      'settings': 'Ayarlar',
      'location_refresh': 'Konumu Yenile',
    },
    'en': {
      'home_title': 'MARKETPLACE',
      'account_title': 'My Account',
      'login': 'Login',
      'logout': 'Logout',
      'register': 'Register',
      'dark_mode': 'Dark Mode',
      'language': 'Language / Dil',
      'welcome': 'Welcome',
      'guest_message':
          'Please login to view your account details and enjoy personal benefits.',
      'edit_profile': 'Edit Profile',
      'create_account': 'Create Account',
      'search_hint': 'Search product (e.g. apple)',
      'nearby_markets': 'Nearby Street Markets',
      'all_markets': 'All Markets',
      'settings': 'Settings',
      'location_refresh': 'Refresh Location',
    },
  };

  static String getString(String key, String languageCode) {
    return _localizedValues[languageCode]?[key] ?? key;
  }
}
