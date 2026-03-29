import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

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

  // Set this to true when your Flask server is running!
  // Note: If using Android Emulator, change 127.0.0.1 to 10.0.2.2
  final bool _useRealApi = false; 
  final String _apiUrl = 'http://127.0.0.1:5000/stats';

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
      if (_useRealApi) {
        final response = await http.get(Uri.parse(_apiUrl));
        if (response.statusCode == 200) {
          if (mounted) {
            setState(() {
              _statsData = json.decode(response.body);
              _isLoading = false;
            });
          }
        } else {
          throw Exception('Failed to load stats: HTTP ${response.statusCode}');
        }
      } else {
        // Mock data for preview
        await Future.delayed(const Duration(seconds: 1));
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

    final homeGoals = (_statsData!['avg_goals_home'] as num).toDouble();
    final awayGoals = (_statsData!['avg_goals_away'] as num).toDouble();
    final distribution = _statsData!['result_distribution'] as Map<String, dynamic>;

    return RefreshIndicator(
      onRefresh: _fetchStats,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_useRealApi)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Currently showing mock data. Set _useRealApi = true in code to connect to your Flask backend.',
                        style: TextStyle(color: Colors.deepOrange),
                      ),
                    ),
                  ],
                ),
              ),
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
                padding: const EdgeInsets.all(24.0),
                child: SizedBox(
                  height: 200,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                            sections: _getPieChartSections(distribution),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 2,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: distribution.entries.map((entry) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: _LegendWidget(
                                label: entry.key,
                                color: _getColorForLabel(entry.key),
                                value: (entry.value as num).toDouble(),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForLabel(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('home')) return Colors.blue;
    if (lower.contains('away')) return Colors.orange;
    if (lower.contains('draw')) return Colors.green;
    return Colors.grey;
  }

  List<PieChartSectionData> _getPieChartSections(Map<String, dynamic> distribution) {
    return distribution.entries.map((entry) {
      final value = (entry.value as num).toDouble();
      return PieChartSectionData(
        color: _getColorForLabel(entry.key),
        value: value,
        title: '${value.toStringAsFixed(1)}%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
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

class _LegendWidget extends StatelessWidget {
  final String label;
  final Color color;
  final double value;

  const _LegendWidget({
    required this.label,
    required this.color,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
