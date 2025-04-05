import 'package:flutter/material.dart';
import 'package:vita_drop/core/constants/colors.dart';
import 'package:vita_drop/screens/settings_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vita_drop/start_page.dart';

class MainDrawer extends StatefulWidget {
  final VoidCallback onSettingsUpdated;

  const MainDrawer({
    Key? key,
    required this.onSettingsUpdated,
  }) : super(key: key);

  @override
  State<MainDrawer> createState() => _MainDrawerState();
}

class _MainDrawerState extends State<MainDrawer> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  Map<String, dynamic>? userData;
  String? username;
  String? bmi;
  String? bmiType;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        setState(() {
          userData = doc.data();
          username = doc['username'] ?? 'User';
          bmi = (doc['bmi'] != null)
              ? double.tryParse(doc['bmi'].toString())?.toStringAsFixed(2) ??
                  '0.00'
              : '0.00';
          bmiType = _getBMICategory(double.tryParse(bmi ?? '0.00') ?? 0.0);
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    return Drawer(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [
                    AppColors.darBackgroundColor1,
                    AppColors.darBackgroundColor2,
                    AppColors.darBackgroundColor3,
                  ]
                : [
                    AppColors.backgroundColor1,
                    AppColors.backgroundColor2,
                    AppColors.backgroundColor3,
                  ],
          ),
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 180,
              padding: const EdgeInsets.only(
                  top: 50, left: 20, right: 20, bottom: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDarkMode
                      ? [
                          AppColors.darBackgroundColor1,
                          AppColors.darBackgroundColor2,
                          AppColors.darBackgroundColor3,
                        ]
                      : [
                          AppColors.backgroundColor1,
                          AppColors.backgroundColor2,
                          AppColors.backgroundColor3,
                        ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'VitaDrop',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode
                          ? AppColors.darkTextColor
                          : AppColors.textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your Health Companion',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode
                          ? AppColors.darkAccentColor
                          : AppColors.accentColor,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                children: [
                  if (userData != null) ...[
                    _buildProfileInfo(
                        'Height',
                        '${userData!['height'] ?? 'N/A'} cm',
                        Icons.height,
                        isDarkMode
                            ? AppColors.darkCardColor
                            : AppColors.cardColor,
                        isDarkMode
                            ? AppColors.darkTextColor
                            : AppColors.textColor),
                    const SizedBox(height: 8),
                    _buildProfileInfo(
                        'Weight',
                        '${userData!['weight'] ?? 'N/A'} kg',
                        Icons.monitor_weight,
                        isDarkMode
                            ? AppColors.darkCardColor
                            : AppColors.cardColor,
                        isDarkMode
                            ? AppColors.darkTextColor
                            : AppColors.textColor),
                    const SizedBox(height: 8),
                    _buildProfileInfo(
                        'BMI',
                        bmi ?? 'N/A',
                        Icons.calculate,
                        isDarkMode
                            ? AppColors.darkCardColor
                            : AppColors.cardColor,
                        isDarkMode
                            ? AppColors.darkTextColor
                            : AppColors.textColor),
                    const SizedBox(height: 8),
                    _buildProfileInfo(
                        'Gender',
                        userData!['gender'] ?? 'N/A',
                        Icons.person,
                        isDarkMode
                            ? AppColors.darkCardColor
                            : AppColors.cardColor,
                        isDarkMode
                            ? AppColors.darkTextColor
                            : AppColors.textColor),
                    const SizedBox(height: 8),
                    _buildProfileInfo(
                        'Age',
                        '${userData!['age'] ?? 'N/A'} years',
                        Icons.cake,
                        isDarkMode
                            ? AppColors.darkCardColor
                            : AppColors.cardColor,
                        isDarkMode
                            ? AppColors.darkTextColor
                            : AppColors.textColor),
                  ],
                  const SizedBox(height: 20),
                  _buildMenuItem(
                    context,
                    Icons.settings,
                    'Settings',
                    isDarkMode ? AppColors.darkCardColor : AppColors.cardColor,
                    isDarkMode ? AppColors.darkTextColor : AppColors.textColor,
                    () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SettingsScreen(
                            onSettingsUpdated: widget.onSettingsUpdated,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    Icons.help_outline,
                    'Help & Support',
                    isDarkMode ? AppColors.darkCardColor : AppColors.cardColor,
                    isDarkMode ? AppColors.darkTextColor : AppColors.textColor,
                    () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white24),
            Padding(
              padding: const EdgeInsets.only(bottom: 7.0),
              child: _buildMenuItem(
                  context,
                  Icons.logout,
                  'Logout',
                  isDarkMode ? AppColors.darkCardColor : AppColors.cardColor,
                  isDarkMode ? AppColors.darkTextColor : AppColors.textColor,
                  () {
                Navigator.pop(context);
                setState(() {
                  FirebaseAuth.instance.signOut();
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Startpage(),
                      ));
                });
              }, isLogout: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfo(String label, String value, IconData icon,
      Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: textColor, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String title,
    Color cardColor,
    Color textColor,
    VoidCallback onTap, {
    bool isLogout = false,
  }) {
    return Container(
      width: double.infinity,
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: isLogout
              ? [Colors.red.shade700, Colors.red.shade900]
              : [
                  Colors.transparent,
                  Colors.transparent,
                ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: isLogout
            ? [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8.0,
                  offset: Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Center(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          leading: Container(
            width: 40,
            height: 40,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isLogout ? Colors.red.shade800 : cardColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isLogout ? Colors.white : textColor,
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              color: isLogout ? Colors.white : textColor,
              fontSize: 16,
            ),
          ),
          onTap: onTap,
        ),
      ),
    );
  }

  String _getBMICategory(double bmi) {
    if (bmi < 18.5) {
      return 'Underweight';
    } else if (bmi >= 18.5 && bmi < 24.9) {
      return 'Normal weight';
    } else if (bmi >= 25 && bmi < 29.9) {
      return 'Overweight';
    } else {
      return 'Obesity';
    }
  }
}
