import 'package:catchspike/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kakao_flutter_sdk_common/kakao_flutter_sdk_common.dart'
    as kakao_sdk;
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'widgets/loading_indicator.dart';

import 'firebase/config/firebase_config.dart';
import 'firebase_options.dart';
import 'screens/home/home_screen.dart';
import 'screens/report/report_screen.dart';
import 'screens/community/community_screen.dart';
import 'screens/achievement/achievement_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'widgets/custom_drawer.dart';
import 'providers/user_provider.dart';
import 'utils/global_keys.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // 1. 환경 변수 로드
    await dotenv.load(fileName: ".env");
    Logger.log("✅ .env 파일을 성공적으로 로드했습니다.");

    // 2. 필수 환경 변수 검증
    _validateEnvironmentVariables();

    // 3. Firebase 초기화 (한 번만 실행)
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      Logger.log("✅ Firebase 초기화 완료");
    }

    // 4. Kakao SDK 초기화
    kakao_sdk.KakaoSdk.init(
      nativeAppKey: dotenv.env['KAKAO_NATIVE_APP_KEY']!,
      javaScriptAppKey: dotenv.env['JAVASCRIPT_APP_KEY'] ?? '',
    );
    Logger.log("✅ Kakao SDK 초기화 완료");

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<UserProvider>(create: (_) => UserProvider()),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e) {
    Logger.log("❌ 초기화 실패: $e");
    rethrow;
  }
}

void _validateEnvironmentVariables() {
  final requiredEnvVars = [
    'KAKAO_NATIVE_APP_KEY',
    'OPENAI_API_KEY',
    'FIREBASE_FUNCTION_URL'
  ];

  for (final envVar in requiredEnvVars) {
    if (dotenv.env[envVar]?.isEmpty ?? true) {
      throw Exception('Required environment variable $envVar is not set');
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CATCHSPIKE',
      theme: ThemeData(
        fontFamily: 'GmarketSans',
        primaryColor: const Color(0xFFE30547),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFE30547),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      // home 속성 제거
      initialRoute: '/', // 초기 라우트 설정
      routes: {
        '/': (context) => Consumer<UserProvider>(
              builder: (context, userProvider, child) {
                return userProvider.user == null
                    ? const OnboardingScreen()
                    : const MainScreen();
              },
            ),
        '/home': (context) => const MainScreen(initialIndex: 0),
        '/report': (context) => const MainScreen(initialIndex: 1),
        '/community': (context) => const MainScreen(initialIndex: 2),
        '/achievement': (context) => const MainScreen(initialIndex: 3),
      },
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: scaffoldMessengerKey,
    );
  }
}

class MainScreen extends StatefulWidget {
  final int? initialIndex;
  const MainScreen({super.key, this.initialIndex});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex ?? 0;
  }

  final List<Widget> _screens = [
    const HomeScreen(),
    const ReportScreen(),
    const CommunityScreen(),
    AchievementsScreen(),
  ];

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
            icon: const Icon(Icons.menu, size: 24),
            onPressed: () {
              _scaffoldKey.currentState?.openEndDrawer();
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      endDrawer: const CustomDrawer(),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              offset: Offset(0, -1),
              blurRadius: 4,
            ),
          ],
        ),
        child: BottomNavigationBar(
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: '홈',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.insert_chart_outlined),
              activeIcon: Icon(Icons.insert_chart),
              label: '리포트',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: '커뮤니티',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events_outlined),
              activeIcon: Icon(Icons.emoji_events),
              label: '성과',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: const Color(0xFFE30547),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: true,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          onTap: _onItemTapped,
          elevation: 0,
        ),
      ),
    );
  }

  @override
  void dispose() {
    // 필요한 리소스 정리
    super.dispose();
  }
}
