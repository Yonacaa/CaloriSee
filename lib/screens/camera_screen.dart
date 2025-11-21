
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/nutrition_service.dart';
import '../database/database_helper.dart';
 

class CameraScreen extends StatefulWidget {
  final int userId;
  const CameraScreen({super.key, required this.userId});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  File? _imageFile;
  bool _isAnalyzing = false;
  Map<String, dynamic>? _nutritionData;
  bool _isSavedAsFavorite = false;

  Future<void> _takePicture() async {
    try {
      // Check and request camera permission at runtime
      PermissionStatus camStatus = await Permission.camera.status;
      if (!camStatus.isGranted) {
        camStatus = await Permission.camera.request();
        if (!camStatus.isGranted) {
          if (!mounted) return;
          // Show dialog to explain why permission is needed and offer to open settings
          await showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Izin Kamera Diperlukan'),
              content: const Text('Aplikasi membutuhkan izin kamera untuk mengambil foto makanan.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Batal'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await openAppSettings();
                  },
                  child: const Text('Buka Pengaturan'),
                ),
              ],
            ),
          );
          return;
        }
      }

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
          _isAnalyzing = true;
        });

        // Simulate AI analysis (2 seconds delay)
        await Future.delayed(const Duration(seconds: 2));

        // Generate mock nutrition data and check favorite status
        await _generateMockNutrition();

        setState(() {
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      debugPrint('Error taking picture: $e');
    }
  }

  Future<void> _generateMockNutrition() async {
    // List of sample foods
    List<Map<String, dynamic>> sampleFoods = [
      {
        'name': 'Nasi Goreng',
        'calories': 450.0,
        'protein': 12.0,
        'fat': 18.0,
        'carbs': 60.0,
      },
      {
        'name': 'Ayam Goreng',
        'calories': 320.0,
        'protein': 28.0,
        'fat': 22.0,
        'carbs': 8.0,
      },
      {
        'name': 'Gado-Gado',
        'calories': 280.0,
        'protein': 10.0,
        'fat': 15.0,
        'carbs': 35.0,
      },
      {
        'name': 'Sate Ayam',
        'calories': 220.0,
        'protein': 25.0,
        'fat': 12.0,
        'carbs': 10.0,
      },
      {
        'name': 'Mie Goreng',
        'calories': 380.0,
        'protein': 14.0,
        'fat': 16.0,
        'carbs': 52.0,
      },
    ];

    // Randomly select a food
    Random random = Random();
    var selected = sampleFoods[random.nextInt(sampleFoods.length)];

    // Check if this food is already in favorites
    try {
      DatabaseHelper db = DatabaseHelper();
      bool fav = await db.isFavorite(widget.userId, selected['name']);
      if (!mounted) return;
      setState(() {
        _nutritionData = selected;
        _isSavedAsFavorite = fav;
      });
    } catch (e) {
      debugPrint('Error checking favorite: $e');
      if (!mounted) return;
      setState(() {
        _nutritionData = selected;
        _isSavedAsFavorite = false;
      });
    }
  }

  Future<void> _lookupNutritionLive() async {
    final TextEditingController ctrl = TextEditingController();
    final result = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lookup Nutrition (live)'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'Masukkan nama makanan, mis. nasi goreng'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(ctrl.text.trim()), child: const Text('Cari')),
        ],
      ),
    );

    if (result == null || result.isEmpty) return;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      NutritionService ns = NutritionService();
      final data = await ns.getNutritionFromText(result);
      if (!mounted) return;

      if (data == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak dapat menemukan data gizi untuk istilah tersebut')));
      } else if (data.containsKey('calories')) {
        // Edamam response
        final parsed = ns.parseEdamamNutrition(data);
        setState(() {
          _nutritionData = {
            'name': result,
            'calories': parsed['calories'] ?? 0,
            'protein': parsed['protein'] ?? 0,
            'fat': parsed['fat'] ?? 0,
            'carbs': parsed['carbs'] ?? 0,
          };
        });
      } else if (data.containsKey('items') && data['items'] is List && data['items'].isNotEmpty) {
        final first = data['items'][0] as Map<String, dynamic>;
        final parsed = ns.parseNinjaNutrition(first);
        setState(() {
          _nutritionData = {
            'name': first['name'] ?? result,
            'calories': parsed['calories'] ?? 0,
            'protein': parsed['protein'] ?? 0,
            'fat': parsed['fat'] ?? 0,
            'carbs': parsed['carbs'] ?? 0,
          };
        });
      } else if (data.containsKey('nutrition')) {
        // Our mock getMockNutrition returns { name, nutrition }
        final nutrition = data['nutrition'] as Map<String, dynamic>;
        setState(() {
          _nutritionData = {
            'name': data['name'] ?? result,
            'calories': nutrition['calories'] ?? 0,
            'protein': nutrition['protein'] ?? 0,
            'fat': nutrition['fat'] ?? 0,
            'carbs': nutrition['carbs'] ?? 0,
          };
        });
      } else {
        // Unknown shape, try to read top-level keys
        setState(() {
          _nutritionData = {
            'name': result,
            'calories': (data['calories'] ?? 0),
            'protein': (data['protein'] ?? 0),
            'fat': (data['fat'] ?? 0),
            'carbs': (data['carbs'] ?? 0),
          };
        });
      }
    } catch (e) {
      debugPrint('Live nutrition lookup failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lookup gagal')));
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _saveToHistory() async {
    if (_nutritionData == null) return;

    try {
      DatabaseHelper db = DatabaseHelper();
      await db.addFoodHistory({
        'userId': widget.userId,
        'foodName': _nutritionData!['name'],
        'calories': _nutritionData!['calories'],
        'protein': _nutritionData!['protein'],
        'fat': _nutritionData!['fat'],
        'carbs': _nutritionData!['carbs'],
        'imagePath': _imageFile?.path ?? '',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Berhasil disimpan ke riwayat! ✓'),
          backgroundColor: const Color(0xFF6EE7B7),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      debugPrint('Error saving to history: $e');
    }
  }

  Future<void> _saveAsFavorite() async {
    if (_nutritionData == null) return;

    try {
      DatabaseHelper db = DatabaseHelper();
      await db.addFavorite({
        'userId': widget.userId,
        'foodName': _nutritionData!['name'],
        'calories': _nutritionData!['calories'],
        'protein': _nutritionData!['protein'],
        'fat': _nutritionData!['fat'],
        'carbs': _nutritionData!['carbs'],
      });

      if (!mounted) return;
      setState(() {
        _isSavedAsFavorite = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Berhasil disimpan ke favorit! ★'),
          backgroundColor: const Color(0xFFFBBF24),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      debugPrint('Error saving to favorites: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Gagal menyimpan ke favorit'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F2937),
      appBar: AppBar(
        title: Text(
          'Scan Makanan',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _imageFile == null ? _buildCameraView() : _buildResultView(),
    );
  }

  Widget _buildCameraView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.camera_alt_outlined,
            size: 100,
            color: Colors.white.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'Arahkan kamera ke makanan',
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 48),
          GestureDetector(
            onTap: _takePicture,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6EE7B7),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6EE7B7).withValues(alpha: 0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.camera,
                size: 40,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultView() {
    if (_isAnalyzing) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: Color(0xFF6EE7B7),
            ),
            const SizedBox(height: 24),
            Text(
              'Menganalisis makanan...',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // Image Preview
          Container(
            height: 250,
            width: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: FileImage(_imageFile!),
                fit: BoxFit.cover,
              ),
            ),
          ),

          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Food Name
                  Text(
                    _nutritionData!['name'],
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6EE7B7).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_nutritionData!['calories'].toInt()} kcal',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF6EE7B7),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Nutrition Chart
                  Text(
                    'Komposisi Nutrisi',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sections: [
                          PieChartSectionData(
                            value: _nutritionData!['protein'],
                            title: 'Protein',
                            color: const Color(0xFF6EE7B7),
                            radius: 80,
                            titleStyle: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          PieChartSectionData(
                            value: _nutritionData!['fat'],
                            title: 'Lemak',
                            color: const Color(0xFFFBBF24),
                            radius: 80,
                            titleStyle: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          PieChartSectionData(
                            value: _nutritionData!['carbs'],
                            title: 'Karbo',
                            color: const Color(0xFF60A5FA),
                            radius: 80,
                            titleStyle: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Nutrition Details
                    _buildNutritionRow('Protein', _nutritionData!['protein'], 'g', const Color(0xFF6EE7B7)),
                    _buildNutritionRow('Lemak', _nutritionData!['fat'], 'g', const Color(0xFFFBBF24)),
                    _buildNutritionRow('Karbohidrat', _nutritionData!['carbs'], 'g', const Color(0xFF60A5FA)),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _imageFile = null;
                                  _nutritionData = null;
                                  _isSavedAsFavorite = false;
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                side: const BorderSide(color: Color(0xFF6EE7B7)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Scan Ulang',
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFF6EE7B7),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _saveToHistory,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: const Color(0xFF6EE7B7),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Simpan',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _lookupNutritionLive,
                          icon: const Icon(Icons.cloud_download_outlined),
                          label: const Text('Lookup Live Nutrition'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isSavedAsFavorite ? null : _saveAsFavorite,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: _isSavedAsFavorite ? Colors.grey : const Color(0xFFFBBF24),
                            disabledBackgroundColor: Colors.grey[300],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: Icon(
                            _isSavedAsFavorite ? Icons.favorite : Icons.favorite_border,
                            color: _isSavedAsFavorite ? Colors.white : Colors.white,
                          ),
                          label: Text(
                            _isSavedAsFavorite ? 'Sudah di Favorit ✓' : 'Simpan sebagai Favorit',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionRow(String label, double value, String unit, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '${value.toStringAsFixed(1)} $unit',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}