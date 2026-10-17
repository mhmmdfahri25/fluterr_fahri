import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ProfileScreen extends StatefulWidget {
  final String token;

  const ProfileScreen({
    super.key,
    required this.token,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isLoading = true;

  String name = '';
  String username = '';
  String email = '';
  String phone = '';
  String gender = '';
  String photo = '';
  String birthPlace = '';
  String birthDate = '';

  @override
  void initState() {
    super.initState();
    getProfile();
  }

  Future<void> getProfile() async {
    try {
      final response = await http.get(
        Uri.parse('https://sijala.biz.id/api/v1/profile'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (!mounted) return;

      print('STATUS CODE: ${response.statusCode}');
      print('RESPONSE: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final profile = data['data'];

        setState(() {
          name = profile['name']?.toString() ?? '';
          username = profile['username']?.toString() ?? '';
          email = profile['email']?.toString() ?? '';
          phone = profile['phone']?.toString() ?? '';
          gender = profile['gender']?.toString() ?? '';
          photo = profile['photo']?.toString() ?? '';
          birthPlace = profile['birth_place']?.toString() ?? '';
          birthDate = profile['birth_date']?.toString() ?? '';

          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal mengambil profil. Status: ${response.statusCode}',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Terjadi kesalahan: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),

      // =========================
      // APP BAR
      // =========================
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D6B),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Profil',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // =========================
      // BODY
      // =========================
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2E7D6B),
              ),
            )
          : RefreshIndicator(
              color: const Color(0xFF2E7D6B),
              onRefresh: getProfile,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // =========================
                    // FOTO PROFIL
                    // =========================
                    Container(
                      width: 120,
                      height: 120,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE0F2EF),
                        shape: BoxShape.circle,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: photo.isNotEmpty
                          ? Image.network(
                              photo,
                              fit: BoxFit.cover,
                              errorBuilder: (
                                context,
                                error,
                                stackTrace,
                              ) {
                                return const Icon(
                                  Icons.person,
                                  size: 70,
                                  color: Color(0xFF2E7D6B),
                                );
                              },
                            )
                          : const Icon(
                              Icons.person,
                              size: 70,
                              color: Color(0xFF2E7D6B),
                            ),
                    ),

                    const SizedBox(height: 15),

                    // =========================
                    // NAMA
                    // =========================
                    Text(
                      name.isNotEmpty ? name : '-',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF263238),
                      ),
                    ),

                    const SizedBox(height: 5),

                    // =========================
                    // USERNAME
                    // =========================
                    Text(
                      username.isNotEmpty ? '@$username' : '-',
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF78909C),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // =========================
                    // INFORMASI AKUN
                    // =========================
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Informasi Akun',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF263238),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // NAMA
                          _profileItem(
                            icon: Icons.person_outline,
                            title: 'Nama',
                            value: name,
                          ),

                          const Divider(height: 30),

                          // USERNAME
                          _profileItem(
                            icon: Icons.account_circle_outlined,
                            title: 'Username',
                            value: username,
                          ),

                          const Divider(height: 30),

                          // EMAIL
                          _profileItem(
                            icon: Icons.email_outlined,
                            title: 'Email',
                            value: email,
                          ),

                          const Divider(height: 30),

                          // NOMOR TELEPON
                          _profileItem(
                            icon: Icons.phone_outlined,
                            title: 'Nomor Telepon',
                            value: phone,
                          ),

                          const Divider(height: 30),

                          // JENIS KELAMIN
                          _profileItem(
                            icon: Icons.wc_outlined,
                            title: 'Jenis Kelamin',
                            value: gender,
                          ),

                          const Divider(height: 30),

                          // TEMPAT LAHIR
                          _profileItem(
                            icon: Icons.location_on_outlined,
                            title: 'Tempat Lahir',
                            value: birthPlace,
                          ),

                          const Divider(height: 30),

                          // TANGGAL LAHIR
                          _profileItem(
                            icon: Icons.calendar_today_outlined,
                            title: 'Tanggal Lahir',
                            value: birthDate,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // =========================
                    // TOMBOL LOGOUT
                    // =========================
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Logout
                        },
                        icon: const Icon(
                          Icons.logout,
                        ),
                        label: const Text(
                          'Logout',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  // =========================
  // PROFILE ITEM
  // =========================
  Widget _profileItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: const Color(0xFFE0F2EF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF2E7D6B),
          ),
        ),

        const SizedBox(width: 15),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF90A4AE),
                ),
              ),

              const SizedBox(height: 4),

              Text(
                value.isNotEmpty ? value : '-',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF263238),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}