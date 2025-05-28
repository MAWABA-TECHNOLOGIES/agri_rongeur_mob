class AppConstants {
  static const String serverBaseUrl = "http://localhost:8000";

  static String get detectImageUrl => "$serverBaseUrl/detect-image";
  static String get translateTextUrl => "$serverBaseUrl/translate";
  static String get ttsUrl => "$serverBaseUrl/tts";

}
