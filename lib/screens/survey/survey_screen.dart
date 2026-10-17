
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'survey_detail_page.dart';
import 'survey_form_page.dart';

class SurveyScreen extends StatefulWidget {
  const SurveyScreen({super.key});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  // ============================================================
  // API
  // ============================================================

  static const String apiUrl =
      'https://sijala.biz.id/api/v1/surveys';

  // ============================================================
  // WARNA OLED BLACK
  // ============================================================

  static const Color primaryColor = Color(0xFFD4D4D8);
  static const Color backgroundColor = Color(0xFF000000);
  static const Color cardColor = Color(0xFF171717);
  static const Color surfaceColor = Color(0xFF202020);
  static const Color borderColor = Color(0xFF333333);
  static const Color textColor = Color(0xFFFFFFFF);
  static const Color subtitleColor = Color(0xFF9CA3AF);

  // ============================================================
  // STATE
  // ============================================================

  List<Map<String, dynamic>> surveys = [];

  bool isLoading = true;

  String? errorMessage;

  // ============================================================
  // INIT STATE
  // ============================================================

  @override
  void initState() {
    super.initState();
    fetchSurveys();
  }

  // ============================================================
  // AMBIL DATA SURVEY
  // ============================================================

  Future<void> fetchSurveys() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      if (token.isEmpty) {
        throw Exception(
          'Token tidak ditemukan. Silakan login kembali.',
        );
      }

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('================================');
      debugPrint('GET SURVEYS');
      debugPrint('STATUS: ${response.statusCode}');
      debugPrint('BODY: ${response.body}');
      debugPrint('================================');

