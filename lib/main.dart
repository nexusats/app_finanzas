import 'package:app_finanzas/config/pallete.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:app_finanzas/screen/home_screen.dart';
import 'package:app_finanzas/screen/auth/login_screen.dart';

import 'package:app_finanzas/app/controller/auth_provider.dart';
import 'package:app_finanzas/app/controller/account_provider.dart';
import 'package:app_finanzas/app/controller/category_provider.dart';
import 'package:app_finanzas/app/controller/transactions_provider.dart';
import 'package:app_finanzas/app/controller/connectivity_provider.dart';
import 'package:app_finanzas/app/services/local/local_database.dart';

import 'package:app_finanzas/widgets/global_loading_overlay.dart';

Future<void> main() async {
  const String envFile = bool.fromEnvironment('dart.vm.product')
      ? ".env.production"
      : ".env.development";

  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: envFile);
  await LocalDatabase.init();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  ));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TransactionsProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => AccountProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Gestiona tus finanzas',
            themeMode: ThemeMode.system,
            theme: ThemeData(
              useMaterial3: true,
              colorSchemeSeed: Pallete.accentColor,
              brightness: Brightness.light,
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorSchemeSeed: Pallete.accentColor,
              brightness: Brightness.dark,
              scaffoldBackgroundColor: Pallete.backgroundColor,
            ),
            builder: (context, child) {
              return GlobalLoadingOverlay(
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: authProvider.isAuthenticated
                ? const HomeScreen()
                : const LoginScreen(),
          );
        },
      ),
    );
  }
}
