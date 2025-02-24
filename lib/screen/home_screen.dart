import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_finanzas/config/global.dart';
import 'package:app_finanzas/screen/auth/login_screen.dart';
import 'package:app_finanzas/app/controller/auth_provider.dart';
import 'package:app_finanzas/screen/transaction/transaction_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (!authProvider.isAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          });
        }

        final List<Widget> screens = [
          _buildHomeScreen(),
          const TransactionScreen(showAppBar: false),
          _buildExpenseCategoryScreen(),
          _buildSettingsScreen(authProvider),
        ];

        return Theme(
          data: ThemeData.light().copyWith(
            scaffoldBackgroundColor: ConfigGlobal.backgroundSecondColor,
          ),
          child: Scaffold(
            appBar: _buildAppBar(),
            body: SafeArea(child: screens[_selectedIndex]),
            bottomNavigationBar: _buildBottomNavigationBar(),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text("Finanzas"),
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Inicio"),
        BottomNavigationBarItem(
            icon: Icon(Icons.money_outlined), label: "Transacciones"),
        BottomNavigationBarItem(
            icon: Icon(Icons.tag), label: "Gastos Categoría"),
        BottomNavigationBarItem(
            icon: Icon(Icons.settings), label: "Configuración"),
      ],
    );
  }

  Widget _buildHomeScreen() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Text(
          "Bienvenido a la aplicación de finanzas",
          textAlign: TextAlign.center,
          style:
              TextStyle(fontSize: ConfigGlobal.sizeTitle, color: Colors.black),
        ),
      ),
    );
  }

  /* Widget _buildTransactionScreen() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: List.generate(5, (index) => _buildTransactionItem(index)),
    );
  }

  Widget _buildTransactionItem(int index) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        leading: const Icon(Icons.attach_money, color: Colors.green),
        title: Text("Transacción #$index"),
        subtitle: Text("Monto: \$${(index + 1) * 100}"),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  } */

  Widget _buildExpenseCategoryScreen() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: List.generate(5, (index) => _buildExpenseCategoryItem(index)),
    );
  }

  Widget _buildExpenseCategoryItem(int index) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        leading: const Icon(Icons.category, color: Colors.blue),
        title: Text("Categoría de Gasto #$index"),
        subtitle: Text("Presupuesto asignado: \$${(index + 1) * 200}"),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 3,
            child: ListTile(
              leading: const Icon(Icons.person),
              title: Text(authProvider.currentUser?.fullName ?? "Usuario"),
              subtitle: Text(
                  authProvider.currentUser?.email ?? "Correo no disponible"),
            ),
          ),
          const Divider(),
          Card(
            elevation: 3,
            child: ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.red),
              title: const Text("Cerrar Sesión"),
              onTap: () => authProvider.logout(context),
            ),
          ),
        ],
      ),
    );
  }
}
