import 'package:app_finanzas/config/pallete.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:app_finanzas/screen/home_screen.dart';
import 'package:app_finanzas/screen/auth/login_screen.dart';
import 'package:app_finanzas/app/controller/auth_provider.dart';
import 'package:app_finanzas/app/controller/transactions_provider.dart';
import 'package:app_finanzas/app/controller/category_expense_provider.dart';

Future<void> main() async {
  await dotenv.load(); // Carga las variables de entorno
  WidgetsFlutterBinding.ensureInitialized(); // Asegura que el framework esté inicializado
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky); // Full screen
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TransactionsProvider()),
        ChangeNotifierProvider(create: (_) => CategoryExpenseProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Gestiona tus finanzas',
            /* theme: ThemeData(
              colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue),
              useMaterial3: true,
            ), */
            theme: ThemeData.dark().copyWith(
              scaffoldBackgroundColor: Pallete.backgroundColor,
            ),
            home: authProvider.isAuthenticated ? const HomeScreen() : const LoginScreen(),
          );
        },
      ),
    );
  }
}
