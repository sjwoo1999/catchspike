import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../components/meal_history.dart';

class MealHistoryScreen extends StatefulWidget {
  const MealHistoryScreen({super.key});

  @override
  _MealHistoryScreenState createState() => _MealHistoryScreenState();
}

class _MealHistoryScreenState extends State<MealHistoryScreen> {
  DateTime _selectedDate = DateTime.now();
  List<Meal> _meals = [];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: const Color(0xFFE30547),
            colorScheme: ColorScheme.light(
                primary: const Color(0xFFE30547),
                secondary: const Color(0xFFE30547)),
            buttonTheme:
                const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchMealHistory();
    }
  }

  Future<void> _fetchMealHistory() async {
    // Firestore에서 선택한 날짜의 데이터를 가져오기
    String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    QuerySnapshot snapshot = await firestore
        .collection('meal_history')
        .where('date', isEqualTo: formattedDate)
        .get();

    setState(() {
      _meals = snapshot.docs.map((doc) {
        return Meal(
          time: doc['time'],
          menu: doc['menu'],
          calories: doc['calories'],
          healthScore: doc['healthScore'],
          imageUrl: doc['imageUrl'],
        );
      }).toList();
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchMealHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('식사 기록'),
        backgroundColor: const Color(0xFFE30547),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: () => _selectDate(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_today, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    '${DateFormat('yyyy년 MM월 dd일').format(_selectedDate)} 날짜 선택',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _meals.isEmpty
                  ? const Center(child: Text('해당 날짜에 기록된 식사가 없습니다.'))
                  : ListView(
                      children: [
                        MealHistoryCard(
                          meals: _meals,
                          onTap: () {},
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
