import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildHeader(),
          const SizedBox(height: 24.0),
          _buildStatCards(),
          const SizedBox(height: 24.0),
          _buildSalesChart(),
          const SizedBox(height: 24.0),
          _buildRecentActivity(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Text(
      'Dashboard',
      style: GoogleFonts.poppins(
        fontSize: 32.0,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildStatCards() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16.0,
      mainAxisSpacing: 16.0,
      childAspectRatio: 1.5,
      children: const [
        StatCard(
          title: 'Today\'s Sales',
          value: '₱1,250',
          icon: Icons.attach_money,
          color: Colors.green,
        ),
        StatCard(
          title: 'Transactions',
          value: '42',
          icon: Icons.receipt_long,
          color: Colors.blue,
        ),
        StatCard(
          title: 'New Customers',
          value: '5',
          icon: Icons.person_add,
          color: Colors.orange,
        ),
        StatCard(
          title: 'Pending Credits',
          value: '₱3,400',
          icon: Icons.credit_card,
          color: Colors.red,
        ),
      ],
    );
  }

  Widget _buildSalesChart() {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly Sales Trend',
              style: GoogleFonts.poppins(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16.0),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 3),
                        FlSpot(1, 4),
                        FlSpot(2, 3.5),
                        FlSpot(3, 5),
                        FlSpot(4, 4.5),
                        FlSpot(5, 6),
                        FlSpot(6, 5.8),
                      ],
                      isCurved: true,
                      color: Colors.teal,
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.teal.withAlpha(51), // Use withAlpha for opacity
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activity',
              style: GoogleFonts.poppins(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16.0),
            _buildActivityItem('Sold 2x Coke', '₱60', '5 mins ago'),
            _buildActivityItem('New Credit: John Doe', '₱500', '1 hour ago'),
            _buildActivityItem('Stock updated: 10x Bread', '', '3 hours ago'),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(String title, String amount, String time) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.history, color: Colors.grey),
      title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
      subtitle: Text(time, style: GoogleFonts.poppins(color: Colors.grey)),
      trailing: amount.isNotEmpty ? Text(amount, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.green)) : null,
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const StatCard({super.key, required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: 32.0, color: color),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(fontSize: 14.0, color: Colors.grey[600]),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(fontSize: 20.0, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
