import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../database/database_helper.dart';
import '../models/food_model.dart';

class HistoryScreen extends StatefulWidget {
  final int userId;
  
  const HistoryScreen({super.key, required this.userId});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<FoodModel> foodHistory = [];
  bool isLoading = true;
  String selectedFilter = 'all'; // all, today, week, month

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => isLoading = true);
    
    try {
      DatabaseHelper db = DatabaseHelper();
      List<Map<String, dynamic>> data = await db.getFoodHistory(widget.userId);
      
      setState(() {
        foodHistory = data.map((map) => FoodModel.fromMap(map)).toList();
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading history: $e');
      setState(() => isLoading = false);
    }
  }

  List<FoodModel> get filteredHistory {
    DateTime now = DateTime.now();
    
    switch (selectedFilter) {
      case 'today':
        return foodHistory.where((food) {
          DateTime foodDate = DateTime.parse(food.scannedAt!);
          return foodDate.year == now.year &&
                 foodDate.month == now.month &&
                 foodDate.day == now.day;
        }).toList();
      
      case 'week':
        DateTime weekAgo = now.subtract(const Duration(days: 7));
        return foodHistory.where((food) {
          DateTime foodDate = DateTime.parse(food.scannedAt!);
          return foodDate.isAfter(weekAgo);
        }).toList();
      
      case 'month':
        return foodHistory.where((food) {
          DateTime foodDate = DateTime.parse(food.scannedAt!);
          return foodDate.year == now.year && foodDate.month == now.month;
        }).toList();
      
      default:
        return foodHistory;
    }
  }

  double get totalCalories {
    return filteredHistory.fold(0, (sum, food) => sum + food.calories);
  }

  Map<String, double> get nutritionTotals {
    double protein = 0, fat = 0, carbs = 0;
    double sugar = 0;
    for (var food in filteredHistory) {
      protein += food.protein;
      fat += food.fat;
      carbs += food.carbs;
      sugar += food.sugar;
    }
    return {'protein': protein, 'fat': fat, 'carbs': carbs, 'sugar': sugar};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Food History',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHistory,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFilterTabs(),
                _buildStatsCard(),
                Expanded(child: _buildHistoryList()),
              ],
            ),
    );
  }

  Widget _buildFilterTabs() {
    final filters = [
      {'id': 'all', 'name': 'All Time'},
      {'id': 'today', 'name': 'Today'},
      {'id': 'week', 'name': 'This Week'},
      {'id': 'month', 'name': 'This Month'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).cardColor,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            bool isSelected = selectedFilter == filter['id'];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => selectedFilter = filter['id']!),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    filter['name']!,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    final totals = nutritionTotals;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
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
            'Total Calories',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${totalCalories.toInt()} kcal',
            style: GoogleFonts.poppins(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: PieChart(
              PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: [
                      PieChartSectionData(
                        value: totals['protein'],
                        title: '${totals['protein']!.toInt()}g',
                        color: Theme.of(context).colorScheme.primary,
                        radius: 45,
                        titleStyle: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                      PieChartSectionData(
                        value: totals['fat'],
                        title: '${totals['fat']!.toInt()}g',
                        color: const Color(0xFFFBBF24),
                        radius: 45,
                        titleStyle: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                      PieChartSectionData(
                        value: totals['carbs'],
                        title: '${totals['carbs']!.toInt()}g',
                        color: const Color(0xFF60A5FA),
                        radius: 45,
                        titleStyle: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                      PieChartSectionData(
                        value: totals['sugar'],
                        title: '${totals['sugar']!.toInt()}g',
                        color: const Color(0xFFFB7185),
                        radius: 45,
                        titleStyle: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem('Protein', Theme.of(context).colorScheme.primary),
              _buildLegendItem('Fat', const Color(0xFFFBBF24)),
              _buildLegendItem('Carbs', const Color(0xFF60A5FA)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryList() {
    if (filteredHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 64,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No food history',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            Text(
              'Start scanning your meals!',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredHistory.length,
      itemBuilder: (context, index) {
        final food = filteredHistory[index];
        return _buildFoodCard(food);
      },
    );
  }

  Widget _buildFoodCard(FoodModel food) {
    return Dismissible(
      key: Key(food.id.toString()),
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.error,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.delete, color: Theme.of(context).colorScheme.onError, size: 32),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) async {
          DatabaseHelper db = DatabaseHelper();
          await db.deleteFoodHistory(food.id!);

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${food.foodName} deleted'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );

          _loadHistory();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.05 * 255).round()),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                    Icons.restaurant,
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
                      food.foodName,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${food.calories.toInt()} kcal • P: ${food.protein.toInt()}g • F: ${food.fat.toInt()}g • C: ${food.carbs.toInt()}g',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      food.formattedDate,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}