import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_finanzas/config/global.dart';
import 'package:app_finanzas/screen/auth/login_screen.dart';
import 'package:app_finanzas/app/controller/auth_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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

    final List<Widget> screens = [
      _buildHomeScreen(),
      _buildSettingsScreen(authProvider),
    ];

    return Theme(
      data: ThemeData.light().copyWith(
        scaffoldBackgroundColor: Colors.white, // Mismo fondo para todas las vistas
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Finanzas"),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white, // Color del texto en el AppBar
        ),
        body: SafeArea(child: screens[_selectedIndex]),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: "Inicio",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: "Configuración",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "Bienvenido a la aplicación de finanzas",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: ConfigGlobal.sizeTitle,
                color: Colors.black, // Texto en color oscuro para el fondo claro
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsScreen(AuthProvider authProvider) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Configuración",
            style: TextStyle(
              fontSize: ConfigGlobal.sizeTitle,
              fontWeight: FontWeight.bold,
              color: Colors.black, // Texto en color oscuro
            ),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.person),
            title: Text(authProvider.currentUser?.firstname ?? "Usuario"),
            subtitle: Text(authProvider.currentUser?.email ?? "Correo no disponible"),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.red),
            title: const Text("Cerrar Sesión"),
            onTap: () {
              authProvider.logout(context);
            },
          ),
        ],
      ),
    );
  }
}
