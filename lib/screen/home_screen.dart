import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_finanzas/config/global.dart';
import 'package:app_finanzas/widgets/gradient_button.dart';
import 'package:app_finanzas/screen/auth/login_screen.dart';
import 'package:app_finanzas/app/controller/auth_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void _logout() {
    context.read<AuthProvider>().logout(context);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (!authProvider.isAuthenticated) {
      Future.microtask(() {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      });
    }

    return Scaffold(
      backgroundColor: ConfigGlobal.secondTextColor,
      appBar: AppBar(title: const Text("Inicio")),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildWelcomeText(),
              const SizedBox(height: 20),
              GradientButton(
                onPressed: _logout,
                label: "Cerrar Sesión",
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeText() {
    return const Text(
      "Bienvenido a la aplicación de finanzas",
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: ConfigGlobal.sizeTitle,
        color: ConfigGlobal.primaryTextColor,
      ),
    );
  }
}
