import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class TtsPlayerButton extends StatefulWidget {
  final String text;
  final String? audioUrl;
  final String? documentId;
  final int? classId;

  const TtsPlayerButton({
    super.key,
    required this.text,
    this.audioUrl,
    this.documentId,
    this.classId,
  });

  @override
  State<TtsPlayerButton> createState() => _TtsPlayerButtonState();
}

class _TtsPlayerButtonState extends State<TtsPlayerButton> {
  final AudioPlayer _player = AudioPlayer();
  bool isPlaying = false;
  String? localAudioUrl;

  Future<void> _handlePlay() async {
    if (isPlaying) {
      await _player.pause();
      setState(() => isPlaying = false);
      return;
    }

    // Utiliser l'audio existant s'il est présent
    String? url = localAudioUrl ?? widget.audioUrl;

    if (url == null) {
      // Sinon, appeler l'API pour générer
      final response = await http.post(
        Uri.parse("${AppConstants.serverBaseUrl}/tts"),
        body: {'text': widget.text},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        url = data['audio_url'];
        setState(() => localAudioUrl = url);

        // 🔁 Sauvegarde dans Firestore
        if (widget.documentId != null && widget.classId != null) {
          final docRef = FirebaseFirestore.instance
              .collection("users")
              .doc(FirebaseAuth.instance.currentUser?.uid)
              .collection("history")
              .doc(widget.documentId);
          final doc = await docRef.get();

          if (doc.exists) {
            final data = doc.data();
            final resultList = List<Map<String, dynamic>>.from(data?['result'] ?? []);
            final updatedList = resultList.map((item) {
              if (item['class_id'] == widget.classId) {
                return {
                  ...item,
                  'audio_url': localAudioUrl,
                };
              }
              return item;
            }).toList();
            await docRef.update({'result': updatedList});
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erreur lors de la génération audio.")),
        );
        return;
      }
    }

    // Lecture
    await _player.play(UrlSource("${AppConstants.serverBaseUrl}$url"));
    setState(() => isPlaying = true);

    _player.onPlayerComplete.listen((_) {
      setState(() => isPlaying = false);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(isPlaying ? Icons.stop : Icons.volume_up),
      onPressed: _handlePlay,
    );
  }
}
