import 'package:flutter/material.dart';
import 'dart:convert';
// import 'package:http/http.dart' as http; // Uncomment when connecting to your real Flask API

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stats Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      // CRITICAL: Always explicitly set initialRoute and map it in routes
      initialRoute: '/',
      routes: {
        '/': (context) => const StatsDashboardScreen(),
      },
    );
  }
}

class StatsDashboardScreen extends StatefulWidget {
  const StatsDashboardScreen({super.key});

  @override
  State<StatsDashboardScreen> createState() => _StatsDashboardScreenState();
}

class _StatsDashboardScreenState extends State<StatsDashboardScreen> {
  Map<String, dynamic>? _statsData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // --- REAL API CALL EXAMPLE ---
      // To connect to your local Flask app, you would use the http package:
      // final response = await http.get(Uri.parse('http://127.0.0.1:5000/stats'));
      // if (response.statusCode == 200) {
      //   setState(() {
      //     _statsData = json.decode(response.body);
      //     _isLoading = false;
      //   });
      // } else {
      //   throw Exception('Failed to load stats');
      // }
      
      // --- MOCK API CALL FOR PREVIEW ---
      // Simulating network delay so you can see the loading state
      await Future.delayed(const Duration(seconds: 1));
      
      // Simulating the exact JSON response your Flask app would return
      final mockJson = '''
      {
          "avg_goals_home": 1.85,
          "avg_goals_away": 1.12,
          "result_distribution": {
              "Home Win": 48.5,
              "Draw": 24.2,
              "Away Win": 27.3
          }
      }
      ''';
      
      if (mounted) {
        setState(() {
          _statsData = json.decode(mockJson);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Match Statistics'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchStats,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text('Error: $_errorMessage', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchStats,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_statsData == null) {
      return const Center(child: Text('No data available'));
    }

    final homeGoals = _statsData!['avg_goals_home'] as double;
    final awayGoals = _statsData!['avg_goals_away'] as double;
    final distribution = _statsData!['result_distribution'] as Map<String, dynamic>;

    return RefreshIndicator(
      onRefresh: _fetchStats,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Average Goals',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Home',
                    value: homeGoals.toStringAsFixed(2),
                    icon: Icons.home,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _StatCard(
                    title: 'Away',
                    value: awayGoals.toStringAsFixed(2),
                    icon: Icons.flight_takeoff,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              'Result Distribution',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: distribution.entries.map((entry) {
                    return _DistributionRow(
                      label: entry.key,
                      percentage: (entry.value as num).toDouble(),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DistributionRow extends StatelessWidget {
  final String label;
  final double percentage;

  const _DistributionRow({
    required this.label,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    // Determine color based on label for visual flair
    Color barColor = Colors.grey;
    if (label.toLowerCase().contains('home')) barColor = Colors.blue;
    if (label.toLowerCase().contains('away')) barColor = Colors.orange;
    if (label.toLowerCase().contains('draw')) barColor = Colors.green;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey[200],
            color: barColor,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}
