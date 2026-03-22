import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class ReportsAnalyticsScreen extends StatefulWidget {
  const ReportsAnalyticsScreen({super.key});
  @override
  ReportsAnalyticsScreenState createState() => ReportsAnalyticsScreenState();
}

class ReportsAnalyticsScreenState extends State<ReportsAnalyticsScreen> {
  int totalUsers = 0;
  int activeUsers = 0;
  int inactiveUsers = 0;

  @override
  void initState() {
    super.initState();
    _fetchAnalyticsData();
  }

  Future<void> _fetchAnalyticsData() async {
    // Instead of .get(), use .count()
final userCountQuery = await FirebaseFirestore.instance.collection('users').count().get();
final activeUserQuery = await FirebaseFirestore.instance.collection('users').where('status', isEqualTo: true).count().get();

setState(() {
  totalUsers = userCountQuery.count?? 0;
    activeUsers = activeUserQuery.count ?? 0;
});}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Reports & Analytics')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('User Analytics', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            Expanded(
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: activeUsers.toDouble(),
                      title: 'Active',
                      color: Colors.green,
                      radius: 60,
                    ),
                    PieChartSectionData(
                      value: inactiveUsers.toDouble(),
                      title: 'Inactive',
                      color: Colors.red,
                      radius: 60,
                    ),
                  ],
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            SizedBox(height: 20),
            Text('Total Users: $totalUsers'),
            Text('Active Users: $activeUsers'),
            Text('Inactive Users: $inactiveUsers'),
          ],
        ),
      ),
    );
  }
}
