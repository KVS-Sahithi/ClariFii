import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:math';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedView;
  late AnimationController _animationController;

  Map<String, double> _budgetLimits = {
    'Weekly': 0,
    'Monthly': 0,
    'Yearly': 0,
  };

  Map<String, List<Map<String, dynamic>>> _expensesByView = {
    'Weekly': [],
    'Monthly': [],
    'Yearly': [],
  };

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  double get _currentLimit =>
      _selectedView == null ? 0 : _budgetLimits[_selectedView!] ?? 0;
  List<Map<String, dynamic>> get _currentExpenses =>
      _selectedView == null ? [] : _expensesByView[_selectedView!]!;
  double get _totalExpense =>
      _currentExpenses.fold(0, (sum, item) => sum + (item['amount'] as num));
  Map<String, double> get _expenseByType {
    Map<String, double> data = {};
    for (var e in _currentExpenses) {
      data[e['type']] = (data[e['type']] ?? 0) + (e['amount'] as num);
    }
    return data;
  }

  String get _summary {
    if (_selectedView == null) return '';
    final expenses = _currentExpenses;
    if (expenses.any((e) => e['title'].toLowerCase().contains('iphone'))) {
      return 'Large iPhone purchase detected. Consider budgeting for luxury items.';
    }
    if (expenses.where((e) => e['type'] == 'Entertainment').length > 2) {
      return 'High entertainment expenses. Consider reducing non-essentials.';
    }
    if (_totalExpense > _currentLimit) {
      return 'You have exceeded your budget! Time to cut down on spending.';
    }
    return 'Spending is within a balanced range. Great work!';
  }

  List<PieChartSectionData> get _pieChartSections {
    final total = _totalExpense;
    final colors = [
      Colors.blue,
      Colors.orange,
      Colors.green,
      Colors.red,
      Colors.purple,
      Colors.teal
    ];
    int colorIndex = 0;
    return _expenseByType.entries.map((entry) {
      final percentage = (entry.value / total) * 100;
      return PieChartSectionData(
        color: colors[colorIndex++ % colors.length],
        value: entry.value,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 50,
        titleStyle: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
  }

  final Map<String, Color> typeColors = {
    'Essential': Colors.blue,
    'Utility': Colors.orange,
    'Entertainment': Colors.green,
    'Luxury': Colors.red,
    'Savings': Colors.purple,
  };

  final Map<String, IconData> typeIcons = {
    'Essential': Icons.shopping_cart,
    'Utility': Icons.lightbulb,
    'Entertainment': Icons.movie,
    'Luxury': Icons.phone_iphone,
    'Savings': Icons.savings,
  };

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 1));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onViewChanged(String? val) async {
    if (val == null) return;
    setState(() {
      _selectedView = val;
      _animationController.reset();
      _animationController.forward();
    });

    final expensesSnapshot = await _firestore
        .collection('expenses')
        .doc(val)
        .collection('items')
        .get();
    final List<Map<String, dynamic>> expenses =
        expensesSnapshot.docs.map((doc) => doc.data()).toList();

    final budgetDoc = await _firestore.collection('budgets').doc(val).get();
    final budgetLimit =
        budgetDoc.exists ? budgetDoc.data()!['limit'] ?? 0.0 : 0.0;

    setState(() {
      _expensesByView[val] = expenses;
      _budgetLimits[val] = budgetLimit.toDouble();
    });
  }

  Future<void> _generateSampleExpenses(String view) async {
    final sampleExpenses = [
      {'title': 'Groceries', 'amount': 50, 'type': 'Essential'},
      {'title': 'Netflix', 'amount': 15, 'type': 'Entertainment'},
      {'title': 'Electricity Bill', 'amount': 40, 'type': 'Utility'},
      {'title': 'iPhone 13', 'amount': 999, 'type': 'Luxury'},
      {'title': 'Public Transport', 'amount': 20, 'type': 'Essential'},
      {'title': 'Gym Membership', 'amount': 30, 'type': 'Utility'},
      {'title': 'Savings Deposit', 'amount': 100, 'type': 'Savings'},
    ];

    final expensesCollection =
        _firestore.collection('expenses').doc(view).collection('items');
    final existing = await expensesCollection.get();
    if (existing.docs.isNotEmpty) return;

    for (var e in sampleExpenses) {
      await expensesCollection.add(e);
    }
  }

  void _showSetLimitDialog() {
    if (_selectedView == null) return;
    final controller = TextEditingController(
        text: _budgetLimits[_selectedView!]?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set Budget for $_selectedView'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Enter budget limit'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final input = double.tryParse(controller.text);
              if (input != null) {
                await _firestore
                    .collection('budgets')
                    .doc(_selectedView!)
                    .set({'limit': input});
                await _generateSampleExpenses(_selectedView!);
                _onViewChanged(_selectedView);
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double progress = _selectedView == null || _currentLimit == 0
        ? 0.0
        : (_totalExpense / _currentLimit).clamp(0, 1).toDouble();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Colorful Dashboard'),
        backgroundColor: Colors.deepPurple,
        actions: [
          if (_selectedView != null)
            IconButton(
                icon: const Icon(Icons.settings),
                onPressed: _showSetLimitDialog,
                tooltip: 'Set Budget Limit'),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  const Text('Select View:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 10),
                  DropdownButton<String>(
                    value: _selectedView,
                    hint: const Text('Choose timeframe'),
                    items: ['Weekly', 'Monthly', 'Yearly'].map((view) {
                      return DropdownMenuItem(value: view, child: Text(view));
                    }).toList(),
                    onChanged: _onViewChanged,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_selectedView == null)
                Expanded(
                  child: Center(
                    child: Text(
                      'Please select Weekly, Monthly, or Yearly to see your dashboard.',
                      style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView(
                    children: [
                      _buildExpenseSummary(progress),
                      const SizedBox(height: 15),
                      _buildPieChart(),
                      const SizedBox(height: 15),
                      _buildExpenseList(),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseSummary(double progress) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient:
            const LinearGradient(colors: [Colors.indigo, Colors.deepPurple]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Expense',
              style: TextStyle(fontSize: 20, color: Colors.white70)),
          const SizedBox(height: 6),
          Text('$_selectedView: \$${_totalExpense.toStringAsFixed(2)}',
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 12),
          Text('Budget Limit: \$${_currentLimit.toStringAsFixed(0)}',
              style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white24,
            valueColor:
                const AlwaysStoppedAnimation<Color>(Colors.yellowAccent),
            minHeight: 12,
          ),
          const SizedBox(height: 6),
          Text(
            progress >= 1
                ? 'Budget exceeded! Time to save!'
                : 'You\'re within your budget.',
            style: TextStyle(
              color: progress >= 1 ? Colors.redAccent : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: Column(
        children: [
          const Text('Expenses Breakdown',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          SizedBox(
            height: 180,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return PieChart(
                  PieChartData(
                    sections: _pieChartSections
                        .map((section) => section.copyWith(
                              value: section.value * _animationController.value,
                              title: _animationController.value == 1
                                  ? section.title
                                  : '',
                            ))
                        .toList(),
                    sectionsSpace: 2,
                    centerSpaceRadius: 30,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Expense Details',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ..._currentExpenses.map((expense) {
          final color = typeColors[expense['type']] ?? Colors.grey;
          final icon = typeIcons[expense['type']] ?? Icons.attach_money;
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              leading: CircleAvatar(
                  backgroundColor: color,
                  child: Icon(icon, color: Colors.white)),
              title: Text(expense['title']),
              subtitle: Text(expense['type']),
              trailing: Text('\$${expense['amount']}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.deepPurple)),
            ),
          );
        }).toList(),
        const SizedBox(height: 20),
        Text(_summary,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87)),
      ],
    );
  }
}
