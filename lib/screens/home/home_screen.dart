// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/logger.dart';
import '../../widgets/loading_indicator.dart';
import 'components/home_components.dart';
import '../onboarding/onboarding_screen.dart';
import '../meal/meal_record_screen.dart';

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
        _handleAuthError(e);
      }
    }
  }

  void _handleAuthError(dynamic error) {
    // Check for authentication errors
    if (error.toString().contains("authentication token doesn't exist") ||
        error.toString().contains("KakaoClientException")) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
          (route) => false,
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('사용자 정보를 불러오는데 실패했습니다. 다시 시도해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToMealRecord() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MealRecordScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        // Show loading indicator while initializing or loading
        if (!_isInitialized || userProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: LoadingIndicator(),
            ),
          );
        }

        // Check for null user and redirect to onboarding
        if (userProvider.user == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const OnboardingScreen()),
              (route) => false,
            );
          });
          return const Scaffold(
            body: Center(
              child: LoadingIndicator(),
            ),
          );
        }

        // Show home content if user exists
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: HomeContent(),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: _navigateToMealRecord,
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
                      children: const [
                        Icon(Icons.camera_alt),
                        SizedBox(width: 8),
                        Text(
                          '식사 기록하기',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
