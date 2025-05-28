import 'dart:io';
import 'package:agri_rongeur_mob/services/api_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

import 'result_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  File? _selectedImage;
  bool _loading = false;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 80);
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  Future<String> _uploadImage(File file) async {
    final fileName = path.basename(file.path);
    final ref = FirebaseStorage.instance.ref().child('uploads/$fileName');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null && !kIsWeb) return;

    setState(() => _loading = true);

    try {
      final res = kIsWeb ? await ApiService.detectImageWeb() :
        await ApiService.detectImage(_selectedImage!);

      print("Prédictions : ${res['predictions']}");
      print("Image annotée URL : ${res['image_url']}");
      res['result'] = res['predictions'];
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .collection('history')
          .add({
        ...res,
        'createdAt': FieldValue.serverTimestamp(),
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(result: res),
        ),
      );
    } catch (e) {
      print(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : ${e.toString()}')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Détection de rongeur')),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_selectedImage != null && !kIsWeb)
                    Image.file(_selectedImage!, height: 200),
                  if (_selectedImage != null && kIsWeb)
                    Image.network(_selectedImage!.path, height: 200),
                  const SizedBox(height: 20),
                  if (_selectedImage == null && !kIsWeb)
                    ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text("Prendre une photo"),
                    ),
                  if (_selectedImage == null && !kIsWeb)
                    ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library),
                      label: const Text("Choisir depuis la galerie"),
                    ),
                  if (_selectedImage != null || kIsWeb)
                    ElevatedButton(
                      onPressed: _analyzeImage,
                      child: const Text("Analyser l'image"),
                    ),
                ],
              ),
      ),
    );
  }
}
