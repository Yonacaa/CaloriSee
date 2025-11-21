import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import 'login_screen.dart';
import '../services/theme_service.dart';

class ProfileScreen extends StatefulWidget {
  final int userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _targetCaloriesController = TextEditingController();
  // Macro target percentages (integers 0-100)
  int _targetProtein = 30;
  int _targetFat = 25;
  int _targetCarbs = 45;
  
  Map<String, dynamic>? userData;
  String? profileImagePath;
  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => isLoading = true);
    
    try {
      DatabaseHelper db = DatabaseHelper();
      userData = await db.getUserById(widget.userId);
      
      if (userData != null) {
        _nameController.text = userData!['fullName'] ?? '';
        _weightController.text = userData!['weight']?.toString() ?? '';
        _heightController.text = userData!['height']?.toString() ?? '';
        _targetCaloriesController.text = userData!['targetCalories']?.toString() ?? '2000';
        _targetProtein = userData!['targetProtein'] is int ? userData!['targetProtein'] as int : (userData!['targetProtein']?.toInt() ?? _targetProtein);
        _targetFat = userData!['targetFat'] is int ? userData!['targetFat'] as int : (userData!['targetFat']?.toInt() ?? _targetFat);
        _targetCarbs = userData!['targetCarbs'] is int ? userData!['targetCarbs'] as int : (userData!['targetCarbs']?.toInt() ?? _targetCarbs);
        profileImagePath = userData!['profileImage'];
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          profileImagePath = image.path;
        });
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('Gagal mengambil foto: $e');
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Pilih Sumber Foto',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF6EE7B7)),
              title: const Text('Kamera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF6EE7B7)),
              title: const Text('Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSaving = true);

    try {
      DatabaseHelper db = DatabaseHelper();
      
      Map<String, dynamic> updatedData = {
        'fullName': _nameController.text,
        'weight': double.tryParse(_weightController.text) ?? 0,
        'height': double.tryParse(_heightController.text) ?? 0,
        'targetCalories': double.tryParse(_targetCaloriesController.text) ?? 2000,
        'targetProtein': _targetProtein,
        'targetFat': _targetFat,
        'targetCarbs': _targetCarbs,
      };

      if (profileImagePath != null) {
        updatedData['profileImage'] = profileImagePath;
      }

      int result = await db.updateUser(widget.userId, updatedData);

      if (!mounted) return;

      if (result > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profil berhasil diperbarui! ✓'),
            backgroundColor: const Color(0xFF6EE7B7),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _showErrorDialog('Gagal memperbarui profil: $e');
    } finally {
      setState(() => isSaving = false);
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.clear();

              if (!mounted) return;
              navigator.pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Profil Saya',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: Theme.of(context).appBarTheme.elevation ?? 0,
        iconTheme: Theme.of(context).appBarTheme.iconTheme,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Theme toggle (dark mode) — persists via ThemeService
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: ValueListenableBuilder<ThemeMode>(
                      valueListenable: ThemeService.modeNotifier,
                      builder: (context, mode, _) {
                        return SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('Dark Mode', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            mode == ThemeMode.dark ? 'Aktif' : 'Non-aktif',
                            style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
                          ),
                          value: mode == ThemeMode.dark,
                          onChanged: (v) {
                            ThemeService.setTheme(v ? ThemeMode.dark : ThemeMode.light);
                          },
                          activeThumbColor: Theme.of(context).colorScheme.primary,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildProfileImage(),
                  const SizedBox(height: 30),
                  _buildProfileForm(),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileImage() {
    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.primary,
              image: profileImagePath != null
                  ? DecorationImage(
                      image: FileImage(File(profileImagePath!)),
                      fit: BoxFit.cover,
                    )
                  : null,
              boxShadow: [
                  BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withAlpha((0.3 * 255).round()),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: profileImagePath == null
                ? Icon(
                    Icons.person,
                    size: 60,
                    color: Theme.of(context).colorScheme.onPrimary,
                  )
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha((0.1 * 255).round()),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Icon(
                Icons.camera_alt,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileForm() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).round()),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informasi Pribadi',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Username (Read-only)
            _buildInfoCard(
              'Username',
              userData?['username'] ?? '-',
              Icons.person_outline,
            ),
            const SizedBox(height: 12),

            // Email (Read-only)
            _buildInfoCard(
              'Email',
              userData?['email'] ?? '-',
              Icons.email_outlined,
            ),
            const SizedBox(height: 20),

            // Full Name
            _buildTextField(
              controller: _nameController,
              label: 'Nama Lengkap',
              icon: Icons.badge_outlined,
            ),
            const SizedBox(height: 16),

            // Weight
            _buildTextField(
              controller: _weightController,
              label: 'Berat Badan (kg)',
              icon: Icons.monitor_weight_outlined,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Height
            _buildTextField(
              controller: _heightController,
              label: 'Tinggi Badan (cm)',
              icon: Icons.height_outlined,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Target Calories
            _buildTextField(
              controller: _targetCaloriesController,
              label: 'Target Kalori Harian',
              icon: Icons.local_fire_department_outlined,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Macro Targets
            Text(
              'Target Makronutrien (%)',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildMacroSlider('Protein', _targetProtein, Theme.of(context).colorScheme.primary, (val) {
              setState(() {
                _targetProtein = val;
                int remainder = 100 - (_targetProtein + _targetFat);
                _targetCarbs = remainder.clamp(0, 100);
              });
            }),
            const SizedBox(height: 8),
            _buildMacroSlider('Lemak', _targetFat, const Color(0xFFFBBF24), (val) {
              setState(() {
                _targetFat = val;
                int remainder = 100 - (_targetProtein + _targetFat);
                _targetCarbs = remainder.clamp(0, 100);
              });
            }),
            const SizedBox(height: 8),
            _buildMacroSlider('Karbo', _targetCarbs, const Color(0xFF60A5FA), (val) {
              setState(() {
                _targetCarbs = val;
                int diff = 100 - (_targetProtein + _targetFat + _targetCarbs);
                if (diff != 0) {
                  _targetFat = (_targetFat + diff).clamp(0, 100);
                }
              });
            }),
            const SizedBox(height: 24),

            // Update Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isSaving ? null : _updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  elevation: 5,
                ),
                child: isSaving
                    ? CircularProgressIndicator(color: Theme.of(context).colorScheme.onPrimary)
                    : Text(
                        'Perbarui Profil',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withAlpha((0.95 * 255).round()),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
        ),
      ),
    );
  }

  Widget _buildMacroSlider(String label, int value, Color color, ValueChanged<int> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[700])),
            Text('$value%', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
        Slider(
          value: value.toDouble().clamp(0, 100),
          min: 0,
          max: 100,
          activeColor: color,
          inactiveColor: color.withAlpha((0.2 * 255).round()),
          divisions: 100,
          label: '$value%',
          onChanged: (v) => onChanged(v.toInt()),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _targetCaloriesController.dispose();
    super.dispose();
  }
}