      if (response.statusCode == 401) {
        await prefs.remove('token');
        await prefs.remove('user');

        throw Exception('Sesi login telah berakhir.');
      }

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);

        List<dynamic> rawData = [];

        if (data is Map &&
            data['status'] == true &&
            data['data'] is List) {
          rawData = data['data'];
        } else if (data is List) {
          rawData = data;
        }

        if (!mounted) return;

        setState(() {
          surveys = rawData
              .whereType<Map>()
              .map(
                (item) => Map<String, dynamic>.from(item),
              )
              .toList();

          isLoading = false;
        });

        debugPrint('TOTAL DATA SURVEY: ${surveys.length}');
        return;
      }

      throw Exception(
        'Gagal mengambil data survey. Kode: ${response.statusCode}',
      );
    } catch (e) {
      debugPrint('ERROR GET SURVEY: $e');

      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e
            .toString()
            .replaceFirst('Exception: ', '');
      });
    }
  }

  // ============================================================
  // TAMBAH SURVEY
  // ============================================================

  Future<void> openAddSurvey() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SurveyFormPage(),
      ),
    );

    if (result == true && mounted) {
      fetchSurveys();
    }
  }

  // ============================================================
  // BUKA DETAIL SURVEY
  // ============================================================

  Future<void> openDetail(int surveyId) async {
    if (surveyId <= 0) {
      showMessage(
        'ID survey tidak valid.',
        Colors.red,
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SurveyDetailPage(surveyId: surveyId),
      ),
    );

    if (result == true && mounted) {
      fetchSurveys();
    }
  }

  // ============================================================
  // FORMAT TANGGAL
  // ============================================================

  String formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return '-';
    }

    try {
      final date = DateTime.parse(
        dateString.replaceFirst(' ', 'T'),
      );

      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  // ============================================================
  // PESAN
  // ============================================================

  void showMessage(String message, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: textColor),
        ),
        backgroundColor: cardColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

      // ========================================================
      // APPBAR
      // ========================================================

      appBar: AppBar(
        title: const Text(
          'Daftar Survey',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: RefreshIndicator(
        color: primaryColor,
        backgroundColor: cardColor,
        onRefresh: fetchSurveys,
        child: buildBody(),
      ),

      // ========================================================
      // BUTTON TAMBAH
      // ========================================================

      floatingActionButton: FloatingActionButton.extended(
        onPressed: openAddSurvey,
        backgroundColor: primaryColor,
        foregroundColor: backgroundColor,
        elevation: 0,
        icon: const Icon(Icons.add),
        label: const Text(
          'Tambah Survey',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD BODY
  // ============================================================

  Widget buildBody() {
    // ==========================================================
    // LOADING
    // ==========================================================

    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: primaryColor,
            ),
            SizedBox(height: 16),
            Text(
              'Memuat data survey...',
              style: TextStyle(color: subtitleColor),
            ),
          ],
        ),
      );
    }

    // ==========================================================
    // ERROR
    // ==========================================================

    if (errorMessage != null && surveys.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.wifi_off_rounded,
                      size: 70,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Gagal Memuat Data',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: subtitleColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: fetchSurveys,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: backgroundColor,
                      ),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    // ==========================================================
    // DATA KOSONG
    // ==========================================================

    if (surveys.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.folder_open_rounded,
                      size: 70,
                      color: subtitleColor,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Belum Ada Data Survey',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tekan tombol di bawah untuk menambah survey.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: subtitleColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: openAddSurvey,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: backgroundColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Tambah Survey'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    // ==========================================================
    // LIST SURVEY
    // ==========================================================

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: surveys.length,
      itemBuilder: (context, index) {
        final survey = surveys[index];

        // ======================================================
        // DATA API
        // ======================================================

        final int id =
            int.tryParse(survey['id']?.toString() ?? '') ?? 0;

        final String title =
            survey['title']?.toString() ?? 'Tanpa Judul';

        final String description =
            survey['description']?.toString() ?? '';

        final String categoryName =
            survey['category_name']?.toString() ??
                'Tanpa Kategori';

        final String latitude =
            survey['latitude']?.toString() ?? '';

        final String longitude =
            survey['longitude']?.toString() ?? '';

        final String date =
            formatDate(survey['created_at']?.toString());

        // ======================================================
        // CARD SURVEY
        // ======================================================

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 14),
          color: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: borderColor),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              openDetail(id);
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ============================================
                  // HEADER CARD
                  // ============================================

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: borderColor,
                          ),
                        ),
                        child: const Icon(
                          Icons.assignment_outlined,
                          color: primaryColor,
                          size: 25,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                borderRadius:
                                    BorderRadius.circular(8),
                                border: Border.all(
                                  color: borderColor,
                                ),
                              ),
                              child: Text(
                                categoryName,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: subtitleColor,
                      ),
                    ],
                  ),

                  // ============================================
                  // DESKRIPSI
                  // ============================================

                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: subtitleColor,
                      ),
                    ),
                  ],

                  const SizedBox(height: 14),
                  const Divider(color: borderColor),
                  const SizedBox(height: 8),

                  // ============================================
                  // LOKASI
                  // ============================================

                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 17,
                        color: primaryColor,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          latitude.isNotEmpty &&
                                  longitude.isNotEmpty
                              ? '$latitude, $longitude'
                              : 'Lokasi tidak tersedia',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: subtitleColor,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // ============================================
                  // TANGGAL
                  // ============================================

                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: subtitleColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        date,
                        style: const TextStyle(
                          fontSize: 12,
                          color: subtitleColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}



// import 'dart:convert';

// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';

// import 'survey_detail_page.dart';
// import 'survey_form_page.dart';

// class SurveyScreen extends StatefulWidget {
//   const SurveyScreen({super.key});

//   @override
//   State<SurveyScreen> createState() => _SurveyScreenState();
// }

// class _SurveyScreenState extends State<SurveyScreen> {
//   // ============================================================
//   // API
//   // ============================================================

//   static const String apiUrl =
//       'https://sijala.biz.id/api/v1/surveys';

//   // ============================================================
//   // WARNA OLED BLACK
//   // ============================================================

//   static const Color primaryColor = Color(0xFFD4D4D8);
//   static const Color backgroundColor = Color(0xFF000000);
//   static const Color cardColor = Color(0xFF171717);
//   static const Color surfaceColor = Color(0xFF202020);
//   static const Color borderColor = Color(0xFF333333);
//   static const Color textColor = Color(0xFFFFFFFF);
//   static const Color subtitleColor = Color(0xFF9CA3AF);

