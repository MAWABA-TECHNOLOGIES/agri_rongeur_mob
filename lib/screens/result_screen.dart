import 'package:agri_rongeur_mob/utils/constants.dart';
import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  final Map<String, dynamic> result;

  const ResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final String? imageUrl = result['image_url'];
    final List<dynamic> predictions = result['result'] ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Résultat')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (imageUrl != null)
              Image.network(
                "${AppConstants.serverBaseUrl}$imageUrl",
                height: 200,
                fit: BoxFit.contain,
              ),
            const SizedBox(height: 20),
            const Text(
              'Rongeur(s) détecté(s) :',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: predictions.isEmpty
                  ? const Text('Aucun objet détecté.')
                  : ListView.builder(
                itemCount: predictions.length,
                itemBuilder: (context, index) {
                  final item = predictions[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.bug_report),
                      title: Text(item['class_name']),
                      subtitle: Text(
                        'Confiance : ${(item['confidence'] * 100).toStringAsFixed(1)}%'
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
