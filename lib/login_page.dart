import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:vita_drop/quiz_screen.dart';
import 'package:vita_drop/screens/dashboard/home_screen.dart';
import 'package:vita_drop/signup_page.dart';

import 'core/constants/colors.dart';

final _firebase = FirebaseAuth.instance;
final _googleSignIn = GoogleSignIn();

class LogInPage extends StatefulWidget {
  final int initialPage;

  const LogInPage({super.key, this.initialPage = 0});

  @override
  State<LogInPage> createState() => _LogInPageState();
}

class _LogInPageState extends State<LogInPage> {
  late final PageController _pageController;

  bool _obscurePassword = true;

  var _enteredEmail = '';
  var _enteredPassword = '';
  final _form = GlobalKey<FormState>();
  var _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _submit() async {
    final isValid = _form.currentState!.validate();
    if (!isValid) {
      //show error
      return;
    }
    _form.currentState!.save();
    try {
      setState(() {
        _isAuthenticating = true;
      });

      final userCredentials = await _firebase.signInWithEmailAndPassword(
        email: _enteredEmail,
        password: _enteredPassword,
      );
      print(userCredentials);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(),
        ),
      );
    } on FirebaseAuthException catch (error) {
      _showAuthError(error.message ?? 'Authentication failed');
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      setState(() {
        _isAuthenticating = true;
      });

      // Begin the Google sign-in process
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the sign-in process
        setState(() {
          _isAuthenticating = false;
        });
        return;
      }

      // Obtain the auth details from the Google sign-in
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a credential with the Google tokens
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _firebase.signInWithCredential(credential);
      final user = userCredential.user!;

      final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

      final googleDisplayName = user.displayName;
      final googleDisplayEmail = user.email;
      print('Google Sign-In: ${userCredential.user?.displayName}');
      print('Is new user: $isNewUser');

      if (isNewUser) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'username': googleDisplayName,
          'email': googleDisplayEmail,
          'createdAt': FieldValue.serverTimestamp(),
        });
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => QuizScreen(),
          ),
        );
      } else {
        // Navigate to home screen after successful sign-in
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(),
          ),
        );
      }
      print('Google Sign-In: ${userCredential.user?.displayName}');
    } catch (error) {
      _showAuthError('Google sign-in failed. Please try again.');
      print('Google sign-in error: $error');
    }
  }

  void _showAuthError(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
    setState(() {
      _isAuthenticating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    return Scaffold(
        body: Container(
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
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Center(
            child: Form(
              key: _form,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 64),
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                            image: AssetImage('assets/images/icon.png'),
                            fit: BoxFit.scaleDown),
                      ),
                    ),
                    const SizedBox(height: 48),
                    TextFormField(
                      style: TextStyle(
                        color: isDarkMode
                            ? AppColors.darkTextColor
                            : AppColors.textColor,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: TextStyle(
                          color: isDarkMode
                              ? AppColors.darkTextColor
                              : AppColors.textColor,
                        ),
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: isDarkMode
                              ? AppColors.darkTextColor
                              : AppColors.textColor,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: isDarkMode
                            ? AppColors.darkCardColor
                            : AppColors.cardColor,
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty ||
                            !value.contains('@')) {
                          return 'Please enter a valid email address.';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _enteredEmail = value!;
                      },
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      style: TextStyle(
                        color: isDarkMode
                            ? AppColors.darkTextColor
                            : AppColors.textColor,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: TextStyle(
                          color: isDarkMode
                              ? AppColors.darkTextColor
                              : AppColors.textColor,
                        ),
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: isDarkMode
                              ? AppColors.darkTextColor
                              : AppColors.textColor,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: isDarkMode
                                ? AppColors.darkTextColor
                                : AppColors.textColor,
                          ),
                          onPressed: _togglePasswordVisibility,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: isDarkMode
                            ? AppColors.darkCardColor
                            : AppColors.cardColor,
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            value.trim().length < 4) {
                          return 'Please enter a valid password.';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _enteredPassword = value!;
                      },
                      obscureText: _obscurePassword,
                      keyboardType: TextInputType.text,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _isAuthenticating ? null : _submit,
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
                      child: _isAuthenticating
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: isDarkMode
                                    ? AppColors.darkAccentColor
                                    : AppColors.accentColor,
                              ),
                            )
                          : Text(
                              'Sign In',
                              style: TextStyle(
                                color: isDarkMode
                                    ? AppColors.darkAccentColor
                                    : AppColors.accentColor,
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),
                    // Google Sign-In Button
                    OutlinedButton.icon(
                      onPressed: _isAuthenticating ? null : _signInWithGoogle,
                      icon: Image.asset(
                        'assets/images/google.png',
                        height: 30,
                        width: 30,
                      ),
                      label: Text(
                        'Sign in with Google',
                        style: TextStyle(
                          color: isDarkMode
                              ? AppColors.darkTextColor
                              : AppColors.textColor,
                          fontSize: 16,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(
                          color: isDarkMode
                              ? AppColors.darkTextColor.withOpacity(0.3)
                              : AppColors.textColor.withOpacity(0.3),
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _isAuthenticating
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const SignUpPage()),
                              );
                            },
                      child: Text(
                        'Don\'t have an account? Sign Up',
                        style: TextStyle(
                          color: isDarkMode
                              ? AppColors.darkTextColor
                              : AppColors.textColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ));
  }
}