//   // ============================================================
//   // STATE
//   // ============================================================

//   List<Map<String, dynamic>> surveys = [];

//   bool isLoading = true;

//   String? errorMessage;

//   // Controller dan kata kunci pencarian
//   final TextEditingController searchController =
//       TextEditingController();

//   String searchQuery = '';

//   // ============================================================
//   // INIT STATE
//   // ============================================================

//   @override
//   void initState() {
//     super.initState();
//     fetchSurveys();
//   }

//   // ============================================================
//   // DISPOSE
//   // ============================================================

//   @override
//   void dispose() {
//     searchController.dispose();
//     super.dispose();
//   }

//   // ============================================================
//   // FILTER PENCARIAN
//   // ============================================================

//   List<Map<String, dynamic>> get filteredSurveys {
//     final query = searchQuery.trim().toLowerCase();

//     if (query.isEmpty) {
//       return surveys;
//     }

//     return surveys.where((survey) {
//       final title =
//           (survey['title'] ?? '').toString().toLowerCase();

//       final description =
//           (survey['description'] ?? '').toString().toLowerCase();

//       final category =
//           (survey['category_name'] ?? '').toString().toLowerCase();

//       final latitude =
//           (survey['latitude'] ?? '').toString().toLowerCase();

//       final longitude =
//           (survey['longitude'] ?? '').toString().toLowerCase();

//       return title.contains(query) ||
//           description.contains(query) ||
//           category.contains(query) ||
//           latitude.contains(query) ||
//           longitude.contains(query);
//     }).toList();
//   }

//   // ============================================================
//   // AMBIL DATA SURVEY
//   // ============================================================

//   Future<void> fetchSurveys() async {
//     if (mounted) {
//       setState(() {
//         isLoading = true;
//         errorMessage = null;
//       });
//     }

//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString('token') ?? '';

//       if (token.isEmpty) {
//         throw Exception(
//           'Token tidak ditemukan. Silakan login kembali.',
//         );
//       }

//       final response = await http.get(
//         Uri.parse(apiUrl),
//         headers: {
//           'Accept': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//       );

//       debugPrint('================================');
//       debugPrint('GET SURVEYS');
//       debugPrint('STATUS: ${response.statusCode}');
//       debugPrint('BODY: ${response.body}');
//       debugPrint('================================');

//       if (response.statusCode == 401) {
//         await prefs.remove('token');
//         await prefs.remove('user');

//         throw Exception('Sesi login telah berakhir.');
//       }

//       if (response.statusCode == 200) {
//         final dynamic data = jsonDecode(response.body);

//         List<dynamic> rawData = [];

//         if (data is Map &&
//             data['status'] == true &&
//             data['data'] is List) {
//           rawData = data['data'];
//         } else if (data is List) {
//           rawData = data;
//         }

//         if (!mounted) return;

//         setState(() {
//           surveys = rawData
//               .whereType<Map>()
//               .map(
//                 (item) => Map<String, dynamic>.from(item),
//               )
//               .toList();

//           isLoading = false;
//         });

//         debugPrint('TOTAL DATA SURVEY: ${surveys.length}');
//         return;
//       }

//       throw Exception(
//         'Gagal mengambil data survey. Kode: ${response.statusCode}',
//       );
//     } catch (e) {
//       debugPrint('ERROR GET SURVEY: $e');

//       if (!mounted) return;

//       setState(() {
//         isLoading = false;
//         errorMessage = e
//             .toString()
//             .replaceFirst('Exception: ', '');
//       });
//     }
//   }

//   // ============================================================
//   // TAMBAH SURVEY
//   // ============================================================

//   Future<void> openAddSurvey() async {
//     final result = await Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => const SurveyFormPage(),
//       ),
//     );

//     if (result == true && mounted) {
//       fetchSurveys();
//     }
//   }

//   // ============================================================
//   // BUKA DETAIL SURVEY
//   // ============================================================

