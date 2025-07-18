import 'package:shimmer/shimmer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_finanzas/config/global.dart';
import 'package:app_finanzas/screen/auth/login_screen.dart';
import 'package:app_finanzas/app/controller/auth_provider.dart';
import 'package:app_finanzas/app/controller/transactions_provider.dart';
import 'package:app_finanzas/screen/category/category_list_screen.dart';
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
          const CategoryListScreen(),
          // _buildExpenseCategoryScreen(),
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
    return Consumer<TransactionsProvider>(
      builder: (context, provider, _) {

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Resumen financiero",
                style: TextStyle(
                  fontSize: ConfigGlobal.sizeTitle,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: /* GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.1,
                  children: [
                    _buildFinanceCard("Gastos", provider.getTotalExpenses(), Icons.trending_down, Colors.red),
                    _buildFinanceCard("Ingresos", provider.getTotalIncomes(), Icons.trending_up, Colors.green),
                    _buildFinanceCard("Ahorros", provider.getTotalSavings(), Icons.savings, Colors.blue),
                    _buildFinanceCard("Balance", provider.getBalance(), Icons.balance, Colors.purple),
                  ],
                ), */
                provider.isLoading
                  ? GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1.1,
                      children: List.generate(4, (_) => buildFinanceCardSkeleton()),
                    )
                  : GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1.1,
                      children: [
                        _buildFinanceCard("Gastos", provider.getTotalExpenses(), Icons.trending_down, Colors.red),
                        _buildFinanceCard("Ingresos", provider.getTotalIncomes(), Icons.trending_up, Colors.green),
                        _buildFinanceCard("Ahorros", provider.getTotalSavings(), Icons.savings, Colors.blue),
                        _buildFinanceCard("Balance", provider.getBalance(), Icons.balance, Colors.purple),
                      ],
                    ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFinanceCard(String title, double amount, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(12),
        height: 130,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Icon(icon, size: 32, color: color),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                "\$${amount.toStringAsFixed(2)}",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildFinanceCardSkeleton() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          height: 130,
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Container(width: 32, height: 32, color: Colors.white),
              Container(width: 60, height: 14, color: Colors.white),
              Container(width: 80, height: 16, color: Colors.white),
            ],
          ),
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
