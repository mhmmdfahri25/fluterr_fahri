import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:field_survey/screens/auth/login_screen.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SurveyFormPage extends StatefulWidget {
  final Map<String, dynamic>? survey;

  const SurveyFormPage({super.key, this.survey});

  @override
  State<SurveyFormPage> createState() => _SurveyFormPageState();
}

class _SurveyFormPageState extends State<SurveyFormPage> {
  // API
  static const String baseUrl = 'https://sijala.biz.id/api/v1';
  static const String categoryUrl = '$baseUrl/categories';
  static const String saveSurveyUrl = '$baseUrl/surveys/save';
  static const String imageUrl = 'https://sijala.biz.id/api/image';

  // WARNA OLED BLACK
  static const Color primaryColor = Color(0xFFD4D4D8);
  static const Color backgroundColor = Color(0xFF000000);
  static const Color cardColor = Color(0xFF171717);
  static const Color inputColor = Color(0xFF202020);
  static const Color borderColor = Color(0xFF333333);
  static const Color textColor = Color(0xFFFFFFFF);
  static const Color subtitleColor = Color(0xFF9CA3AF);

  // FORM
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController =
      TextEditingController();
  final TextEditingController latitudeController = TextEditingController();
  final TextEditingController longitudeController = TextEditingController();

  // KATEGORI
  List<Map<String, dynamic>> categories = [];
  int? selectedCategoryId;
  bool isLoadingCategories = true;

  // FOTO
  final ImagePicker picker = ImagePicker();
  XFile? selectedImage;
  Uint8List? selectedImageBytes;
  Uint8List? existingImageBytes;
  bool isLoadingImage = false;

  // PETA
  final MapController mapController = MapController();

  // Titik awal peta sekitar Tasikmalaya
  LatLng selectedLocation = const LatLng(-7.3274, 108.2207);
  bool hasSelectedLocation = false;
  bool mapReady = false;

  // STATE
  bool isSubmitting = false;
  bool get isEdit => widget.survey != null;

  @override
  void initState() {
    super.initState();
    fillSurveyData();
    fetchCategories();
  }

  // ============================================================
  // ISI DATA SAAT EDIT
  // ============================================================

