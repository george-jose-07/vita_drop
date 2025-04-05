import 'package:flutter/material.dart';
import '../water_history_screen.dart';

class HealthMetricsScreen extends StatelessWidget {
  final String bmi;
  final String bmiType;
  final double waterIntake;
  final Color textColor;
  final Color accentColor;
  final Color cardColor;

  const HealthMetricsScreen({
    Key? key,
    required this.bmi,
    required this.bmiType,
    required this.waterIntake,
    required this.textColor,
    required this.accentColor,
    required this.cardColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: [
          Expanded(
            child: _buildMetricCard(
              title: 'BMI',
              value: double.tryParse(bmi)?.toStringAsFixed(2) ?? '0.00',
              subtitle: bmiType,
              color: _getBMIColor(double.tryParse(bmi) ?? 0.0),
              icon: Icons.monitor_weight,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WaterHistoryScreen(),
                  ),
                );
              },
              child: _buildMetricCard(
                title: 'Water',
                value: '${waterIntake.toStringAsFixed(2)}L',
                subtitle: 'Daily Intake',
                color: Color(0xFF5cb5e1),
                icon: Icons.water_drop,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: accentColor,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Color _getBMIColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi > 18.5 && bmi < 25) return Colors.green;
    if (bmi > 25 && bmi < 30) return Colors.orange;
    return Colors.red;
  }
}