//   Future<void> openDetail(int surveyId) async {
//     if (surveyId <= 0) {
//       showMessage(
//         'ID survey tidak valid.',
//         Colors.red,
//       );
//       return;
//     }

//     final result = await Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) =>
//             SurveyDetailPage(surveyId: surveyId),
//       ),
//     );

//     if (result == true && mounted) {
//       fetchSurveys();
//     }
//   }

//   // ============================================================
//   // FORMAT TANGGAL
//   // ============================================================

//   String formatDate(String? dateString) {
//     if (dateString == null || dateString.isEmpty) {
//       return '-';
//     }

//     try {
//       final date = DateTime.parse(
//         dateString.replaceFirst(' ', 'T'),
//       );

//       return '${date.day.toString().padLeft(2, '0')}/'
//           '${date.month.toString().padLeft(2, '0')}/'
//           '${date.year}';
//     } catch (e) {
//       return dateString;
//     }
//   }

//   // ============================================================
//   // PESAN
//   // ============================================================

//   void showMessage(String message, Color color) {
//     if (!mounted) return;

//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(
//           message,
//           style: const TextStyle(color: textColor),
//         ),
//         backgroundColor: cardColor,
//         behavior: SnackBarBehavior.floating,
//       ),
//     );
//   }

//   // ============================================================
//   // KOLOM PENCARIAN
//   // ============================================================

//   Widget buildSearchField() {
//     return TextField(
//       controller: searchController,
//       style: const TextStyle(
//         color: textColor,
//         fontSize: 14,
//       ),
//       cursorColor: primaryColor,
//       textInputAction: TextInputAction.search,
//       onChanged: (value) {
//         setState(() {
//           searchQuery = value;
//         });
//       },
//       decoration: InputDecoration(
//         hintText: 'Cari judul, deskripsi, kategori...',
//         hintStyle: const TextStyle(
//           color: subtitleColor,
//           fontSize: 13,
//         ),
//         prefixIcon: const Icon(
//           Icons.search_rounded,
//           color: subtitleColor,
//         ),
//         suffixIcon: searchQuery.isNotEmpty
//             ? IconButton(
//                 tooltip: 'Hapus pencarian',
//                 onPressed: () {
//                   searchController.clear();

//                   setState(() {
//                     searchQuery = '';
//                   });
//                 },
//                 icon: const Icon(
//                   Icons.close_rounded,
//                   color: subtitleColor,
//                 ),
//               )
//             : null,
//         filled: true,
//         fillColor: cardColor,
//         contentPadding: const EdgeInsets.symmetric(
//           horizontal: 16,
//           vertical: 15,
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(14),
//           borderSide: const BorderSide(
//             color: borderColor,
//           ),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(14),
//           borderSide: const BorderSide(
//             color: primaryColor,
//             width: 1.3,
//           ),
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // BUILD
//   // ============================================================

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: backgroundColor,

//       // APPBAR
//       appBar: AppBar(
//         title: const Text(
//           'Daftar Survey',
//           style: TextStyle(
//             color: textColor,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         centerTitle: true,
//         backgroundColor: backgroundColor,
//         foregroundColor: textColor,
//         elevation: 0,
//         scrolledUnderElevation: 0,
//         surfaceTintColor: Colors.transparent,
//       ),

//       // BODY
//       body: RefreshIndicator(
//         color: primaryColor,
//         backgroundColor: cardColor,
//         onRefresh: fetchSurveys,
//         child: buildBody(),
//       ),

//       // BUTTON TAMBAH
//       floatingActionButton: FloatingActionButton.extended(
//         onPressed: openAddSurvey,
//         backgroundColor: primaryColor,
//         foregroundColor: backgroundColor,
//         elevation: 0,
//         icon: const Icon(Icons.add),
//         label: const Text(
//           'Tambah Survey',
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // BUILD BODY
//   // ============================================================

//   Widget buildBody() {
//     // LOADING
//     if (isLoading) {
//       return const Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             CircularProgressIndicator(
//               color: primaryColor,
//             ),
//             SizedBox(height: 16),
//             Text(
//               'Memuat data survey...',
//               style: TextStyle(
//                 color: subtitleColor,
//               ),
//             ),
//           ],
//         ),
//       );
//     }

