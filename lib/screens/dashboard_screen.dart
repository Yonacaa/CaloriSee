import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../database/database_helper.dart';
import '../services/weather_service.dart';
// nutrition_service removed from imports — not used in Dashboard
import 'profile_screen.dart';
import 'camera_screen.dart';
import 'history_screen.dart';
import 'exercise_screen.dart';

class DashboardScreen extends StatefulWidget {
  final int userId;
  const DashboardScreen({super.key, required this.userId});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  Map<String, dynamic>? userData;
  double todayCalories = 0;
  double targetCalories = 2000;
  double targetProtein = 100.0;
  double targetFat = 70.0;
  double targetCarbs = 250.0;
  List<Map<String, dynamic>> recentFoods = [];
  double todayProtein = 0;
  double todayFat = 0;
  double todayCarbs = 0;
  // sugar tracking removed per user request
  WeatherModel? weather;
  bool isLoading = true;
  List<Map<String, dynamic>> favoriteFoods = [];
  double todayCaloriesBurned = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => isLoading = true);

    try {
      DatabaseHelper db = DatabaseHelper();

      userData = await db.getUserById(widget.userId);
      todayCalories = await db.getTodayCalories(widget.userId);
      todayCaloriesBurned = await db.getTodayCaloriesBurned(widget.userId);

      if (userData != null) {
        targetCalories = userData!['targetCalories'] ?? 2000.0;
        targetProtein = userData!['targetProtein'] ?? 100.0;
        targetFat = userData!['targetFat'] ?? 70.0;
        targetCarbs = userData!['targetCarbs'] ?? 250.0;
      }

      List<Map<String, dynamic>> allFoods = await db.getFoodHistory(widget.userId);
      recentFoods = allFoods.take(5).toList();

      // Calculate macros for today
      DateTime now = DateTime.now();
      DateTime startOfDay = DateTime(now.year, now.month, now.day);
      List<Map<String, dynamic>> todays = allFoods.where((f) {
        try {
          DateTime d = DateTime.parse(f['scannedAt']);
          return d.isAfter(startOfDay.subtract(const Duration(seconds: 1)));
        } catch (e) {
          return false;
        }
      }).toList();

      todayProtein = 0;
      todayFat = 0;
      todayCarbs = 0;
      for (var f in todays) {
        todayProtein += (f['protein'] ?? 0).toDouble();
        todayFat += (f['fat'] ?? 0).toDouble();
        todayCarbs += (f['carbs'] ?? 0).toDouble();
        // sugar removed from tracker; ignore any 'sugar' values in DB rows
      }

      favoriteFoods = await db.getFavorites(widget.userId);

      WeatherService weatherService = WeatherService();
      Map<String, dynamic>? weatherData = await weatherService.getCurrentWeather('Jakarta');
      if (weatherData != null) {
        weather = WeatherModel.fromJson(weatherData);
      }

    } catch (e) {
      debugPrint('Error loading dashboard: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget _buildHomeScreen() {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildQuickStats(),
                const SizedBox(height: 24),
                _buildWeatherCard(),
                const SizedBox(height: 24),
                _buildCalorieProgress(),
                const SizedBox(height: 24),
                _buildMacroSummary(),
                const SizedBox(height: 16),
                _buildFavoritesQuickAdd(),
                const SizedBox(height: 24),
                _buildRecentFoods(),
                const SizedBox(height: 80), // Space for FAB
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeScreen(),
          ExerciseScreen(userId: widget.userId),
          HistoryScreen(userId: widget.userId),
          ProfileScreen(userId: widget.userId),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _buildScanButton(),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.1 * 255).round()),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: Theme.of(context).cardColor,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_rounded, 'Home', 0),
              _buildNavItem(Icons.fitness_center_rounded, 'Exercise', 1),
              const SizedBox(width: 60), // Space for FAB
              _buildNavItem(Icons.history_rounded, 'History', 2),
              _buildNavItem(Icons.person_rounded, 'Profile', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).iconTheme.color,
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).textTheme.bodySmall?.color,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanButton() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF6EE7B7), Color(0xFF9AFFC2)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6EE7B7).withAlpha((0.5 * 255).round()),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: IconButton(
        icon: const Icon(Icons.camera_alt, color: Colors.white, size: 32),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CameraScreen(userId: widget.userId),
            ),
          ).then((_) => _loadDashboardData());
        },
      ),
    );
  }

  Widget _buildMacroSummary() {
    double totalMacro = todayProtein + todayFat + todayCarbs;
    double pPct = totalMacro > 0 ? (todayProtein / totalMacro) : 0;
    double fPct = totalMacro > 0 ? (todayFat / totalMacro) : 0;
    double cPct = totalMacro > 0 ? (todayCarbs / totalMacro) : 0;
    Widget macroCardContainer(String label, double grams, double pct, Color color, {EdgeInsets? margin}) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        margin: margin,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.03 * 255).round()),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Label centered and prevented from wrapping into vertical layout
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: 13, color: Theme.of(context).textTheme.bodySmall?.color, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Limit indicator to a fixed width so it can't force overflow
                SizedBox(
                  width: 48,
                  child: CircularPercentIndicator(
                    radius: 24,
                    lineWidth: 5,
                    percent: pct.clamp(0, 1),
                    center: FittedBox(child: Text('${(pct * 100).toInt()}%', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold))),
                    progressColor: color,
                    backgroundColor: Colors.grey[200]!,
                  ),
                ),
                const SizedBox(width: 8),
                // Show number and unit on a single line and allow it to scale down as needed
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text('${grams.toStringAsFixed(0)} g', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            )
          ],
        ),
      );
    }

    // Use Expanded so each card gets equal horizontal space and labels won't wrap vertically
    return Row(
      children: [
        Expanded(child: Padding(padding: const EdgeInsets.only(right: 6), child: macroCardContainer('Protein', todayProtein, pPct, const Color(0xFF6EE7B7)))),
        Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: macroCardContainer('Lemak', todayFat, fPct, const Color(0xFFFBBF24)))),
        Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: macroCardContainer('Karbo', todayCarbs, cPct, const Color(0xFF60A5FA)))),
        // Gula removed per user request
      ],
    );
  }

  Widget _buildHeader() {
    String username = userData?['username'] ?? 'User';
    String greeting = _getGreeting();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$greeting,',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            Text(
              username,
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.headlineMedium?.color ?? const Color(0xFF1F2937),
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () {
            // Navigate to Profile
            setState(() => _currentIndex = 3);
          },
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF6EE7B7), Color(0xFF9AFFC2)],
              ),
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white,
              child: Text(
                username[0].toUpperCase(),
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF6EE7B7),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            '${recentFoods.length}',
            'Foods Today',
            Icons.restaurant_rounded,
            const Color(0xFF60A5FA),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            '${(targetCalories - todayCalories).toInt()}',
            'Remaining',
            Icons.local_fire_department_rounded,
            const Color(0xFFFBBF24),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).round()),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherCard() {
    if (weather == null) return const SizedBox.shrink();

    WeatherService weatherService = WeatherService();
    String icon = weatherService.getWeatherIcon(weather!.condition);
    String recommendation = weatherService.getWeatherRecommendation(
      weather!.temperature,
      weather!.condition,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6EE7B7), Color(0xFF9AFFC2)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6EE7B7).withAlpha((0.3 * 255).round()),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    weather!.city,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    weather!.description,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              Text(
                icon,
                style: const TextStyle(fontSize: 48),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${weather!.temperature.toStringAsFixed(1)}°C',
            style: GoogleFonts.poppins(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha((0.2 * 255).round()),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    recommendation,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalorieProgress() {
    double percentage = todayCalories / targetCalories;
    if (percentage > 1) percentage = 1;

    return Container(
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
      child: Column(
        children: [
          Text(
            'Today\'s Calories',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          CircularPercentIndicator(
            radius: 90,
            lineWidth: 18,
            percent: percentage,
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${todayCalories.toInt()}',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF6EE7B7),
                  ),
                ),
                Text(
                  'kcal',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
            progressColor: const Color(0xFF6EE7B7),
            backgroundColor: const Color(0xFFE2E8F0),
            circularStrokeCap: CircularStrokeCap.round,
            animation: true,
            animationDuration: 1000,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Target: ${targetCalories.toInt()} kcal',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(percentage * 100).toInt()}%',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF6EE7B7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentFoods() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Foods',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _currentIndex = 2),
              child: Text(
                'See All',
                style: GoogleFonts.inter(
                  color: const Color(0xFF6EE7B7),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        recentFoods.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.restaurant_menu,
                        size: 64,
                        color: Theme.of(context).disabledColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No food scanned yet',
                        style: GoogleFonts.inter(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentFoods.length,
                itemBuilder: (context, index) {
                  var food = recentFoods[index];
                  return _buildFoodCard(food);
                },
              ),
      ],
    );
  }

  Widget _buildFavoritesQuickAdd() {
    if (favoriteFoods.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Favorites',
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: favoriteFoods.length,
            itemBuilder: (context, index) {
              var f = favoriteFoods[index];
              return Container(
                width: 180,
                margin: EdgeInsets.only(right: index == favoriteFoods.length - 1 ? 0 : 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withAlpha((0.03 * 255).round()), blurRadius: 8, offset: const Offset(0, 3)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(f['foodName'] ?? '', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text('${(f['calories'] ?? 0).toInt()} kcal', style: GoogleFonts.inter(color: Theme.of(context).textTheme.bodySmall?.color)),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _addFavoriteToHistory(f),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6EE7B7),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text('Add', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () async {
                            DatabaseHelper db = DatabaseHelper();
                            await db.deleteFavorite(f['id']);
                            await _loadDashboardData();
                          },
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _addFavoriteToHistory(Map<String, dynamic> fav) async {
    try {
      DatabaseHelper db = DatabaseHelper();
      await db.addFoodHistory({
        'userId': widget.userId,
        'foodName': fav['foodName'],
        'calories': fav['calories'],
        'protein': fav['protein'],
        'fat': fav['fat'],
        'carbs': fav['carbs'],
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Ditambahkan ke riwayat dari Favorit'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      await _loadDashboardData();
    } catch (e) {
      debugPrint('Error adding favorite to history: $e');
    }
  }

  Widget _buildFoodCard(Map<String, dynamic> food) {
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
              gradient: const LinearGradient(
                colors: [Color(0xFF6EE7B7), Color(0xFF9AFFC2)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.restaurant,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  food['foodName'] ?? 'Unknown',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${food['calories']?.toInt() ?? 0} kcal',
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
              '${food['protein']?.toInt() ?? 0}g P',
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