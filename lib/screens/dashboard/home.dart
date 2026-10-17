import 'package:flutter/material.dart';
import 'package:field_survey/screens/profile/profile.dart';

class HomeScreen extends StatelessWidget {
  final String token;

  const HomeScreen({
    super.key,
    required this.token,
  });

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
          'Field Survey',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Notifikasi
            },
            icon: const Icon(
              Icons.notifications_outlined,
            ),
          ),
        ],
      ),

      // =========================
      // BODY
      // =========================
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =========================
            // GREETING
            // =========================
            const Text(
              'Halo, Selamat Datang 👋',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF263238),
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Kelola kegiatan survei lapangan kamu dengan mudah.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF78909C),
              ),
            ),

            const SizedBox(height: 25),

            // =========================
            // CARD MULAI SURVEY
            // =========================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D6B),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.assignment_outlined,
                      color: Colors.white,
                      size: 35,
                    ),
                  ),

                  const SizedBox(width: 15),

                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mulai Survey',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: 5),

                        Text(
                          'Buat dan lakukan survey lapangan baru.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // =========================
            // MENU UTAMA
            // =========================
            const Text(
              'Menu Utama',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF263238),
              ),
            ),

            const SizedBox(height: 15),

            // =========================
            // MENU GRID
            // =========================
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 1.1,
              children: [
                // =========================
                // SURVEY
                // =========================
                _menuCard(
                  icon: Icons.assignment_outlined,
                  title: 'Survey',
                  subtitle: 'Data survey',
                  onTap: () {
                    // TODO: Halaman Survey
                  },
                ),

                // =========================
                // SURVEY BARU
                // =========================
                _menuCard(
                  icon: Icons.add_location_alt_outlined,
                  title: 'Survey Baru',
                  subtitle: 'Buat survey',
                  onTap: () {
                    // TODO: Buat survey baru
                  },
                ),

                // =========================
                // RIWAYAT
                // =========================
                _menuCard(
                  icon: Icons.history,
                  title: 'Riwayat',
                  subtitle: 'Survey sebelumnya',
                  onTap: () {
                    // TODO: Halaman Riwayat
                  },
                ),

                // =========================
                // PROFIL
                // =========================
                _menuCard(
                  icon: Icons.person_outline,
                  title: 'Profil',
                  subtitle: 'Data akun',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileScreen(
                          token: token,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 30),

            // =========================
            // INFORMASI
            // =========================
            const Text(
              'Informasi',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF263238),
              ),
            ),

            const SizedBox(height: 15),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Color(0xFF2E7D6B),
                    size: 30,
                  ),

                  SizedBox(width: 15),

                  Expanded(
                    child: Text(
                      'Pastikan data survey yang kamu masukkan sudah sesuai dengan kondisi di lapangan.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF546E7A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // =========================
      // BOTTOM NAVIGATION
      // =========================
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: const Color(0xFF2E7D6B),
        unselectedItemColor: const Color(0xFF90A4AE),
        type: BottomNavigationBarType.fixed,

        onTap: (index) {
          if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileScreen(
                  token: token,
                ),
              ),
            );
          }
        },

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            label: 'Survey',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Riwayat',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  // =========================
  // MENU CARD
  // =========================
  Widget _menuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 38,
              color: const Color(0xFF2E7D6B),
            ),

            const SizedBox(height: 12),

            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF263238),
              ),
            ),

            const SizedBox(height: 4),

            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF90A4AE),
              ),
            ),
          ],
        ),
      ),
    );
  }
}