//     // ERROR
//     if (errorMessage != null && surveys.isEmpty) {
//       return ListView(
//         physics: const AlwaysScrollableScrollPhysics(),
//         padding: const EdgeInsets.all(16),
//         children: [
//           SizedBox(
//             height: MediaQuery.of(context).size.height * 0.65,
//             child: Center(
//               child: Padding(
//                 padding: const EdgeInsets.all(24),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Icon(
//                       Icons.wifi_off_rounded,
//                       size: 70,
//                       color: Colors.redAccent,
//                     ),
//                     const SizedBox(height: 16),
//                     const Text(
//                       'Gagal Memuat Data',
//                       style: TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                         color: textColor,
//                       ),
//                     ),
//                     const SizedBox(height: 10),
//                     Text(
//                       errorMessage!,
//                       textAlign: TextAlign.center,
//                       style: const TextStyle(
//                         color: subtitleColor,
//                       ),
//                     ),
//                     const SizedBox(height: 20),
//                     ElevatedButton.icon(
//                       onPressed: fetchSurveys,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: primaryColor,
//                         foregroundColor: backgroundColor,
//                       ),
//                       icon: const Icon(Icons.refresh),
//                       label: const Text('Coba Lagi'),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       );
//     }

//     // DATA KOSONG DARI API
//     if (surveys.isEmpty) {
//       return ListView(
//         physics: const AlwaysScrollableScrollPhysics(),
//         padding: const EdgeInsets.all(16),
//         children: [
//           buildSearchField(),
//           SizedBox(
//             height: MediaQuery.of(context).size.height * 0.55,
//             child: const Center(
//               child: Padding(
//                 padding: EdgeInsets.all(24),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(
//                       Icons.folder_open_rounded,
//                       size: 70,
//                       color: subtitleColor,
//                     ),
//                     SizedBox(height: 16),
//                     Text(
//                       'Belum Ada Data Survey',
//                       textAlign: TextAlign.center,
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         color: textColor,
//                       ),
//                     ),
//                     SizedBox(height: 8),
//                     Text(
//                       'Tekan tombol tambah untuk membuat survey.',
//                       textAlign: TextAlign.center,
//                       style: TextStyle(
//                         color: subtitleColor,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       );
//     }

//     // DATA SURVEY + PENCARIAN
//     final displayedSurveys = filteredSurveys;

//     return ListView(
//       physics: const AlwaysScrollableScrollPhysics(),
//       padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
//       children: [
//         // KOLOM PENCARIAN
//         buildSearchField(),

//         const SizedBox(height: 14),

//         // JUMLAH HASIL
//         Padding(
//           padding: const EdgeInsets.only(bottom: 14),
//           child: Text(
//             searchQuery.trim().isEmpty
//                 ? '${surveys.length} data survey'
//                 : '${displayedSurveys.length} hasil ditemukan',
//             style: const TextStyle(
//               color: subtitleColor,
//               fontSize: 13,
//             ),
//           ),
//         ),

//         // JIKA PENCARIAN TIDAK MENEMUKAN HASIL
//         if (displayedSurveys.isEmpty)
//           const Padding(
//             padding: EdgeInsets.symmetric(vertical: 60),
//             child: Column(
//               children: [
//                 Icon(
//                   Icons.search_off_rounded,
//                   size: 60,
//                   color: subtitleColor,
//                 ),
//                 SizedBox(height: 12),
//                 Text(
//                   'Survey tidak ditemukan',
//                   style: TextStyle(
//                     color: textColor,
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 SizedBox(height: 6),
//                 Text(
//                   'Coba kata kunci yang lain.',
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     color: subtitleColor,
//                   ),
//                 ),
//               ],
//             ),
//           ),

//         // LIST CARD SURVEY
//         ...List.generate(displayedSurveys.length, (index) {
//           final survey = displayedSurveys[index];

//           // DATA API
//           final int id =
//               int.tryParse(survey['id']?.toString() ?? '') ?? 0;

