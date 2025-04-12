import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:vita_drop/core/constants/colors.dart';
import 'package:vita_drop/screens/settings_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vita_drop/start_page.dart';

final _googleSignIn = GoogleSignIn();

class MainDrawer extends StatefulWidget {
  final VoidCallback onSettingsUpdated;

  const MainDrawer({
    Key? key,
    required this.onSettingsUpdated,
  }) : super(key: key);

  @override
  State<MainDrawer> createState() => _MainDrawerState();
}

class _MainDrawerState extends State<MainDrawer> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  Map<String, dynamic>? userData;
  String? username;
  String? bmi;
  String? bmiType;

  // Animation controller
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Staggered animations for menu items
  final List<Animation<Offset>> _itemAnimations = [];

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Setup fade animation for header
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    // Setup slide animation for header
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-0.3, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));

    // Create staggered animations for each menu item
    final int totalItems = 7; // 5 profile info items + settings + logout
    for (int i = 0; i < totalItems; i++) {
      final begin = 0.2 + (i * 0.05); // Stagger start times
      final end = begin + 0.2;

      _itemAnimations.add(
          Tween<Offset>(
            begin: const Offset(0.5, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _animationController,
            curve: Interval(begin, end, curve: Curves.easeOut),
          ))
      );
    }

    // Play animation when drawer opens
    _animationController.forward();

    _fetchUserData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && mounted) {
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
            // Animated Header
            SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
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
              ),
            ),
            Expanded(
              child: ListView(
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                children: [
                  if (userData != null) ...[
                    _buildAnimatedProfileInfo(
                        'Height',
                        '${userData!['height'] ?? 'N/A'} cm',
                        Icons.height,
                        isDarkMode
                            ? AppColors.darkCardColor
                            : AppColors.cardColor,
                        isDarkMode
                            ? AppColors.darkTextColor
                            : AppColors.textColor,
                        0),
                    const SizedBox(height: 8),
                    _buildAnimatedProfileInfo(
                        'Weight',
                        '${userData!['weight'] ?? 'N/A'} kg',
                        Icons.monitor_weight,
                        isDarkMode
                            ? AppColors.darkCardColor
                            : AppColors.cardColor,
                        isDarkMode
                            ? AppColors.darkTextColor
                            : AppColors.textColor,
                        1),
                    const SizedBox(height: 8),
                    _buildAnimatedProfileInfo(
                        'BMI',
                        bmi ?? 'N/A',
                        Icons.calculate,
                        isDarkMode
                            ? AppColors.darkCardColor
                            : AppColors.cardColor,
                        isDarkMode
                            ? AppColors.darkTextColor
                            : AppColors.textColor,
                        2),
                    const SizedBox(height: 8),
                    _buildAnimatedProfileInfo(
                        'Gender',
                        userData!['gender'] ?? 'N/A',
                        Icons.person,
                        isDarkMode
                            ? AppColors.darkCardColor
                            : AppColors.cardColor,
                        isDarkMode
                            ? AppColors.darkTextColor
                            : AppColors.textColor,
                        3),
                    const SizedBox(height: 8),
                    _buildAnimatedProfileInfo(
                        'Age',
                        '${userData!['age'] ?? 'N/A'} years',
                        Icons.cake,
                        isDarkMode
                            ? AppColors.darkCardColor
                            : AppColors.cardColor,
                        isDarkMode
                            ? AppColors.darkTextColor
                            : AppColors.textColor,
                        4),
                  ],
                  const SizedBox(height: 20),
                  _buildAnimatedMenuItem(
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
                    5,
                    isLogout: false,
                  ),
                  _buildAnimatedMenuItem(
                    context,
                    Icons.help_outline,
                    'Help & Support',
                    isDarkMode ? AppColors.darkCardColor : AppColors.cardColor,
                    isDarkMode ? AppColors.darkTextColor : AppColors.textColor,
                        () => Navigator.pop(context),
                    6,
                    isLogout: false,
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
                  setState(() async {
                    await _googleSignIn.signOut();
                    await FirebaseAuth.instance.signOut();
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Startpage(),
                        ));
                  });
                },
                isLogout: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedProfileInfo(String label, String value, IconData icon,
      Color cardColor, Color textColor, int index) {
    // Check if index is within bounds
    if (index >= _itemAnimations.length) {
      return _buildProfileInfo(label, value, icon, cardColor, textColor);
    }

    return SlideTransition(
      position: _itemAnimations[index],
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: _buildProfileInfo(label, value, icon, cardColor, textColor),
      ),
    );
  }

  Widget _buildAnimatedMenuItem(
      BuildContext context,
      IconData icon,
      String title,
      Color cardColor,
      Color textColor,
      VoidCallback onTap,
      int index, {
        required bool isLogout,
      }) {
    // Check if index is within bounds
    if (index >= _itemAnimations.length) {
      return _buildMenuItem(
        context,
        icon,
        title,
        cardColor,
        textColor,
        onTap,
        isLogout: isLogout,
      );
    }

    return SlideTransition(
      position: _itemAnimations[index],
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: _buildMenuItem(
          context,
          icon,
          title,
          cardColor,
          textColor,
          onTap,
          isLogout: isLogout,
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
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
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
    return GestureDetector(
      onTap: () {
        // Add haptic feedback
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
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
              offset: const Offset(0, 4),
            ),
          ]
              : null,
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Container(
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
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: isLogout ? Colors.white : textColor,
                fontSize: 16,
              ),
            ),
          ],
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