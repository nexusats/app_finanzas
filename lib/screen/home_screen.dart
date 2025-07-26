import 'package:app_finanzas/app/controller/goals_provider.dart';
import 'package:app_finanzas/app/model/goal.dart';
import 'package:app_finanzas/app/model/transaction.dart';
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
    return Consumer2<TransactionsProvider, GoalsProvider>(
      builder: (context, txProvider, gsProvider, _) {
        final isLoading = txProvider.isLoading || gsProvider.isLoading;
        final goals = gsProvider.goals;

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

              // Scroll vertical con todo dentro
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tarjetas de balance una debajo de otra
                      // 🔁 Scroll horizontal para las tarjetas de balance
                      if (txProvider.isLoading)
                        SizedBox(
                          height: 150,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: 3,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                            itemBuilder: (_, __) => buildFinanceCardSkeleton(),
                          ),
                        )
                      else
                        SizedBox(
                          height: 80,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: 5,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final items = [
                                {
                                  "title": "Libertad Financiera",
                                  "amount": txProvider.getTotalDebt(),
                                  "icon": Icons.lock_open_rounded,
                                  "color": Colors.deepOrangeAccent,
                                },
                                {
                                  "title": "Gastos Conscientes",
                                  "amount": txProvider.getTotalExpenses(),
                                  "icon": Icons.account_balance_wallet_outlined,
                                  "color": Colors.orangeAccent,
                                },
                                {
                                  "title": "Prosperidad",
                                  "amount": txProvider.getTotalIncomes(),
                                  "icon": Icons.trending_up_rounded,
                                  "color": Colors.teal,
                                },
                                {
                                  "title": "Capital Semilla",
                                  "amount": txProvider.getTotalSavings(),
                                  "icon": Icons.savings_rounded,
                                  "color": Colors.indigoAccent,
                                },
                                {
                                  "title": "Balance",
                                  "amount": txProvider.getBalance(),
                                  "icon": Icons.auto_graph_rounded,
                                  "color": Colors.deepPurpleAccent,
                                },
                              ];

                              final item = items[index];
                              return _buildFinanceCard(
                                item["title"] as String,
                                item["amount"] as double,
                                item["icon"] as IconData,
                                item["color"] as Color,
                              );
                            },
                          ),
                        ),
                      // Sección de metas
                      if (isLoading) ...[
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 150,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: 3,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                            itemBuilder: (_, __) => buildFinanceCardSkeleton(),
                          ),
                        )]
                      else if (goals.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Text(
                          "Estado de los objetivos",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 120,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: goals.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final goal = goals[index];
                              return _buildGoalsCard(goal);
                            },
                          ),
                        ),
                      ],

                      // Sección de deudas
                      if (isLoading) ...[
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 150,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: 3,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                            itemBuilder: (_, __) => buildFinanceCardSkeleton(),
                          ),
                        )]
                      else if (txProvider
                              .getTransactionsByType(TransactionType.E)
                              .isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Text(
                          "Estado de las deudas",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 120,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: txProvider
                                .getTransactionsByType(TransactionType.E)
                                .length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final debt = txProvider.getTransactionsByType(
                                  TransactionType.E)[index];
                              return _buildDebtCard(debt);
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGoalsCard(Goal goal) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: Colors.blueGrey.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        // ignore: deprecated_member_use
        border: Border.all(color: Colors.blueGrey.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.flag, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  goal.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            formatCurrency(goal.amount),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          Text(
            formatCurrency(goal.totalTransactions),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              // ignore: deprecated_member_use
              color: Colors.green.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            // ignore: unnecessary_null_comparison
            goal.date != null
                ? "Fecha: ${goal.date.toLocal().toIso8601String().split('T')[0]}"
                : "Fecha no disponible",
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildDebtCard(Transaction transaction) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: Colors.deepOrangeAccent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        // ignore: deprecated_member_use
        border: Border.all(color: Colors.deepOrangeAccent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Colors.deepOrangeAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  transaction.description ?? "Sin descripción",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            formatCurrency(transaction.amount),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.deepOrangeAccent,
            ),
          ),
          Text(
            formatCurrency(transaction.totalDebt ?? 0),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              // ignore: deprecated_member_use
              color: Colors.green.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            // ignore: unnecessary_null_comparison
            transaction.date != null
                ? "Fecha: ${transaction.date.toLocal().toIso8601String().split('T')[0]}"
                : "Fecha no disponible",
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceCard(
      String title, double amount, IconData icon, Color color) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        // ignore: deprecated_member_use
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
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
