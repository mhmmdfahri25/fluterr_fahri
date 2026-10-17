import 'dart:convert';

import 'package:field_survey/screens/auth/register.dart';
import 'package:field_survey/screens/dashboard/home.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;

  static const Color primaryColor = Color(0xFFD4D4D8);
  static const Color secondaryColor = Color(0xFF9CA3AF);
  static const Color backgroundColor = Color(0xFF000000);
  static const Color cardColor = Color(0xFF171717);
  static const Color inputColor = Color(0xFF202020);
  static const Color borderColor = Color(0xFF333333);
  static const Color textColor = Color(0xFFFFFFFF);
  static const Color secondaryTextColor = Color(0xFF9CA3AF);

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // PROSES LOGIN API
  Future<void> login() async {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.isEmpty) {
      showMessage('Email dan password wajib diisi.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://sijala.biz.id/api/v1/login'),
        headers: {
          'Accept': 'application/json',
        },
        body: {
          'email': emailController.text.trim(),
          'password': passwordController.text,
        },
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200 && data['status'] == true) {
        final token = data['data']?['token'];

        if (token == null || token.toString().isEmpty) {
          showMessage('Token login tidak ditemukan.');
          return;
        }

        final prefs = await SharedPreferences.getInstance();

        await prefs.setString('token', token.toString());
        await prefs.setString(
          'user',
          jsonEncode(data['data']?['user'] ?? {}),
        );

        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              token: token.toString(),
            ),
          ),
          (route) => false,
        );
      } else {
        showMessage(
          data['message']?.toString() ??
              'Login gagal. Periksa email dan password.',
        );
      }
    } catch (e) {
      if (!mounted) return;

      showMessage(
        'Tidak dapat terhubung ke server. Periksa koneksi internet.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // NOTIFIKASI
  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: cardColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // DESAIN INPUT
  InputDecoration inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: secondaryTextColor,
        fontSize: 14,
      ),
      prefixIcon: Icon(
        icon,
        color: secondaryColor,
        size: 21,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: inputColor,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: borderColor,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: borderColor,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: primaryColor,
          width: 1.3,
        ),
      ),
    );
  }

  // LABEL INPUT
  Widget buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          color: textColor,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // HEADER
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 30,
                          bottom: 30,
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 84,
                              height: 84,
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: borderColor,
                                ),
                              ),
                              child: const Icon(
                                Icons.map_rounded,
                                color: primaryColor,
                                size: 43,
                              ),
                            ),

                            const SizedBox(height: 22),

                            const Text(
                              'Field Survey',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 27,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 8),

                            const Text(
                              'Masuk untuk melanjutkan aktivitas survei',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: secondaryTextColor,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // KARTU FORM FULL WIDTH
                      Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 20,
                        ),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: borderColor,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Masuk ke Akun',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 23,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 8),

                            const Text(
                              'Masukkan email dan password kamu '
                              'untuk melanjutkan.',
                              style: TextStyle(
                                color: secondaryTextColor,
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),

                            const SizedBox(height: 26),

                            // EMAIL
                            buildLabel('Email'),

                            TextField(
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autocorrect: false,
                              style: const TextStyle(
                                color: textColor,
                                fontSize: 14,
                              ),
                              decoration: inputDecoration(
                                hint: 'Masukkan alamat email',
                                icon: Icons.mail_outline_rounded,
                              ),
                            ),

                            const SizedBox(height: 22),

                            // PASSWORD
                            buildLabel('Password'),

                            TextField(
                              controller: passwordController,
                              obscureText: obscurePassword,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) {
                                if (!isLoading) login();
                              },
                              style: const TextStyle(
                                color: textColor,
                                fontSize: 14,
                              ),
                              decoration: inputDecoration(
                                hint: 'Masukkan password',
                                icon: Icons.lock_outline_rounded,
                                suffixIcon: IconButton(
                                  tooltip: obscurePassword
                                      ? 'Tampilkan password'
                                      : 'Sembunyikan password',
                                  onPressed: () {
                                    setState(() {
                                      obscurePassword = !obscurePassword;
                                    });
                                  },
                                  icon: Icon(
                                    obscurePassword
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                    color: secondaryColor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),

                      // TOMBOL LOGIN FULL WIDTH
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                        ),
                        child: SizedBox(
                          height: 54,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: backgroundColor,
                              disabledBackgroundColor:
                                  const Color(0xFF77777A),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(
                                milliseconds: 200,
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      key: ValueKey('loading'),
                                      width: 23,
                                      height: 23,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          backgroundColor,
                                        ),
                                      ),
                                    )
                                  : const Row(
                                      key: ValueKey('login'),
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.login_rounded,
                                          size: 20,
                                        ),
                                        SizedBox(width: 10),
                                        Text(
                                          'Masuk Sekarang',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      // PEMBATAS
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Divider(
                                color: borderColor,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              child: Text(
                                'ATAU',
                                style: TextStyle(
                                  color: secondaryTextColor,
                                  fontSize: 11,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            const Expanded(
                              child: Divider(
                                color: borderColor,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // LINK REGISTER
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Flexible(
                            child: Text(
                              'Belum punya akun?',
                              style: TextStyle(
                                color: secondaryTextColor,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: isLoading
                                ? null
                                : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const RegisterScreen(),
                                      ),
                                    );
                                  },
                            style: TextButton.styleFrom(
                              foregroundColor: primaryColor,
                            ),
                            child: const Text(
                              'Daftar',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const Spacer(),

                      // FOOTER
                      const Padding(
                        padding: EdgeInsets.only(
                          top: 20,
                          bottom: 20,
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Icon(
                                //   Icons.shield_outlined,
                                //   color: secondaryTextColor,
                                //   size: 16,
                                // ),
                                // SizedBox(width: 7),
                                // Text(
                                //   'Akses akun dengan aman',
                                //   style: TextStyle(
                                //     color: secondaryTextColor,
                                //     fontSize: 12,
                                //   ),
                                // ),
                              ],
                            ),
                            // SizedBox(height: 12),
                            // Text(
                            //   'FIELD SURVEY APPLICATION',
                            //   textAlign: TextAlign.center,
                            //   style: TextStyle(
                            //     color: Color(0xFF525252),
                            //     fontSize: 10,
                            //     letterSpacing: 2,
                            //   ),
                            // ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}