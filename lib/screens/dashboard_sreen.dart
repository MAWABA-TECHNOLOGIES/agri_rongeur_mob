import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, int> classCounts = {};
  Map<String, int> detectionsPerDay = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchStats();
  }

  Future<void> fetchStats() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshots = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("history")
        .orderBy("createdAt", descending: true)
        .get();

    final Map<String, int> tempClassCounts = {};
    final Map<String, int> tempDetectionsPerDay = {};

    for (var doc in snapshots.docs) {
      final data = doc.data();
      final List<dynamic> result = data['result'] ?? [];
      final timestamp = data['createdAt'];
      final date = timestamp != null && timestamp is Timestamp
          ? timestamp.toDate().toString().split(' ')[0]
          : 'Inconnu';

      for (var pred in result) {
        final className = pred['class_name'] ?? 'Inconnu';
        tempClassCounts[className] = (tempClassCounts[className] ?? 0) + 1;
        tempDetectionsPerDay[date] = (tempDetectionsPerDay[date] ?? 0) + 1;
      }
    }

    setState(() {
      classCounts = tempClassCounts;
      detectionsPerDay = tempDetectionsPerDay;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: fetchStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Résumé des détections",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: classCounts.entries.map((entry) {
                  return _StatCard(
                    title: entry.key,
                    value: entry.value.toString(),
                    color: Colors.primaries[Random().nextInt(Colors.primaries.length)],
                  );
                }).toList(),
              ),
              const SizedBox(height: 30),
              const Text(
                "Graphique des types détectés",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 200, child: _BarChartWidget(data: classCounts)),
              const SizedBox(height: 30),
              const Text(
                "Évolution quotidienne",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 250, child: _LineChartWidget(data: detectionsPerDay)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 16, color: color)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class _BarChartWidget extends StatelessWidget {
  final Map<String, int> data;

  const _BarChartWidget({required this.data});

  @override
  Widget build(BuildContext context) {
    final items = data.entries.toList();
    return BarChart(
      BarChartData(
        barGroups: List.generate(items.length, (index) {
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: items[index].value.toDouble(),
                width: 16,
                color: Theme.of(context).primaryColor,
              ),
            ],
          );
        }),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= items.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    items[value.toInt()].key,
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _LineChartWidget extends StatelessWidget {
  final Map<String, int> data;

  const _LineChartWidget({required this.data});

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    final labels = data.keys.toList()..sort();

    for (int i = 0; i < labels.length; i++) {
      spots.add(FlSpot(i.toDouble(), data[labels[i]]!.toDouble()));
    }

    return LineChart(
      LineChartData(
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= labels.length) return const SizedBox.shrink();
                return Text(labels[value.toInt()], style: const TextStyle(fontSize: 10));
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            barWidth: 2,
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }
}
