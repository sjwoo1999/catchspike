import 'package:catchspike/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kakao_flutter_sdk_common/kakao_flutter_sdk_common.dart'
    as kakao_sdk;
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'screens/home/home_screen.dart';
import 'screens/report/report_screen.dart';
import 'screens/community/community_screen.dart';
import 'screens/achievement/achievement_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'widgets/custom_drawer.dart';
import 'providers/user_provider.dart';
import 'utils/global_keys.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
    Logger.log("✅ .env 파일을 성공적으로 로드했습니다.");

    final functionUrl = dotenv.env['FIREBASE_FUNCTION_URL'];
    final kakaoNativeKey = dotenv.env['KAKAO_NATIVE_APP_KEY'];
    final googleApiKey = dotenv.env['GOOGLE_API_KEY']; // Google API 키 추가

    Logger.log("Function URL: $functionUrl");
    Logger.log("Kakao Native Key: $kakaoNativeKey");
    Logger.log("Google API Key: $googleApiKey"); // Google API 키 로깅

    if (functionUrl == null || functionUrl.isEmpty) {
      throw Exception('FIREBASE_FUNCTION_URL이 설정되지 않았습니다.');
    }
    if (googleApiKey == null || googleApiKey.isEmpty) {
      throw Exception('GOOGLE_API_KEY가 설정되지 않았습니다.');
    }
  } catch (e) {
    Logger.log("❌ .env 파일 또는 환경변수 로드 실패: $e");
  }

  kakao_sdk.KakaoSdk.init(
    nativeAppKey: dotenv.env['KAKAO_NATIVE_APP_KEY'] ?? '',
    javaScriptAppKey: dotenv.env['JAVASCRIPT_APP_KEY'] ?? '',
  );

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<UserProvider>(create: (_) => UserProvider()),
      ],
      child: const MyApp(),
    ),
  );
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
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            fontFamily: 'GmarketSans',
          ),
        ),
      ),
      routes: {
        "/": (context) => Consumer<UserProvider>(
              builder: (context, userProvider, child) {
                userProvider.addListener(() {
                  Logger.log('UserProvider 상태 변경됨');
                  Logger.log('현재 사용자: ${userProvider.user?.id}');
                });

                return userProvider.user == null
                    ? OnboardingScreen()
                    : const MainScreen();
              },
            ),
        "/home": (context) => const MainScreen(), // "/home" 경로 추가
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/') {
          final int? index = settings.arguments as int?;
          return MaterialPageRoute(
            builder: (context) => MainScreen(initialIndex: index),
          );
        }
        return null;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('CATCHSPIKE'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
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
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
              switch (index) {
                case 0:
                  Navigator.pushNamed(context, '/home');
                  break;
                case 1:
                  Navigator.pushNamed(context, '/report');
                  break;
                case 2:
                  Navigator.pushNamed(context, '/community');
                  break;
                case 3:
                  Navigator.pushNamed(context, '/achievement');
                  break;
              }
            });
          },
        ),
      ),
    );
  }
}
