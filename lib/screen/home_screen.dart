import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:app_finanzas/config/global.dart';
import 'package:app_finanzas/screen/auth/login_screen.dart';
import 'package:app_finanzas/app/controller/auth_provider.dart';
import 'package:app_finanzas/app/controller/connectivity_provider.dart';
import 'package:app_finanzas/screen/account/account_list_screen.dart';
import 'package:app_finanzas/app/controller/transactions_provider.dart';
import 'package:app_finanzas/screen/category/category_list_screen.dart';
import 'package:app_finanzas/screen/transaction/transaction_screen.dart';
import 'package:app_finanzas/app/services/local/local_database.dart';
import 'package:fl_chart/fl_chart.dart';

// Si ya tienes GetSelectsService úsalo. Aquí lo dejo como placeholder:
import 'package:app_finanzas/app/services/get_selects_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late Future<_HomeMeta> _metaFuture;

  // void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);

    // Lazy-load de movimientos solo cuando entra a Movimientos
    if (index == 1) {
      context.read<TransactionsProvider>().fetchTransactionsIfNeeded();
    }
  }

  @override
  void initState() {
    super.initState();
    _metaFuture = _loadMeta();
    context.read<TransactionsProvider>().fetchTransactionsIfNeeded();

    // Mantén esto si tu app lo necesita para otras pantallas
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   context.read<TransactionsProvider>().fetchTransactions();
    // });
  }

  Future<_HomeMeta> _loadMeta() async {
    try {
      final raw = await GetSelectsService.fetchData(['accounts', 'categories']);
      final Map<String, dynamic> json = raw is Map<String, dynamic>
          ? raw
          : jsonDecode(raw.toString()) as Map<String, dynamic>;

      final accountsJson =
          (json['accounts'] ?? json['data']?['accounts'] ?? []) as List;
      final categoriesJson =
          (json['categories'] ?? json['data']?['categories'] ?? []) as List;

      final accounts = accountsJson
          .whereType<Map<String, dynamic>>()
          .map(AccountMeta.fromJson)
          .toList();

      final categories = categoriesJson
          .whereType<Map<String, dynamic>>()
          .map(CategoryMeta.fromJson)
          .toList();

      return _HomeMeta(accounts: accounts, categories: categories);
    } catch (_) {
      final localAccounts = await LocalDatabase.getAccounts();
      final localCategories = await LocalDatabase.getCategories();

      return _HomeMeta(
        accounts: localAccounts
            .map(
              (account) => AccountMeta(
                id: account.id ?? 0,
                name: account.name,
                currentBalance: account.currentBalance ?? 0,
                currentBalanceFormatted:
                    account.currentBalanceFormatted ?? '0.00',
              ),
            )
            .toList(),
        categories: localCategories
            .map(
              (category) => CategoryMeta(
                id: category.id ?? 0,
                name: category.name,
                type: category.type ?? '',
              ),
            )
            .toList(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Selector<AuthProvider, bool>(
      selector: (_, auth) => auth.isAuthenticated,
      builder: (context, isAuthenticated, _) {
        if (!isAuthenticated) return const LoginScreen();

        final screens = <Widget>[
          _buildHomeScreen(),
          _selectedIndex == 1
              ? const TransactionScreen(showAppBar: false)
              : const SizedBox.shrink(),
          _selectedIndex == 2
              ? const CategoryListScreen()
              : const SizedBox.shrink(),
          _selectedIndex == 3
              ? const AccountListScreen()
              : const SizedBox.shrink(),
          _buildSettingsScreen(context.read<AuthProvider>()),
        ];

        return Theme(
          data: ThemeData.light().copyWith(
            scaffoldBackgroundColor: ConfigGlobal.backgroundColor,
          ),
          child: Scaffold(
            appBar: _buildAppBar(),
            body: SafeArea(
              child: IndexedStack(
                index: _selectedIndex,
                children: screens,
              ),
            ),
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
      selectedItemColor: Colors.black87,
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
          icon: Icon(Icons.account_balance_wallet_rounded),
          label: "Cuentas",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.tune_rounded),
          label: "Ajustes",
        ),
      ],
    );
  }

  Widget _buildHomeScreen() {
    return FutureBuilder<_HomeMeta>(
      future: _metaFuture,
      builder: (context, snap) {
        final isLoading = snap.connectionState == ConnectionState.waiting;
        final connectivity = context.watch<ConnectivityProvider>();

        // Contenedor base (misma UI que ya tienes)
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
              _buildOfflineBanner(connectivity),
              const SizedBox(height: 8),
              // HEADER
              if (isLoading)
                _titleSkeleton(width: 220, height: 18)
              else
                const Text(
                  "Resumen financiero",
                  style: TextStyle(
                    fontSize: ConfigGlobal.sizeTitle,
                    fontWeight: FontWeight.bold,
                  ),
                ),

              const SizedBox(height: 16),

              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    // Refresca meta (accounts/categories)
                    setState(() => _metaFuture = _loadMeta());

                    // si también quieres refrescar movimientos (como ya lo tienes)
                    context.read<TransactionsProvider>().fetchTransactions();

                    await _metaFuture; // asegura que actualice el cache visual
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ---------------- CUENTAS ----------------
                        if (isLoading) ...[
                          _titleSkeleton(width: 90, height: 14),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 90,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: 3,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (_, __) => _accountCardSkeleton(),
                            ),
                          ),
                        ] else if (snap.hasError) ...[
                          _errorBox(
                            'Error al cargar cuentas',
                            onRetry: () =>
                                setState(() => _metaFuture = _loadMeta()),
                          ),
                        ] else ...[
                          const Text(
                            "Cuentas",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 90,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: snap.data!.accounts.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                final a = snap.data!.accounts[index];
                                return _buildAccountCard(a);
                              },
                            ),
                          ),
                        ],

                        const SizedBox(height: 18),

                        // -------------- CATEGORÍAS (CHIPS) --------------
                        if (isLoading) ...[
                          _titleSkeleton(width: 110, height: 14),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _chipSkeleton(),
                              _chipSkeleton(),
                            ],
                          ),
                        ] else if (snap.hasError) ...[
                          _errorBox(
                            'Error al cargar categorías',
                            onRetry: () =>
                                setState(() => _metaFuture = _loadMeta()),
                          ),
                        ] else ...[
                          const Text(
                            "Categorías",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildChip(
                                icon: Icons.trending_up_rounded,
                                label: "Ingresos",
                                value: snap.data!.incomeCount.toString(),
                              ),
                              _buildChip(
                                icon: Icons.trending_down_rounded,
                                label: "Gastos",
                                value: snap.data!.expenseCount.toString(),
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 18),

                        _buildAnalyticsSection(),

                        const SizedBox(height: 18),

                        // Opcional: mini bloque skeleton extra para que no se vea “vacío”
                        if (isLoading) ...[
                          _blockSkeleton(height: 70),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _titleSkeleton({required double width, required double height}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _chipSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 18, height: 18, color: Colors.white),
            const SizedBox(width: 8),
            Container(width: 90, height: 12, color: Colors.white),
            const SizedBox(width: 6),
            Container(width: 20, height: 12, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _blockSkeleton({required double height}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildAccountCard(AccountMeta a) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_outlined),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  a.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            a.currentBalanceFormatted,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(
            "$label: ",
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Text(value),
        ],
      ),
    );
  }

  Widget _accountCardSkeleton() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: SizedBox(
          width: 200,
          height: 90,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                    height: 14, width: double.infinity, color: Colors.white),
                const SizedBox(height: 10),
                Container(height: 16, width: 120, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _errorBox(String text, {required VoidCallback onRetry}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
          TextButton(onPressed: onRetry, child: const Text("Reintentar")),
        ],
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

  Widget _buildOfflineBanner(ConnectivityProvider connectivity) {
    if (connectivity.isOnline) {
      return Row(
        children: [
          const Icon(Icons.cloud_done_outlined, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              connectivity.lastSyncAt == null
                  ? "Sincronización completa"
                  : "Última sincronización: ${_formatDate(connectivity.lastSyncAt!)}",
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
          TextButton(
            onPressed: connectivity.manualSync,
            child: const Text("Sincronizar"),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, color: Colors.orange),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              "Estás en modo offline. Guardaremos cambios para sincronizar luego.",
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsSection() {
    return Consumer<TransactionsProvider>(
      builder: (context, provider, _) {
        final income = provider.getTotalIncomes();
        final expense = provider.getTotalExpenses();
        final balance = provider.getBalance();

        final total = income + expense;
        final incomeShare = total == 0 ? 0.0 : income / total;
        final expenseShare = total == 0 ? 0.0 : expense / total;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Análisis rápido",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 30,
                        sections: [
                          PieChartSectionData(
                            color: Colors.green[400],
                            value: incomeShare * 100,
                            title: "Ingresos",
                            radius: 30,
                            titleStyle: const TextStyle(fontSize: 10),
                          ),
                          PieChartSectionData(
                            color: Colors.red[300],
                            value: expenseShare * 100,
                            title: "Gastos",
                            radius: 30,
                            titleStyle: const TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _metricRow(
                          label: "Balance",
                          value: balance.toStringAsFixed(2),
                          color: balance >= 0 ? Colors.green : Colors.red,
                        ),
                        const SizedBox(height: 6),
                        _metricRow(
                          label: "Ingresos",
                          value: income.toStringAsFixed(2),
                          color: Colors.green,
                        ),
                        const SizedBox(height: 6),
                        _metricRow(
                          label: "Gastos",
                          value: expense.toStringAsFixed(2),
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _metricRow({
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Text(value),
      ],
    );
  }

  String _formatDate(DateTime dateTime) {
    return "${dateTime.day.toString().padLeft(2, '0')}/"
        "${dateTime.month.toString().padLeft(2, '0')}/"
        "${dateTime.year} "
        "${dateTime.hour.toString().padLeft(2, '0')}:"
        "${dateTime.minute.toString().padLeft(2, '0')}";
  }
}

/* ---------------------------- Models for meta ---------------------------- */

class _HomeMeta {
  final List<AccountMeta> accounts;
  final List<CategoryMeta> categories;

  _HomeMeta({required this.accounts, required this.categories});

  int get incomeCount => categories.where((c) => c.type == 'income').length;
  int get expenseCount => categories.where((c) => c.type == 'expense').length;
}

class AccountMeta {
  final int id;
  final String name;
  final double currentBalance;
  final String currentBalanceFormatted;

  AccountMeta({
    required this.id,
    required this.name,
    required this.currentBalance,
    required this.currentBalanceFormatted,
  });

  factory AccountMeta.fromJson(Map<String, dynamic> json) {
    return AccountMeta(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: (json['name'] ?? '').toString(),
      currentBalance:
          double.tryParse(json['current_balance']?.toString() ?? '') ?? 0.0,
      currentBalanceFormatted:
          (json['current_balance_formatted'] ?? '0.00').toString(),
    );
  }
}

class CategoryMeta {
  final int id;
  final String name;
  final String type; // income | expense

  CategoryMeta({required this.id, required this.name, required this.type});

  factory CategoryMeta.fromJson(Map<String, dynamic> json) {
    return CategoryMeta(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: (json['name'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
    );
  }
}
