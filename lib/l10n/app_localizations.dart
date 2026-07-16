import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [Locale('tr'), Locale('en')];

  static const delegate = _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  static const Map<String, Map<String, String>> _values = {
    'en': {
      'appName': 'Calcademy',
      'tagline': 'Calculate. Visualize. Optimize. Learn.',
      'home': 'Home',
      'history': 'History',
      'saved': 'Saved',
      'settings': 'Settings',
      'welcome': 'Welcome to Calcademy',
      'welcomeBody': 'Your modular workspace for scientific problem solving.',
      'available': 'Available now',
      'comingSoon': 'Coming soon',
      'open': 'Open',
      'recent': 'Recent calculations',
      'noRecent': 'Your recent calculations will appear here.',
      'quickActions': 'Quick actions',
      'calculator': 'Scientific Calculator',
      'calculatorDescription': 'Evaluate basic and scientific expressions.',
      'graphing': 'Graphing',
      'matrices': 'Matrices & Linear Algebra',
      'equations': 'Equation Solver',
      'calculus': 'Calculus',
      'statistics': 'Statistics',
      'linearProgramming': 'Linear Programming',
      'integerProgramming': 'Integer Programming',
      'nonlinearOptimization': 'Nonlinear Optimization',
      'dynamicProgramming': 'Dynamic Programming',
      'numericalMethods': 'Numerical Methods',
      'plannedFeature':
          'This academic tool is being prepared for a future release.',
      'plannedIncludes': 'Planned capabilities',
      'backHome': 'Back to home',
      'expressionHint': 'Enter an expression',
      'result': 'Result',
      'copyExpression': 'Copy expression',
      'copyResult': 'Copy result',
      'saveResult': 'Save calculation',
      'useResult': 'Use result',
      'copied': 'Copied to clipboard',
      'degrees': 'Degrees',
      'radians': 'Radians',
      'emptyExpression': 'Enter an expression first.',
      'incompleteExpression': 'The expression is incomplete.',
      'parenthesesError': 'Check the parentheses.',
      'invalidExpression': 'This expression is not valid.',
      'divisionByZero': 'Cannot divide by zero.',
      'domainError': 'The value is outside the function domain.',
      'undefinedResult': 'The result is undefined.',
      'resultTooLarge': 'The result is too large.',
      'noHistory': 'No calculations yet',
      'noHistoryBody': 'Successful calculations are saved automatically.',
      'searchHistory': 'Search history',
      'reuse': 'Use again',
      'delete': 'Delete',
      'clearHistory': 'Clear history',
      'clearHistoryQuestion': 'Delete all calculation history?',
      'clearSaved': 'Clear saved calculations',
      'clearSavedQuestion': 'Delete all saved calculations?',
      'cancel': 'Cancel',
      'clear': 'Clear',
      'noSaved': 'Nothing saved yet',
      'noSavedBody': 'Save useful results from the calculator or history.',
      'title': 'Title',
      'note': 'Note (optional)',
      'save': 'Save',
      'edit': 'Edit',
      'editSaved': 'Edit saved calculation',
      'theme': 'Theme',
      'system': 'System',
      'light': 'Light',
      'dark': 'Dark',
      'language': 'Language',
      'turkish': 'Turkish',
      'english': 'English',
      'defaultAngle': 'Default angle mode',
      'haptics': 'Haptic feedback',
      'keySound': 'Key sound',
      'precision': 'Decimal precision',
      'scientificNotation': 'Automatic scientific notation',
      'data': 'Data',
      'about': 'About',
      'privacy': 'Privacy',
      'privacyBody':
          'All calculations and preferences stay on this device. Calcademy does not use an account, backend, ads, or analytics in this version.',
      'aboutBody':
          'Calcademy is a modular academic calculation workspace for university students.',
      'version': 'Version 1.0.0',
      'today': 'Today',
      'yesterday': 'Yesterday',
      'older': 'Earlier',
    },
    'tr': {
      'appName': 'Calcademy',
      'tagline': 'Hesapla. Görselleştir. Optimize et. Öğren.',
      'home': 'Ana Sayfa',
      'history': 'Geçmiş',
      'saved': 'Kaydedilenler',
      'settings': 'Ayarlar',
      'welcome': 'Calcademy’ye hoş geldiniz',
      'welcomeBody': 'Bilimsel problem çözümü için modüler çalışma alanınız.',
      'available': 'Kullanılabilir',
      'comingSoon': 'Yakında',
      'open': 'Aç',
      'recent': 'Son hesaplamalar',
      'noRecent': 'Son hesaplamalarınız burada görünecek.',
      'quickActions': 'Hızlı işlemler',
      'calculator': 'Bilimsel Hesap Makinesi',
      'calculatorDescription': 'Temel ve bilimsel ifadeleri hesaplayın.',
      'graphing': 'Grafik Çizici',
      'matrices': 'Matrisler ve Lineer Cebir',
      'equations': 'Denklem Çözücü',
      'calculus': 'Calculus',
      'statistics': 'İstatistik',
      'linearProgramming': 'Lineer Programlama',
      'integerProgramming': 'Integer Programlama',
      'nonlinearOptimization': 'Nonlineer Optimizasyon',
      'dynamicProgramming': 'Dinamik Programlama',
      'numericalMethods': 'Sayısal Yöntemler',
      'plannedFeature': 'Bu akademik araç gelecek bir sürüm için hazırlanıyor.',
      'plannedIncludes': 'Planlanan özellikler',
      'backHome': 'Ana sayfaya dön',
      'expressionHint': 'Bir ifade girin',
      'result': 'Sonuç',
      'copyExpression': 'İfadeyi kopyala',
      'copyResult': 'Sonucu kopyala',
      'saveResult': 'Hesaplamayı kaydet',
      'useResult': 'Sonucu kullan',
      'copied': 'Panoya kopyalandı',
      'degrees': 'Derece',
      'radians': 'Radyan',
      'emptyExpression': 'Önce bir ifade girin.',
      'incompleteExpression': 'İfade tamamlanmamış.',
      'parenthesesError': 'Parantezleri kontrol edin.',
      'invalidExpression': 'Bu ifade geçerli değil.',
      'divisionByZero': 'Sıfıra bölme yapılamaz.',
      'domainError': 'Bu işlem için geçersiz bir değer girdiniz.',
      'undefinedResult': 'Sonuç tanımsız.',
      'resultTooLarge': 'Sonuç gösterilemeyecek kadar büyük.',
      'noHistory': 'Henüz hesaplama yok',
      'noHistoryBody': 'Başarılı hesaplamalar otomatik olarak kaydedilir.',
      'searchHistory': 'Geçmişte ara',
      'reuse': 'Tekrar kullan',
      'delete': 'Sil',
      'clearHistory': 'Geçmişi temizle',
      'clearHistoryQuestion': 'Tüm hesaplama geçmişi silinsin mi?',
      'clearSaved': 'Kaydedilenleri temizle',
      'clearSavedQuestion': 'Tüm kaydedilen hesaplamalar silinsin mi?',
      'cancel': 'İptal',
      'clear': 'Temizle',
      'noSaved': 'Henüz kayıt yok',
      'noSavedBody':
          'Hesap makinesinden veya geçmişten yararlı sonuçları kaydedin.',
      'title': 'Başlık',
      'note': 'Not (isteğe bağlı)',
      'save': 'Kaydet',
      'edit': 'Düzenle',
      'editSaved': 'Kaydedilen hesaplamayı düzenle',
      'theme': 'Tema',
      'system': 'Sistem',
      'light': 'Açık',
      'dark': 'Koyu',
      'language': 'Dil',
      'turkish': 'Türkçe',
      'english': 'İngilizce',
      'defaultAngle': 'Varsayılan açı modu',
      'haptics': 'Titreşim geri bildirimi',
      'keySound': 'Tuş sesi',
      'precision': 'Ondalık hassasiyeti',
      'scientificNotation': 'Otomatik bilimsel gösterim',
      'data': 'Veriler',
      'about': 'Hakkında',
      'privacy': 'Gizlilik',
      'privacyBody':
          'Tüm hesaplamalar ve tercihler bu cihazda kalır. Calcademy bu sürümde hesap, sunucu, reklam veya analiz kullanmaz.',
      'aboutBody':
          'Calcademy, üniversite öğrencileri için modüler bir akademik hesaplama alanıdır.',
      'version': 'Sürüm 1.0.0',
      'today': 'Bugün',
      'yesterday': 'Dün',
      'older': 'Daha önce',
    },
  };

  String t(String key) =>
      _values[locale.languageCode]?[key] ?? _values['en']![key] ?? key;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales.any(
    (item) => item.languageCode == locale.languageCode,
  );

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture(AppLocalizations(locale));

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension LocalizationContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
