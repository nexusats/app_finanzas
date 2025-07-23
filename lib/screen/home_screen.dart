import 'package:shimmer/shimmer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_finanzas/config/global.dart';
import 'package:app_finanzas/config/format_utils.dart';
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
            scaffoldBackgroundColor: ConfigGlobal.backgroundColor,
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
    return PreferredSize(
      preferredSize: const Size.fromHeight(40),
      child: AppBar(
        backgroundColor: ConfigGlobal.backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: ConfigGlobal.backgroundColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: "Inicio",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.swap_vert_circle_rounded),
            label: "Movimientos",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category_rounded),
            label: "Categorías",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.tune_rounded),
            label: "Ajustes",
          ),
        ]);
  }

  Widget _buildHomeScreen() {
    return Consumer<TransactionsProvider>(
      builder: (context, provider, _) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
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
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.9,
                  children: provider.isLoading
                      ? List.generate(5, (_) => buildFinanceCardSkeleton())
                      : [
                          _buildFinanceCard(
                            "Libertad Financiera",
                            provider.getTotalDebt(),
                            Icons.lock_open_rounded,
                            Colors.deepOrangeAccent,
                          ),
                          _buildFinanceCard(
                            "Gastos Conscientes",
                            provider.getTotalExpenses(),
                            Icons.account_balance_wallet_outlined,
                            Colors.orangeAccent,
                          ),
                          _buildFinanceCard(
                            "Prosperidad",
                            provider.getTotalIncomes(),
                            Icons.trending_up_rounded,
                            Colors.teal,
                          ),
                          _buildFinanceCard(
                            "Capital Semilla",
                            provider.getTotalSavings(),
                            Icons.savings_rounded,
                            Colors.indigoAccent,
                          ),
                          _buildFinanceCard(
                            "Balance",
                            provider.getBalance(),
                            Icons.auto_graph_rounded,
                            Colors.deepPurpleAccent,
                          ),
                        ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFinanceCard(
      String title, double amount, IconData icon, Color color) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      // ignore: deprecated_member_use
      shadowColor: color.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                // ignore: deprecated_member_use
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              formatCurrency(amount),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
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
    return Container(
      padding: const EdgeInsets.only(top: 40, left: 20, right: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
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
