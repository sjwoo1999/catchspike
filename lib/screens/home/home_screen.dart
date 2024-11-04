// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/logger.dart';
import '../../widgets/loading_indicator.dart'; // Import the LoadingIndicator
import 'components/home_components.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    if (!mounted) return;

    try {
      await Provider.of<UserProvider>(context, listen: false).initializeUser();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      Logger.log('홈 화면 초기화 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('사용자 정보를 불러오는데 실패했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          if (!_isInitialized || userProvider.isLoading) {
            return const LoadingIndicator(); // Use your custom LoadingIndicator here
          }

          // 사용자가 없는 경우
          if (userProvider.user == null) {
            return const Center(
              child: Text('사용자 정보를 찾을 수 없습니다.'),
            );
          }

          return const SafeArea(
            child: HomeContent(),
          );
        },
      ),
    );
  }
}
