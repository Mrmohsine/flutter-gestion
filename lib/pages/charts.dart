import 'dart:math';
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
            double totalIncome = 0;
            double totalExpense = 0;

            // Aggregation for global totals.
            for (var doc in transactions) {
              final data = doc.data() as Map<String, dynamic>;
              double amount = (data['montant'] as num).toDouble();
              if (data['type'] == 'recette') {
                totalIncome += amount;
              } else if (data['type'] == 'dépense') {
                totalExpense += amount;
              }
            }
            double net = totalIncome - totalExpense;

            // Aggregate totals per category.
            final Map<String, double> categoryIncome = {};
            final Map<String, double> categoryExpense = {};
            for (var doc in transactions) {
              final data = doc.data() as Map<String, dynamic>;
              final category = data['category'] ?? 'Unknown';
              final type = data['type'] ?? '';
              final amount = (data['montant'] as num).toDouble();
              if (type == 'recette') {
                categoryIncome[category] = (categoryIncome[category] ?? 0) + amount;
              } else if (type == 'dépense') {
                categoryExpense[category] = (categoryExpense[category] ?? 0) + amount;
              }
            }
            // All unique categories.
            final allCategories = {
              ...categoryIncome.keys,
              ...categoryExpense.keys,
            }.toList();

            // Build bar groups for each category.
            final List<BarChartGroupData> barGroups = [];
            double maxVal = 0;
            for (int i = 0; i < allCategories.length; i++) {
              final catName = allCategories[i];
              final incomeVal = categoryIncome[catName] ?? 0;
              final expenseVal = categoryExpense[catName] ?? 0;
              maxVal = max(maxVal, max(incomeVal, expenseVal));

              barGroups.add(
                BarChartGroupData(
                  x: i,
                  barsSpace: 8,
                  barRods: [
                    // Income bar (green)
                    BarChartRodData(
                      toY: incomeVal,
                      color: Colors.green,
                      width: 10,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    // Expense bar (red)
                    BarChartRodData(
                      toY: expenseVal,
                      color: Colors.red,
                      width: 10,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Global Totals Section
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
                    "Net Balance: \$${net.toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  // Global Pie Chart
                  SizedBox(
                    height: 300,
                    child: PieChart(
                      PieChartData(
                        sections: _buildPieChartSections(totalIncome, totalExpense),
                        centerSpaceRadius: 40,
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Grouped Bar Chart by Category
                  const Text(
                    'Income & Expense by Category',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 400,
                    child: BarChart(
                      BarChartData(
                        barGroups: barGroups,
                        maxY: maxVal * 1.2,
                        groupsSpace: 20,
                        borderData: FlBorderData(show: false),
                        barTouchData: BarTouchData(enabled: false),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 50,
                              getTitlesWidget: (double value, TitleMeta meta) {
                                final index = value.toInt();
                                if (index < 0 || index >= allCategories.length) return const SizedBox();
                                final catName = allCategories[index];
                                return SideTitleWidget(
                                  meta: meta,
                                  space: 8,
                                  child: Text(
                                    catName,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                      ),
                    ),
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

  /// Builds the global pie chart sections for total income and expense.
  List<PieChartSectionData> _buildPieChartSections(double totalIncome, double totalExpense) {
    final List<PieChartSectionData> sections = [];

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
    return sections;
  }
}
