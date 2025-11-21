import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/database_helper.dart';
import '../services/exercise_service.dart';

class ExerciseScreen extends StatefulWidget {
  final int userId;
  const ExerciseScreen({super.key, required this.userId});

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  List<Map<String, dynamic>> exercises = [];
  bool isLoading = true;
  double todayCaloriesBurned = 0;

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    setState(() => isLoading = true);

    try {
      DatabaseHelper db = DatabaseHelper();
      exercises = await db.getExercises(widget.userId);
      todayCaloriesBurned = await db.getTodayCaloriesBurned(widget.userId);

      // Try to fetch remote exercises if none found locally (or merge if desired)
      ExerciseService exerciseService = ExerciseService();
      List<Map<String, dynamic>>? remote = await exerciseService.getExercisesByType('cardio');
      if ((exercises.isEmpty || exercises.length < 5) && remote != null && remote.isNotEmpty) {
        // Map remote items into the local display format without persisting
        final mapped = remote.map((item) {
          double caloriesBurned = 0;
          try {
            if (item.containsKey('met')) {
              final met = (item['met'] is num) ? (item['met'] as num).toDouble() : double.tryParse('${item['met']}') ?? 0.0;
              caloriesBurned = met * 70 * (30 / 60); // assume 70kg and 30 minutes
            }
          } catch (_) {}

          return {
            'exerciseName': item['name'] ?? item['exerciseName'] ?? 'Exercise',
            'durationMinutes': 30,
            'caloriesBurned': caloriesBurned > 0 ? caloriesBurned : 200,
          };
        }).toList();

        // Prepend remote suggestions
        exercises = [...mapped, ...exercises];
      }
    } catch (e) {
      debugPrint('Error loading exercises: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _addExercise() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const AddExerciseDialog(),
    );

    if (result != null) {
      try {
        DatabaseHelper db = DatabaseHelper();
        await db.addExercise({
          'userId': widget.userId,
          ...result,
        });
        await _loadExercises();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Olahraga berhasil ditambahkan')),
        );
      } catch (e) {
        debugPrint('Error adding exercise: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Olahraga',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).appBarTheme.titleTextStyle?.color,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: Theme.of(context).appBarTheme.elevation ?? 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadExercises,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTodaySummary(),
                      const SizedBox(height: 24),
                      _buildExerciseList(),
                    ],
                  ),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addExercise,
        backgroundColor: Theme.of(context).floatingActionButtonTheme.backgroundColor,
        child: Icon(Icons.add, color: Theme.of(context).floatingActionButtonTheme.foregroundColor),
      ),
    );
  }

  Widget _buildTodaySummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primaryContainer],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withAlpha((0.3 * 255).round()),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kalori Terbakar Hari Ini',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${todayCaloriesBurned.toInt()} kcal',
            style: GoogleFonts.poppins(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Riwayat Olahraga',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
                  '${exercises.length} olahraga',
                  style: GoogleFonts.inter(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
          ],
        ),
        const SizedBox(height: 12),
        exercises.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.fitness_center,
                        size: 64,
                        color: Theme.of(context).disabledColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada olahraga tercatat',
                        style: GoogleFonts.inter(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: exercises.length,
                itemBuilder: (context, index) {
                  var exercise = exercises[index];
                  return _buildExerciseCard(exercise);
                },
              ),
      ],
    );
  }

  Widget _buildExerciseCard(Map<String, dynamic> exercise) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).round()),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primaryContainer],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.fitness_center,
              color: Theme.of(context).colorScheme.onPrimary,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise['exerciseName'] ?? 'Unknown',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${exercise['durationMinutes']} menit',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withAlpha((0.1 * 255).round()),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${exercise['caloriesBurned']?.toInt() ?? 0} kcal',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AddExerciseDialog extends StatefulWidget {
  const AddExerciseDialog({super.key});

  @override
  State<AddExerciseDialog> createState() => _AddExerciseDialogState();
}

class _AddExerciseDialogState extends State<AddExerciseDialog> {
  final _formKey = GlobalKey<FormState>();
  String exerciseName = '';
  int durationMinutes = 30;
  double caloriesBurned = 0;

  final List<Map<String, dynamic>> exerciseTypes = [
    {'name': 'Lari', 'caloriesPerMinute': 8.3},
    {'name': 'Bersepeda', 'caloriesPerMinute': 7.0},
    {'name': 'Renang', 'caloriesPerMinute': 6.0},
    {'name': 'Yoga', 'caloriesPerMinute': 3.0},
    {'name': 'Push-up', 'caloriesPerMinute': 7.0},
    {'name': 'Sit-up', 'caloriesPerMinute': 5.0},
    {'name': 'Jogging', 'caloriesPerMinute': 6.7},
    {'name': 'Basketball', 'caloriesPerMinute': 8.0},
    {'name': 'Sepak Bola', 'caloriesPerMinute': 7.0},
    {'name': 'Tenis', 'caloriesPerMinute': 7.3},
  ];

  void _updateCalories() {
    final selectedExercise = exerciseTypes.firstWhere(
      (e) => e['name'] == exerciseName,
      orElse: () => {'caloriesPerMinute': 5.0},
    );
    setState(() {
      caloriesBurned = (selectedExercise['caloriesPerMinute'] as double) * durationMinutes;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Tambah Olahraga',
        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Jenis Olahraga',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: exerciseTypes.map((exercise) {
                return DropdownMenuItem(
                  value: exercise['name'] as String,
                  child: Text(exercise['name'] as String),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  exerciseName = value!;
                  _updateCalories();
                });
              },
              validator: (value) => value == null ? 'Pilih jenis olahraga' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Durasi (menit)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.number,
              initialValue: durationMinutes.toString(),
              onChanged: (value) {
                durationMinutes = int.tryParse(value) ?? 30;
                _updateCalories();
              },
              validator: (value) {
                if (value == null || value.isEmpty) return 'Masukkan durasi';
                final minutes = int.tryParse(value);
                if (minutes == null || minutes <= 0) return 'Durasi harus lebih dari 0';
                return null;
              },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withAlpha((0.1 * 255).round()),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Kalori Terbakar:',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${caloriesBurned.toInt()} kcal',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
              'Batal',
              style: GoogleFonts.inter(color: Theme.of(context).textTheme.bodySmall?.color),
            ),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop({
                'exerciseName': exerciseName,
                'durationMinutes': durationMinutes,
                'caloriesBurned': caloriesBurned,
                'date': DateTime.now().toIso8601String(),
              });
            }
          },
          style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
          ),
          child: Text(
              'Tambah',
              style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onPrimary),
          ),
        ),
      ],
    );
  }
}
