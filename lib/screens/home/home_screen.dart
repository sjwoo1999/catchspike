import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/logger.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/custom_drawer.dart'; // CustomDrawer import
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
  int _selectedIndex = 0; // 네비게이션 바 인덱스
  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>(); // 추가

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeUser();
    });
  }

  Future<void> _initializeUser() async {
    if (!mounted) return;

    try {
      final userProvider = context.read<UserProvider>();

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
    return Column(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        if (!_isInitialized || userProvider.isLoading) {
          return _buildLoadingScreen();
        }

        if (userProvider.user == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _navigateToOnboarding();
          });
          return _buildLoadingScreen();
        }

        return Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            title: const Text(
              'CATCHSPIKE',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  _scaffoldKey.currentState?.openEndDrawer(); // 우측 Drawer 열기
                },
              ),
            ],
          ),
          endDrawer: const CustomDrawer(), // endDrawer로 우측 Drawer 설정
          body: Stack(
            children: [
              IndexedStack(
                index: _selectedIndex,
                children: [
                  const HomeContent(),
                  const Placeholder(), // 리포트 화면
                  const Placeholder(), // 설정 화면
                  const Placeholder(), // 기타 화면
                ],
              ),
              if (_selectedIndex == 0)
                Positioned(
                  bottom: 16.0,
                  left: 16.0,
                  right: 16.0,
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
          bottomNavigationBar: BottomNavigationBar(
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: '홈',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart_outlined),
                activeIcon: Icon(Icons.bar_chart),
                label: '리포트',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                activeIcon: Icon(Icons.settings),
                label: '설정',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.more_horiz),
                activeIcon: Icon(Icons.more_horiz),
                label: '기타',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: const Color(0xFFE30547),
            unselectedItemColor: Colors.grey,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
        );
      },
    );
  }
}
