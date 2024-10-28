// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kakao_flutter_sdk_common/kakao_flutter_sdk_common.dart';
import 'package:provider/provider.dart';

import 'screens/home/home_screen.dart';
import 'screens/calendar/calendar_screen.dart';
import 'screens/record/record_screen.dart';
import 'screens/map/map_screen.dart';
import 'widgets/custom_drawer.dart';
import 'utils/theme.dart';
import 'providers/user_provider.dart';
import 'utils/global_keys.dart'; // GlobalKey import

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 환경 변수 로드
  try {
    await dotenv.load(fileName: ".env");
    print("✅ .env 파일을 성공적으로 로드했습니다.");
  } catch (e) {
    print("❌ .env 파일 로드 실패: $e");
  }

  // Kakao SDK 초기화
  KakaoSdk.init(
    nativeAppKey: dotenv.env['KAKAO_NATIVE_APP_KEY'] ?? '',
    javaScriptAppKey: dotenv.env['JAVASCRIPT_APP_KEY'] ?? '',
  );

  // 앱 실행
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<UserProvider>(create: (_) => UserProvider()),
        // 다른 프로바이더들을 여기에 추가하세요.
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
        primaryColor: const Color(0xFFE30547), // #E30547 색상 설정
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFE30547),
          foregroundColor: Colors.white, // AppBar 텍스트 색상
          elevation: 0,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500, // 글자 굵기 조정
            fontFamily: 'GmarketSans',
          ),
        ),
      ),
      home: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          Provider.of<UserProvider>(context).addListener(() {
            print('UserProvider 상태 변경됨');
            print(
                '현재 사용자: ${Provider.of<UserProvider>(context, listen: false).user?.id}');
          });
          return MainScreen();
        },
      ),
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: scaffoldMessengerKey,
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _selectedIndex = 0;

  final List<Widget> _screens = [
    HomeScreen(),
    CalendarScreen(),
    RecordScreen(),
    MapScreen(),
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
              icon: Icon(Icons.home),
              label: '홈',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month),
              label: '달력',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.timer),
              label: '기록',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map),
              label: '지도',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: Colors.grey,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
        ),
      ),
    );
  }
}
