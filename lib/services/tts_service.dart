import 'dart:convert';
import 'package:agri_rongeur_mob/utils/constants.dart';
import 'package:http/http.dart' as http;

class TtsService {
  static Future<String?> fetchTtsUrl(String text) async {
    final uri = Uri.parse("${AppConstants.serverBaseUrl}/tts");

    final response = await http.post(
      uri,
      body: {'text': text},
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return AppConstants.serverBaseUrl + (json['audio_url'] ?? '');
    } else {
      return null;
    }
  }
}
