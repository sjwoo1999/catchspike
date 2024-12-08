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
    // 빌드가 완료된 후 초기화 실행
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeUser();
    });
  }

  Future<void> _initializeUser() async {
    if (!mounted) return;

    try {
      final userProvider = context.read<UserProvider>();

      // 이미 초기화되었거나 로딩 중인 경우 중복 실행 방지
      if (_isInitialized || userProvider.isLoading) return;

      await userProvider.initializeUser();

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
    // 인증 관련 에러 확인 및 처리
    if (error.toString().contains("authentication token doesn't exist") ||
        error.toString().contains("KakaoClientException")) {
      _navigateToOnboarding();
    } else {
      _showErrorSnackBar();
    }
  }

  void _navigateToOnboarding() {
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      (route) => false,
    );
  }

  void _showErrorSnackBar() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('사용자 정보를 불러오는데 실패했습니다. 다시 시도해주세요.'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _navigateToMealRecord() {
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MealRecordScreen(),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return const Scaffold(
      body: Center(
        child: LoadingIndicator(),
      ),
    );
  }

  Widget _buildHomeContent() {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Expanded(
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
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        // 초기화 중이거나 로딩 중인 경우 로딩 화면 표시
        if (!_isInitialized || userProvider.isLoading) {
          return _buildLoadingScreen();
        }

        // 사용자가 없는 경우 온보딩 화면으로 이동
        if (userProvider.user == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _navigateToOnboarding();
          });
          return _buildLoadingScreen();
        }

        // 메인 홈 화면 표시
        return _buildHomeContent();
      },
    );
  }
}
