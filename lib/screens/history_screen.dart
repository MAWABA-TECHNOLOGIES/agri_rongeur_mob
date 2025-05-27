import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'result_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  Future<void> _deleteEntry(String docId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('history')
          .doc(docId)
          .delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Center(child: Text("Non connecté."));

    final historyRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('history')
        .orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(title: const Text('Historique')),
      body: StreamBuilder<QuerySnapshot>(
        stream: historyRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Text('Erreur');
          if (!snapshot.hasData) return const CircularProgressIndicator();

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("Aucune analyse enregistrée."));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final result = data['result'] ?? {};
              final imageUrl = data['image_url'];
              final name = result['name'] ?? 'Inconnu';
              final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

              return ListTile(
                leading: imageUrl != null
                    ? Image.network(imageUrl,
                        width: 50, height: 50, fit: BoxFit.cover)
                    : const Icon(Icons.image),
                title: Text(name),
                subtitle: createdAt != null
                    ? Text('${createdAt.toLocal()}'.split('.')[0])
                    : null,
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteEntry(doc.id),
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ResultScreen(result: result),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
