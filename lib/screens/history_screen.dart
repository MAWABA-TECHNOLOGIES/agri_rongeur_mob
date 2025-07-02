import 'package:agri_rongeur_mob/utils/constants.dart';
import 'package:agri_rongeur_mob/utils/dialogs.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'result_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  Future<void> _deleteEntry(String docId, BuildContext context) async {
    final confirmed = await MyDialog.confirmAndDelete(context, docId);
    if (confirmed ?? false) {
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
          if (snapshot.hasError) {
            return const Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warning, color: Color(0xFFF44336),),
                  Text('Erreur'),
                ],
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("Aucune analyse enregistrée."));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id;
              final result = data['result'] ?? [];
              final imageUrl = data['image_url'];
              // final name = result['name'] ?? 'Inconnu';
              final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

              return ListTile(
                leading: imageUrl != null
                    ? Image.network("${AppConstants.serverBaseUrl}$imageUrl",
                        width: 50, height: 50, fit: BoxFit.cover)
                    : const Icon(Icons.image),
                title: Text(createdAt != null ? '${createdAt.toLocal()}'.split('.')[0] : "Date non définie"),
                subtitle: Text("${result.length} rongeur(s) détecté(s)"),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_forever),
                  onPressed: () => _deleteEntry(doc.id, context),
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ResultScreen(result: data),
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
