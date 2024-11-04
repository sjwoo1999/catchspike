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
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
    Logger.log("✅ .env 파일을 성공적으로 로드했습니다.");

    // Kakao SDK 초기화
    kakao_sdk.KakaoSdk.init(
      nativeAppKey: dotenv.env['KAKAO_NATIVE_APP_KEY'],
      javaScriptAppKey: dotenv.env['JAVASCRIPT_APP_KEY'] ?? '',
    );

    // Firebase 초기화
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
  } catch (e) {
    Logger.log("❌ 초기화 실패: $e");
    rethrow;
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
      routes: {
        "/home": (context) => const MainScreen(), // Add this route
      },
      home: FutureBuilder(
        future: Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Consumer<UserProvider>(
              builder: (context, userProvider, child) {
                // Check user state
                if (userProvider.user == null) {
                  // If user is not logged in, redirect to onboarding
                  return OnboardingScreen();
                }
                return const MainScreen(); // Navigate to main screen if logged in
              },
            );
          }
          return const LoadingIndicator(); // Show loading UI while waiting for Firebase initialization
        },
      ),
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
