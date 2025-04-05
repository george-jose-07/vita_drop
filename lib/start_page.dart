import 'package:flutter/material.dart';
import 'package:vita_drop/login_page.dart';

import 'core/constants/colors.dart';

class Startpage extends StatelessWidget {
  const Startpage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDarkMode
              ? [
            AppColors.darBackgroundColor1,
            AppColors.darBackgroundColor2,
            AppColors.darBackgroundColor3
          ]
              : [
            AppColors.backgroundColor1,
            AppColors.backgroundColor2,
            AppColors.backgroundColor3
          ],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.spa,
                size: 140,
                color: isDarkMode ? AppColors.darkTextColor : AppColors.textColor,
              ),
              const SizedBox(height: 48),
              Text(
                'Welcome to LiveWell',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: isDarkMode
                      ? AppColors.darkTextColor
                      : AppColors.textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 36,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Your journey to a healthier lifestyle starts here.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: isDarkMode
                        ? AppColors.darkAccentColor
                        : AppColors.accentColor,
                    fontSize: 18,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 64),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LogInPage()
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode
                      ? AppColors.darkCardColor
                      : AppColors.cardColor,
                  foregroundColor: isDarkMode
                      ? AppColors.darkAccentColor
                      : AppColors.accentColor,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 48, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  textStyle: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode
                        ? AppColors.darkTextColor
                        : AppColors.textColor,
                  ),
                ),
                child:Text(
                  'Start Your Journey',
                  style: TextStyle(
                    color: isDarkMode
                        ? AppColors.darkAccentColor
                        : AppColors.accentColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
