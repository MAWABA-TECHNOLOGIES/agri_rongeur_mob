import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  final Map<String, dynamic> result;

  const ResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final String name = result['name'] ?? 'Inconnu';
    final String description =
        result['description'] ?? 'Aucune description disponible.';
    final String? imageUrl = result['image_url']; // Peut être null

    return Scaffold(
      appBar: AppBar(title: const Text('Résultat')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (imageUrl != null)
              Image.network(imageUrl, height: 200, fit: BoxFit.cover),
            const SizedBox(height: 20),
            Text(
              name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              description,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.justify,
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Retour'),
            )
          ],
        ),
      ),
    );
  }
}
