import 'package:agri_rongeur_mob/utils/constants.dart';
import 'package:flutter/material.dart';

class ResultScreen extends StatefulWidget {
  final Map<String, dynamic> result;

  const ResultScreen({super.key, required this.result});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool isTranslate = false;

  @override
  Widget build(BuildContext context) {
    final String? imageUrl = widget.result['image_url'];
    final List<dynamic> predictions = filterUniquePredictions(widget.result['result'] ?? []);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Résultat'),
        actions: [
          IconButton(
            icon: isTranslate ? const Icon(Icons.settings_backup_restore) : const Icon(Icons.translate),
            onPressed: () {
              setState(() {
                isTranslate = !isTranslate;
              });
            },
          ),
        ],
      ),
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
                        isTranslate
                            ? (item['translation'] ?? 'Traduction indisponible')
                            : (item['description'] ?? 'Description indisponible'),
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

List<dynamic> filterUniquePredictions (List<dynamic> predictions) {
  final List<dynamic> uniquePredictions = [];
  for (var item in predictions) {
    if (!uniquePredictions.any((x) => x['class_name'] == item['class_name'])) {
      uniquePredictions.add(item);
    }
  }
  return uniquePredictions;
}