  void fillSurveyData() {
    if (!isEdit) return;

    final survey = widget.survey!;

    titleController.text = survey['title']?.toString() ?? '';
    descriptionController.text =
        survey['description']?.toString() ?? '';
    latitudeController.text = survey['latitude']?.toString() ?? '';
    longitudeController.text = survey['longitude']?.toString() ?? '';

    selectedCategoryId =
        int.tryParse(survey['category_id']?.toString() ?? '');

    final latitude = double.tryParse(latitudeController.text);
    final longitude = double.tryParse(longitudeController.text);

    if (latitude != null &&
        longitude != null &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180) {
      selectedLocation = LatLng(latitude, longitude);
      hasSelectedLocation = true;
    }

    final photoName = survey['photo']?.toString() ?? '';

    if (photoName.isNotEmpty &&
        photoName != 'null' &&
        photoName != 'placeholder.jpg') {
      fetchExistingImage(photoName);
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    super.dispose();
  }

  // ============================================================
  // TOKEN
  // ============================================================

  Future<String> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  // ============================================================
  // KATEGORI API
  // ============================================================

  Future<void> fetchCategories() async {
    try {
      if (mounted) {
        setState(() => isLoadingCategories = true);
      }

      final token = await getToken();

      final response = await http.get(
        Uri.parse(categoryUrl),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('CATEGORY STATUS: ${response.statusCode}');
      debugPrint('CATEGORY BODY: ${response.body}');

      if (response.statusCode == 401) {
        await logout();
        return;
      }

      if (response.statusCode != 200) {
        throw Exception('Gagal mengambil kategori');
      }

      final decoded = jsonDecode(response.body);
      List<dynamic> rawCategories = [];

      if (decoded is Map && decoded['data'] is List) {
        rawCategories = decoded['data'];
      } else if (decoded is List) {
        rawCategories = decoded;
      }

      if (!mounted) return;

      setState(() {
        categories = rawCategories
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();

        if (selectedCategoryId != null) {
          final exists = categories.any((category) {
            final id =
                int.tryParse(category['id']?.toString() ?? '');
            return id == selectedCategoryId;
          });

          if (!exists) selectedCategoryId = null;
        }

        isLoadingCategories = false;
      });
    } catch (e) {
      debugPrint('CATEGORY ERROR: $e');

      if (!mounted) return;

      setState(() => isLoadingCategories = false);
      showErrorSnackBar('Gagal memuat kategori.');
    }
  }

  // ============================================================
  // FOTO LAMA
  // ============================================================

  Future<void> fetchExistingImage(String photoName) async {
    try {
      if (mounted) {
        setState(() => isLoadingImage = true);
      }

      final token = await getToken();
      final fileName =
          photoName.contains('/') ? photoName.split('/').last : photoName;

      final response = await http.get(
        Uri.parse('$imageUrl/$fileName'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'image/*',
        },
      );

      debugPrint('PHOTO STATUS: ${response.statusCode}');

      if (response.statusCode == 200 &&
          response.bodyBytes.isNotEmpty &&
          mounted) {
        setState(() => existingImageBytes = response.bodyBytes);
      }
    } catch (e) {
      debugPrint('PHOTO ERROR: $e');
    } finally {
      if (mounted) {
        setState(() => isLoadingImage = false);
      }
    }
  }

  // ============================================================
  // PILIH FOTO
  // ============================================================

  Future<void> pickImage(ImageSource source) async {
    try {
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (image == null) return;

      final bytes = await image.readAsBytes();

      if (!mounted) return;

      setState(() {
        selectedImage = image;
        selectedImageBytes = bytes;
      });
    } catch (e) {
      showErrorSnackBar('Gagal memilih foto.');
    }
  }

  void showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        side: BorderSide(color: borderColor),
      ),
      builder: (bottomContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 45,
                  height: 5,
                  decoration: BoxDecoration(
                    color: borderColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Pilih Sumber Foto',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 15),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library,
                    color: primaryColor,
                  ),
                  title: const Text(
                    'Galeri',
                    style: TextStyle(color: textColor),
                  ),
                  subtitle: const Text(
                    'Pilih foto dari galeri',
                    style: TextStyle(color: subtitleColor),
                  ),
                  onTap: () {
                    Navigator.pop(bottomContext);
                    pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt,
                    color: primaryColor,
                  ),
                  title: const Text(
                    'Kamera',
                    style: TextStyle(color: textColor),
                  ),
                  subtitle: const Text(
                    'Ambil foto langsung',
                    style: TextStyle(color: subtitleColor),
                  ),
                  onTap: () {
                    Navigator.pop(bottomContext);
                    pickImage(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void removeSelectedImage() {
    setState(() {
      selectedImage = null;
      selectedImageBytes = null;
      existingImageBytes = null;
    });
  }

  // ============================================================
  // PILIH TITIK DI PETA
  // ============================================================

  void selectLocation(LatLng location) {
    setState(() {
      selectedLocation = location;
      hasSelectedLocation = true;

      latitudeController.text = location.latitude.toStringAsFixed(7);
      longitudeController.text = location.longitude.toStringAsFixed(7);
    });
  }

  void moveMapToCoordinates() {
    final latitude = double.tryParse(latitudeController.text.trim());
    final longitude = double.tryParse(longitudeController.text.trim());

    if (latitude == null ||
        longitude == null ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      showErrorSnackBar('Masukkan koordinat yang valid.');
      return;
    }

    final location = LatLng(latitude, longitude);

    setState(() {
      selectedLocation = location;
      hasSelectedLocation = true;
    });

    if (mapReady) {
      mapController.move(location, 16);
    }
  }

  // ============================================================
  // SIMPAN SURVEY
  // ============================================================

  Future<void> saveSurvey() async {
    if (!formKey.currentState!.validate()) {
      showErrorSnackBar('Lengkapi data yang wajib diisi.');
      return;
    }

    if (selectedCategoryId == null) {
      showErrorSnackBar('Silakan pilih kategori.');
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final token = await getToken();

      if (token.isEmpty) {
        await logout();
        return;
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(saveSurveyUrl),
      );

      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      request.fields['title'] = titleController.text.trim();
      request.fields['category_id'] = selectedCategoryId.toString();
      request.fields['description'] = descriptionController.text.trim();

      if (latitudeController.text.trim().isNotEmpty) {
        request.fields['latitude'] = latitudeController.text.trim();
      }

      if (longitudeController.text.trim().isNotEmpty) {
        request.fields['longitude'] = longitudeController.text.trim();
      }

      if (isEdit) {
        request.fields['id'] = widget.survey!['id'].toString();
        request.fields['_method'] = 'PUT';
      }

      if (selectedImage != null && selectedImageBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'photo',
            selectedImageBytes!,
            filename: selectedImage!.name,
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('SAVE STATUS: ${response.statusCode}');
      debugPrint('SAVE BODY: ${response.body}');

      dynamic responseData;

      try {
        responseData = jsonDecode(response.body);
      } catch (_) {}

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEdit
                  ? 'Survey berhasil diperbarui!'
                  : 'Survey berhasil ditambahkan!',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        await Future.delayed(const Duration(milliseconds: 400));

        if (!mounted) return;

        Navigator.pop(context, true);
        return;
      }

      String message = 'Gagal menyimpan survey.';

      if (responseData is Map) {
        if (responseData['message'] != null) {
          message = responseData['message'].toString();
        }

        if (responseData['errors'] != null) {
          message += '\n${responseData['errors']}';
        }
      }

      throw Exception('$message (Kode: ${response.statusCode})');
    } catch (e) {
      debugPrint('SAVE ERROR: $e');

      if (!mounted) return;

      showErrorSnackBar(
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('token');
    await prefs.remove('user');

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  void showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
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
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        title: Text(
          isEdit ? 'Edit Survey' : 'Tambah Survey',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // HEADER
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: inputColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        isEdit ? Icons.edit_document : Icons.add_task,
                        color: primaryColor,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEdit ? 'Edit Data Survey' : 'Buat Survey Baru',
                            style: const TextStyle(
                              color: textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isEdit
                                ? 'Perbarui data survey kamu.'
                                : 'Lengkapi informasi survey.',
                            style: const TextStyle(
                              color: subtitleColor,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              buildMainDataCard(),
              const SizedBox(height: 16),
              buildPhotoCard(),
              const SizedBox(height: 16),
              buildMapCard(),
              const SizedBox(height: 16),
              buildLocationCard(),
              const SizedBox(height: 24),

              SizedBox(
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: isSubmitting ? null : saveSurvey,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: borderColor,
                    disabledForegroundColor: subtitleColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(isEdit ? Icons.save : Icons.add_circle),
                  label: Text(
                    isSubmitting
                        ? 'Menyimpan...'
                        : isEdit
                            ? 'Simpan Perubahan'
                            : 'Simpan Survey',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DATA UTAMA
  // ============================================================

  Widget buildMainDataCard() {
    return Card(
      elevation: 0,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.description_outlined, color: primaryColor),
                SizedBox(width: 10),
                Text(
                  'Data Utama Survey',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: titleController,
              style: const TextStyle(color: textColor),
              decoration: inputDecoration(
                label: 'Judul Survey *',
                hint: 'Contoh: Jalan Berlubang',
                icon: Icons.title,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Judul survey wajib diisi';
                }
                return null;
              },
            ),

            const SizedBox(height: 18),

            if (isLoadingCategories)
              const Center(
                child: CircularProgressIndicator(color: primaryColor),
              )
            else
              DropdownButtonFormField<int>(
                value: selectedCategoryId,
                isExpanded: true,
                dropdownColor: cardColor,
                style: const TextStyle(color: textColor),
                iconEnabledColor: primaryColor,
                decoration: inputDecoration(
                  label: 'Kategori Survey *',
                  hint: 'Pilih kategori',
                  icon: Icons.category,
                ),
                items: categories.map((category) {
                  final id = int.tryParse(
                    category['id']?.toString() ?? '',
                  );
                  final name =
                      category['name']?.toString() ?? 'Tanpa Nama';

                  if (id == null) return null;

                  return DropdownMenuItem<int>(
                    value: id,
                    child: Text(
                      name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: textColor),
                    ),
                  );
                }).whereType<DropdownMenuItem<int>>().toList(),
                onChanged: (value) {
                  setState(() => selectedCategoryId = value);
                },
                validator: (value) {
                  if (value == null) return 'Pilih kategori survey';
                  return null;
                },
              ),

            const SizedBox(height: 18),

            TextFormField(
              controller: descriptionController,
              style: const TextStyle(color: textColor),
              maxLines: 5,
              decoration: inputDecoration(
                label: 'Deskripsi Survey',
                hint: 'Masukkan keterangan survey',
                icon: Icons.notes,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FOTO SURVEY
  // ============================================================

  Widget buildPhotoCard() {
    return Card(
      elevation: 0,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.photo_camera_outlined, color: primaryColor),
                SizedBox(width: 10),
                Text(
                  'Foto Survey',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            if (isLoadingImage)
              const Center(
                child: CircularProgressIndicator(color: primaryColor),
              )
            else if (selectedImageBytes != null ||
                existingImageBytes != null)
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.memory(
                      selectedImageBytes ?? existingImageBytes!,
                      width: double.infinity,
                      height: 220,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: showImageSourceDialog,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryColor,
                            side: const BorderSide(color: primaryColor),
                            padding: const EdgeInsets.symmetric(
                              vertical: 13,
                            ),
                          ),
                          icon: const Icon(Icons.edit),
                          label: const Text('Ganti Foto'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: removeSelectedImage,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(
                            vertical: 13,
                          ),
                        ),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Hapus'),
                      ),
                    ],
                  ),
                ],
              )
            else
              InkWell(
                onTap: showImageSourceDialog,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: inputColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: borderColor,
                      width: 1.5,
                    ),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo_outlined,
                        size: 45,
                        color: primaryColor,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Ketuk untuk memilih foto',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: subtitleColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PETA INTERAKTIF
  // ============================================================

  Widget buildMapCard() {
    return Card(
      elevation: 0,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.map_outlined, color: primaryColor),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Pilih Lokasi di Peta',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Ketuk lokasi yang ingin disurvei. Koordinat akan terisi otomatis.',
              style: TextStyle(
                color: subtitleColor,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),

            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                height: 300,
                child: FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    initialCenter: selectedLocation,
                    initialZoom: 14,
                    onMapReady: () {
                      mapReady = true;

                      if (hasSelectedLocation) {
                        mapController.move(selectedLocation, 15);
                      }
                    },
                    onTap: (tapPosition, point) {
                      selectLocation(point);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.field_survey.app',
                    ),
                    MarkerLayer(
                      markers: [
                        if (hasSelectedLocation)
                          Marker(
                            point: selectedLocation,
                            width: 45,
                            height: 45,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 42,
                            ),
                          ),
                      ],
                    ),
                    const RichAttributionWidget(
                      attributions: [
                        TextSourceAttribution(
                          'OpenStreetMap contributors',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: inputColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Koordinat Terpilih',
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Latitude: ${hasSelectedLocation ? selectedLocation.latitude.toStringAsFixed(7) : '-'}',
                    style: const TextStyle(
                      color: textColor,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Longitude: ${hasSelectedLocation ? selectedLocation.longitude.toStringAsFixed(7) : '-'}',
                    style: const TextStyle(
                      color: textColor,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: moveMapToCoordinates,
                icon: const Icon(Icons.my_location),
                label: const Text('Gunakan Koordinat dari Input'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColor,
                  side: const BorderSide(color: borderColor),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INPUT LATITUDE DAN LONGITUDE
  // ============================================================

  Widget buildLocationCard() {
    return Card(
      elevation: 0,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.location_on_outlined, color: primaryColor),
                SizedBox(width: 10),
                Text(
                  'Koordinat Lokasi',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Koordinat otomatis terisi ketika kamu mengetuk peta. Kamu juga bisa memasukkannya secara manual.',
              style: TextStyle(
                fontSize: 13,
                color: subtitleColor,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),

            TextFormField(
              controller: latitudeController,
              style: const TextStyle(color: textColor),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              onChanged: (_) {},
              decoration: inputDecoration(
                label: 'Latitude',
                hint: '-7.360680',
                icon: Icons.my_location,
              ),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: longitudeController,
              style: const TextStyle(color: textColor),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: inputDecoration(
                label: 'Longitude',
                hint: '108.105797',
                icon: Icons.location_on,
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: moveMapToCoordinates,
                style: ElevatedButton.styleFrom(
                  backgroundColor: inputColor,
                  foregroundColor: primaryColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: borderColor),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                icon: const Icon(Icons.map),
                label: const Text('Tampilkan Koordinat di Peta'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: subtitleColor),
      hintStyle: const TextStyle(color: subtitleColor),
      errorStyle: const TextStyle(color: Colors.redAccent),
      prefixIcon: Icon(icon, color: primaryColor),
      filled: true,
      fillColor: inputColor,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: primaryColor,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1.5,
        ),
      ),
    );
  }
}
