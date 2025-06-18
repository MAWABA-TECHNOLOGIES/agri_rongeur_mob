import 'dart:convert' as convert;
import 'dart:io';
import 'package:agri_rongeur_mob/utils/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:http_parser/http_parser.dart' as http_parser;
import 'dart:html' as html;

class ApiService {

  static Future<Map<String, dynamic>> detectImage(File imageFile) async {
    final uri = Uri.parse(AppConstants.detectImageUrl);

    final request = http.MultipartRequest("POST", uri);
    request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return convert.jsonDecode(convert.utf8.decode(response.bodyBytes));
    } else {
      throw Exception("Erreur détection : ${response.statusCode} - ${response.body}");
    }
  }

  static Future<Map<String, dynamic>> detectImageWeb() async {
    final input = html.FileUploadInputElement();
    input.accept = 'image/*';
    input.click();

    await input.onChange.first;
    final file = input.files?.first;
    if (file == null) throw Exception("Aucun fichier sélectionné");

    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    await reader.onLoad.first;

    final data = reader.result as Uint8List;

    final uri = Uri.parse(AppConstants.detectImageUrl);
    final request = http.MultipartRequest("POST", uri);

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        data,
        filename: file.name,
        contentType: http_parser.MediaType('image', 'jpeg'),
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return convert.jsonDecode(convert.utf8.decode(response.bodyBytes));
    } else {
      throw Exception("Erreur détection : ${response.statusCode} - ${response.body}");
    }
  }

}
