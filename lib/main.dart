import 'dart:io'; // For Directory
import 'package:catchspike/widgets/custom_drawer.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kReleaseMode
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:kakao_flutter_sdk_common/kakao_flutter_sdk_common.dart'
    as kakao_sdk;
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase/config/firebase_config.dart';
import 'providers/user_provider.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/home/home_screen.dart';
import 'utils/global_keys.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. 실행 환경에 따른 환경 파일 설정
  final environment = const String.fromEnvironment(
    'ENV',
    defaultValue: 'development', // 기본값은 개발 환경
  );
  final fileName = '.env.$environment';
  print("📂 로드할 환경 파일: $fileName");

  try {
    await dotenv.load(fileName: fileName);
    print("✅ 환경 파일 로드 성공: $fileName");
    dotenv.env.forEach((key, value) {
      print("🔑 $key: $value");
    });
  } catch (e) {
    print("❌ 환경 파일 로드 실패: $e");
    rethrow;
  }

  // 2. 현재 실행된 환경 출력
  final firebaseEnv = dotenv.env['FIREBASE_ENV'] ?? 'UNKNOWN';
  print("🌍 실행된 환경: ${firebaseEnv.toUpperCase()}");

  // 3. 환경 변수 검증
  _validateEnvironmentVariables(firebaseEnv);

  // 4. Firebase 초기화
  if (Firebase.apps.isEmpty) {
    try {
      await Firebase.initializeApp(
        options: FirebaseConfig.currentPlatform,
      );
      print("✅ Firebase 초기화 완료");
    } catch (e) {
      print("❌ Firebase 초기화 실패: $e");
      rethrow;
    }

    // Firebase Emulator 설정 (개발 환경에서만)
    if (firebaseEnv == 'development' &&
        dotenv.env['USE_FIREBASE_EMULATOR'] == 'true') {
      print("⚙️ 개발 환경: Firebase Emulator 설정 중...");

      FirebaseFirestore.instance.settings = Settings(
        host:
            '${dotenv.env['FIREBASE_EMULATOR_HOST']}:${dotenv.env['FIREBASE_FIRESTORE_PORT'] ?? '8080'}',
        sslEnabled: false,
        persistenceEnabled: false,
      );
      FirebaseFunctions.instance.useFunctionsEmulator(
        dotenv.env['FIREBASE_EMULATOR_HOST'] ?? '127.0.0.1',
        int.parse(dotenv.env['FIREBASE_FUNCTIONS_PORT'] ?? '5001'),
      );
      FirebaseStorage.instance.useStorageEmulator(
        dotenv.env['FIREBASE_EMULATOR_HOST'] ?? '127.0.0.1',
        int.parse(dotenv.env['FIREBASE_STORAGE_PORT'] ?? '9199'),
      );
      print("🔥 Firebase Emulator 설정 완료");
    }
  }

  // 6. Kakao SDK 초기화
  kakao_sdk.KakaoSdk.init(
    nativeAppKey: FirebaseConfig.kakaoNativeKey,
    javaScriptAppKey: FirebaseConfig.kakaoJavaScriptKey,
  );
  print("✅ Kakao SDK 초기화 완료");

  // 7. 앱 실행
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

// 환경 변수 검증 함수
void _validateEnvironmentVariables(String environment) {
  final commonEnvVars = [
    'FIREBASE_ENV',
    'FIREBASE_ANDROID_API_KEY',
    'FIREBASE_IOS_API_KEY',
    'GET_CUSTOM_TOKEN_URL',
  ];

  final developmentEnvVars = [
    'USE_FIREBASE_EMULATOR',
    'FIREBASE_EMULATOR_HOST',
    'FIREBASE_FIRESTORE_PORT',
    'FIREBASE_FUNCTIONS_PORT',
    'FIREBASE_STORAGE_PORT',
  ];

  final productionEnvVars = [
    'ANALYZE_FOOD_IMAGE_URL',
    'HEALTH_CHECK_URL',
  ];

  final requiredEnvVars = [
    ...commonEnvVars,
    if (environment == 'development') ...developmentEnvVars,
    if (environment == 'production') ...productionEnvVars,
  ];

  for (final envVar in requiredEnvVars) {
    if (dotenv.env[envVar]?.isEmpty ?? true) {
      throw Exception('⚠️ Required environment variable $envVar is not set');
    }
  }

  print("✅ 모든 필수 환경 변수가 설정되었습니다.");
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
      initialRoute: '/', // 초기 라우트 설정
      routes: {
        '/': (context) => const OnboardingScreen(),
        '/home': (context) => const HomeScreen(),
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

    final environment = dotenv.env['FIREBASE_ENV'] ?? 'production';
    print("📱 MainScreen 실행 중 - 환경: ${environment.toUpperCase()}");
  }

  final List<Widget> _screens = [
    const HomeScreen(),
    const OnboardingScreen(), // Placeholder
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
      bottomNavigationBar: BottomNavigationBar(
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
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFFE30547),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
