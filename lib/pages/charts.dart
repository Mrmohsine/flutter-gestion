import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dashboard")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('transactions').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final transactions = snapshot.data!.docs;

            // Calculate totals
            double totalIncome = 0;
            double totalExpense = 0;
            for (var doc in transactions) {
              final data = doc.data() as Map<String, dynamic>;
              double amount = (data['montant'] as num).toDouble();
              String type = data['type'];
              if (type == 'recette') {
                totalIncome += amount;
              } else if (type == 'dépense') {
                totalExpense += amount;
              }
            }
            double net = totalIncome - totalExpense;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Text(
                    "Total Income: \$${totalIncome.toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Total Expense: \$${totalExpense.toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Net: \$${net.toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 300,
                    child: buildPieChart(totalIncome, totalExpense),
                  ),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  Widget buildPieChart(double totalIncome, double totalExpense) {
    List<PieChartSectionData> sections = [];
    if (totalIncome > 0) {
      sections.add(
        PieChartSectionData(
          color: Colors.green,
          value: totalIncome,
          title: 'Income\n\$${totalIncome.toStringAsFixed(2)}',
          radius: 50,
          titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
    }
    if (totalExpense > 0) {
      sections.add(
        PieChartSectionData(
          color: Colors.red,
          value: totalExpense,
          title: 'Expense\n\$${totalExpense.toStringAsFixed(2)}',
          radius: 50,
          titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
    }
    if (sections.isEmpty) {
      sections.add(
        PieChartSectionData(
          color: Colors.grey,
          value: 1,
          title: 'No Data',
          radius: 50,
          titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
    }
    return PieChart(
      PieChartData(
        sections: sections,
        centerSpaceRadius: 40,
        sectionsSpace: 2,
      ),
    );
  }
}
