import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:field_survey/screens/survey/survey_screen.dart';
import 'package:field_survey/screens/profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final String token;

  const HomeScreen({super.key, required this.token});

  static const Color primaryColor = Color(0xFFD4D4D8);
  static const Color backgroundColor = Color(0xFF000000);
  static const Color cardColor = Color(0xFF171717);
  static const Color borderColor = Color(0xFF333333);
  static const Color textColor = Color(0xFFFFFFFF);
  static const Color subtitleColor = Color(0xFF9CA3AF);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;

  List<dynamic> surveys = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchSurveys();
  }

  // ============================================================
  // MENGAMBIL DATA SURVEY DARI API
  // ============================================================

  Future<void> fetchSurveys() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('https://sijala.biz.id/api/v1/surveys'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List<dynamic> result = [];

        if (decoded is List) {
          result = decoded;
        } else if (decoded is Map) {
          final data = decoded['data'];

          if (data is List) {
            result = data;
          } else if (data is Map && data['data'] is List) {
            result = data['data'] as List;
          } else {
            throw Exception('Format data survey tidak sesuai.');
          }
        } else {
          throw Exception('Format respons API tidak dikenali.');
        }

        if (!mounted) return;

        setState(() {
          surveys = result;
          isLoading = false;
        });
      } else {
        if (!mounted) return;

        setState(() {
          isLoading = false;
          errorMessage = response.statusCode == 401
              ? 'Sesi login berakhir. Silakan login kembali.'
              : 'Gagal mengambil data survey (${response.statusCode}).';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = 'Tidak dapat terhubung ke server.';
      });
    }
  }

  // ============================================================
  // MENGAMBIL NAMA KATEGORI DARI DATA API
  // ============================================================

  String getCategory(dynamic survey) {
    if (survey is! Map) return 'Lainnya';

    final value = survey['category'] ??
        survey['kategori'] ??
        survey['category_name'] ??
        survey['nama_kategori'];

    if (value is Map) {
      final name = value['name'] ??
          value['nama'] ??
          value['title'];

      if (name != null && name.toString().trim().isNotEmpty) {
        return name.toString().trim();
      }

      return 'Lainnya';
    }

    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString().trim();
    }

    return 'Lainnya';
  }

  // JUMLAH KATEGORI UNIK
  int get totalCategories {
    final categories = surveys
        .map(getCategory)
        .where((category) => category != 'Lainnya')
        .toSet();

    return categories.length;
  }

  // ============================================================
  // NAVIGASI
  // ============================================================

  void changeTab(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomeContent(),
      const SurveyScreen(),
      ProfileScreen(token: widget.token),
    ];

    return Scaffold(
      backgroundColor: HomeScreen.backgroundColor,

      appBar: AppBar(
        backgroundColor: HomeScreen.backgroundColor,
        foregroundColor: HomeScreen.textColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            const Icon(
              Icons.location_on_rounded,
              color: HomeScreen.primaryColor,
              size: 25,
            ),
            const SizedBox(width: 8),
            Text(
              selectedIndex == 0
                  ? 'Field Survey'
                  : selectedIndex == 1
                      ? 'Daftar Survey'
                      : 'Profil Saya',
              style: const TextStyle(
                color: HomeScreen.textColor,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: fetchSurveys,
            tooltip: 'Muat ulang data',
            icon: const Icon(
              Icons.refresh_rounded,
              color: HomeScreen.textColor,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: IndexedStack(
        index: selectedIndex,
        children: pages,
      ),

      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: HomeScreen.backgroundColor,
          border: Border(
            top: BorderSide(
              color: HomeScreen.borderColor,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: selectedIndex,
          backgroundColor: HomeScreen.backgroundColor,
          elevation: 0,
          selectedItemColor: HomeScreen.primaryColor,
          unselectedItemColor: HomeScreen.subtitleColor,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
          type: BottomNavigationBarType.fixed,
          onTap: changeTab,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              activeIcon: Icon(Icons.assignment_rounded),
              label: 'Survey',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // KONTEN HOME
  // ============================================================

  Widget _buildHomeContent() {
    return RefreshIndicator(
      onRefresh: fetchSurveys,
      color: HomeScreen.primaryColor,
      backgroundColor: HomeScreen.cardColor,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Halo, Selamat Datang 👋',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
              color: HomeScreen.textColor,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Kelola kegiatan survei lapangan dengan mudah.',
            style: TextStyle(
              fontSize: 14,
              color: HomeScreen.subtitleColor,
            ),
          ),

          const SizedBox(height: 25),

          // RINGKASAN SURVEY
          _buildSectionTitle('Ringkasan Survey'),

          const SizedBox(height: 12),

          // DUA KARTU: TOTAL SURVEY DAN KATEGORI
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Total Survey',
                  value: isLoading ? '...' : '${surveys.length}',
                  subtitle: 'Data survey',
                  icon: Icons.assignment_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Kategori',
                  value: isLoading ? '...' : '$totalCategories',
                  subtitle: 'Jenis kategori',
                  icon: Icons.category_rounded,
                ),
              ),
            ],
          ),

          // ERROR API
          if (errorMessage != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: _cardDecoration(),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: HomeScreen.subtitleColor,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      errorMessage!,
                      style: const TextStyle(
                        color: HomeScreen.subtitleColor,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: fetchSurveys,
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: HomeScreen.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 25),

          // MENU UTAMA
          _buildSectionTitle('Menu Utama'),

          const SizedBox(height: 12),

          _buildMenuCard(
            title: 'Data Survey',
            subtitle: 'Lihat dan kelola data survei lapangan.',
            icon: Icons.assignment_outlined,
            onTap: () => changeTab(1),
          ),

          const SizedBox(height: 14),

          _buildMenuCard(
            title: 'Profil Saya',
            subtitle: 'Lihat dan kelola informasi akun.',
            icon: Icons.person_outline_rounded,
            onTap: () => changeTab(2),
          ),

          const SizedBox(height: 25),

          // INFORMASI
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration(),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: HomeScreen.primaryColor,
                  size: 23,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informasi',
                        style: TextStyle(
                          color: HomeScreen.textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Pastikan data, lokasi, dan foto survey '
                        'sesuai dengan kondisi sebenarnya.',
                        style: TextStyle(
                          color: HomeScreen.subtitleColor,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ============================================================
  // JUDUL BAGIAN
  // ============================================================

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: HomeScreen.textColor,
        fontSize: 17,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  // ============================================================
  // KARTU STATISTIK
  // ============================================================

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF262626),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: HomeScreen.primaryColor,
              size: 23,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            title,
            style: const TextStyle(
              color: HomeScreen.subtitleColor,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            value,
            style: const TextStyle(
              color: HomeScreen.textColor,
              fontSize: 27,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            subtitle,
            style: const TextStyle(
              color: HomeScreen.subtitleColor,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MENU CARD
  // ============================================================

  Widget _buildMenuCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: HomeScreen.cardColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: HomeScreen.borderColor,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFF262626),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: HomeScreen.primaryColor,
                  size: 24,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: HomeScreen.textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: HomeScreen.subtitleColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.chevron_right_rounded,
                color: HomeScreen.subtitleColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DEKORASI KARTU
  // ============================================================

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: HomeScreen.cardColor,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: HomeScreen.borderColor,
      ),
    );
  }
}