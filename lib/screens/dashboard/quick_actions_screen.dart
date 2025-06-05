import 'package:flutter/material.dart';

class QuickActionsScreen extends StatelessWidget {
  final Color textColor;
  final Color accentColor;
  final Color cardColor;
  final VoidCallback onAddMeal;
  final VoidCallback onAddWater;
  final VoidCallback onAddWorkout;

  const QuickActionsScreen({
    Key? key,
    required this.textColor,
    required this.accentColor,
    required this.cardColor,
    required this.onAddMeal,
    required this.onAddWater,
    required this.onAddWorkout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickActionButton(
                  icon: Icons.restaurant_outlined,
                  label: 'Add Meal',
                  onTap: onAddMeal,
                  width: MediaQuery.of(context).size.width * 0.25 - 10,
                  iconColor: Colors.orange
                ),
                _buildQuickActionButton(
                  icon: Icons.water_drop_outlined,
                  label: 'Add Water',
                  onTap: onAddWater,
                  width: MediaQuery.of(context).size.width * 0.25 - 10,
                  iconColor: Color(0xFF5cb5e1)
                ),
                _buildQuickActionButton(
                  icon: Icons.fitness_center_outlined,
                  label: 'Add Workout',
                  onTap: onAddWorkout,
                  width: MediaQuery.of(context).size.width * 0.25 - 10,
                  iconColor: Colors.green
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required double width,
    Color? iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 100,
        width: width,
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: iconColor,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