//           final String title =
//               survey['title']?.toString() ?? 'Tanpa Judul';

//           final String description =
//               survey['description']?.toString() ?? '';

//           final String categoryName =
//               survey['category_name']?.toString() ??
//                   'Tanpa Kategori';

//           final String latitude =
//               survey['latitude']?.toString() ?? '';

//           final String longitude =
//               survey['longitude']?.toString() ?? '';

//           final String date =
//               formatDate(survey['created_at']?.toString());

//           // CARD SURVEY
//           return Card(
//             elevation: 0,
//             margin: const EdgeInsets.only(bottom: 14),
//             color: cardColor,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(16),
//               side: const BorderSide(
//                 color: borderColor,
//               ),
//             ),
//             child: InkWell(
//               borderRadius: BorderRadius.circular(16),
//               onTap: () {
//                 openDetail(id);
//               },
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // HEADER CARD
//                     Row(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Container(
//                           width: 50,
//                           height: 50,
//                           decoration: BoxDecoration(
//                             color: surfaceColor,
//                             borderRadius: BorderRadius.circular(12),
//                             border: Border.all(
//                               color: borderColor,
//                             ),
//                           ),
//                           child: const Icon(
//                             Icons.assignment_outlined,
//                             color: primaryColor,
//                             size: 25,
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment:
//                                 CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 title,
//                                 maxLines: 2,
//                                 overflow: TextOverflow.ellipsis,
//                                 style: const TextStyle(
//                                   fontSize: 17,
//                                   fontWeight: FontWeight.bold,
//                                   color: textColor,
//                                 ),
//                               ),
//                               const SizedBox(height: 8),
//                               Container(
//                                 padding:
//                                     const EdgeInsets.symmetric(
//                                   horizontal: 10,
//                                   vertical: 5,
//                                 ),
//                                 decoration: BoxDecoration(
//                                   color: surfaceColor,
//                                   borderRadius:
//                                       BorderRadius.circular(8),
//                                   border: Border.all(
//                                     color: borderColor,
//                                   ),
//                                 ),
//                                 child: Text(
//                                   categoryName,
//                                   style: const TextStyle(
//                                     fontSize: 12,
//                                     fontWeight: FontWeight.w600,
//                                     color: primaryColor,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                         const SizedBox(width: 4),
//                         const Icon(
//                           Icons.chevron_right_rounded,
//                           color: subtitleColor,
//                         ),
//                       ],
//                     ),

//                     // DESKRIPSI
//                     if (description.isNotEmpty) ...[
//                       const SizedBox(height: 14),
//                       Text(
//                         description,
//                         maxLines: 2,
//                         overflow: TextOverflow.ellipsis,
//                         style: const TextStyle(
//                           fontSize: 13,
//                           height: 1.5,
//                           color: subtitleColor,
//                         ),
//                       ),
//                     ],

//                     const SizedBox(height: 14),
//                     const Divider(color: borderColor),
//                     const SizedBox(height: 8),

//                     // LOKASI
//                     Row(
//                       children: [
//                         const Icon(
//                           Icons.location_on_outlined,
//                           size: 17,
//                           color: primaryColor,
//                         ),
//                         const SizedBox(width: 5),
//                         Expanded(
//                           child: Text(
//                             latitude.isNotEmpty &&
//                                     longitude.isNotEmpty
//                                 ? '$latitude, $longitude'
//                                 : 'Lokasi tidak tersedia',
//                             maxLines: 1,
//                             overflow: TextOverflow.ellipsis,
//                             style: const TextStyle(
//                               fontSize: 12,
//                               color: subtitleColor,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),

//                     const SizedBox(height: 8),

//                     // TANGGAL
//                     Row(
//                       children: [
//                         const Icon(
//                           Icons.calendar_today_outlined,
//                           size: 16,
//                           color: subtitleColor,
//                         ),
//                         const SizedBox(width: 6),
//                         Text(
//                           date,
//                           style: const TextStyle(
//                             fontSize: 12,
//                             color: subtitleColor,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           );
//         }),
//       ],
//     );
//   }
// }