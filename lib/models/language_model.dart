/// Represents a language model for localization support.
class LanguageModel {
  final String country;
  final String languageName;
  final String languageCode;

  /// Creates a new LanguageModel instance.
  ///
  /// [country] is the country flag emoji.
  /// [languageName] is the display name of the language.
  /// [languageCode] is the ISO language code.
  const LanguageModel({
    required this.country,
    required this.languageName,
    required this.languageCode,
  });

  static List<LanguageModel> languageList() {
    return <LanguageModel>[
      LanguageModel(
        country: "🇺🇸",
        languageName: "English",
        languageCode: 'en',
      ),
      LanguageModel(
          country: "🇸🇦",
          languageName: "اَلْعَرَبِيَّةُ‎",
          languageCode: 'ar'),
    ];
  }
}
