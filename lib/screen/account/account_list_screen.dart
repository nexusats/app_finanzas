import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

import 'package:app_finanzas/config/global.dart';
import 'package:app_finanzas/app/model/account.dart';
import 'package:app_finanzas/app/controller/account_provider.dart';
import 'package:app_finanzas/screen/account/account_edit_screen.dart'; // AccountEditModal

class AccountListScreen extends StatefulWidget {
  const AccountListScreen({super.key});

  @override
  State<AccountListScreen> createState() => _AccountListScreenState();
}

class _AccountListScreenState extends State<AccountListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<AccountProvider>().fetchIfNeeded();
    });
  }

  Future<void> _openEditModal(BuildContext context, Account? account) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.65,
        child: AccountEditModal(account: account),
      ),
    );

    if (!mounted) return;
    if (changed == true) {
      await context.read<AccountProvider>().refresh();
    }
  }

  Future<void> _confirmArchive(
      AccountProvider provider, Account account) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Archivar cuenta'),
        content: Text('¿Seguro que deseas archivar "${account.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Archivar'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    await provider.removeAccount(account);
    await provider.refresh();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cuenta archivada')),
    );
  }

  Future<void> _confirmDelete(AccountProvider provider, Account account) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar cuenta'),
        content: Text('¿Seguro que deseas eliminar "${account.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    await provider.removeAccount(account);
    await provider.refresh();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cuenta archivada')),
    );
  }

  Widget _skeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100, top: 8),
      itemCount: 8,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: const ListTile(
            leading: CircleAvatar(backgroundColor: Colors.white, radius: 18),
            title: SizedBox(height: 14, width: double.infinity),
            subtitle: SizedBox(height: 12, width: 140),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AccountProvider>(
      builder: (context, provider, _) {
        final accounts = provider.accounts;

        return Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(0),
            child: AppBar(
              backgroundColor: ConfigGlobal.backgroundColor,
              elevation: 0,
              automaticallyImplyLeading: false,
              titleSpacing: 0,
            ),
          ),
          body: Container(
            padding: const EdgeInsets.only(top: 40),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
            ),
            child: provider.isLoading
                ? _skeletonList()
                : accounts.isEmpty
                    ? const Center(child: Text('No hay cuentas registradas'))
                    : RefreshIndicator(
                        onRefresh: () => provider.refresh(),
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 100),
                          itemCount: accounts.length,
                          itemBuilder: (context, index) {
                            final account = accounts[index];
                            final archived = account.isArchived == true;

                            final balanceText =
                                account.currentBalanceFormatted ??
                                    (account.currentBalance?.toString());

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: ListTile(
                                leading: Icon(
                                  Icons.account_balance_wallet_outlined,
                                  size: 32,
                                  color: archived
                                      ? Colors.grey
                                      : ConfigGlobal.backgroundColor,
                                ),
                                title: Text(account.name),
                                subtitle: (balanceText != null &&
                                        balanceText.toString().isNotEmpty)
                                    ? Text('Saldo actual: $balanceText')
                                    : null,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.edit,
                                        color: archived
                                            ? Colors.grey
                                            : Colors.blue,
                                      ),
                                      onPressed: archived
                                          ? null
                                          : () => _openEditModal(
                                                context,
                                                account,
                                              ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.archive,
                                        color: archived
                                            ? Colors.grey
                                            : Colors.orange,
                                      ),
                                      onPressed: archived
                                          ? null
                                          : () => _confirmArchive(
                                                provider,
                                                account,
                                              ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete,
                                        color:
                                            archived ? Colors.grey : Colors.red,
                                      ),
                                      onPressed: archived
                                          ? null
                                          : () => _confirmDelete(
                                                provider,
                                                account,
                                              ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
          floatingActionButton: SpeedDial(
            icon: Icons.menu,
            activeIcon: Icons.close,
            backgroundColor: ConfigGlobal.backgroundColor,
            foregroundColor: Colors.white,
            overlayOpacity: 0.1,
            children: [
              SpeedDialChild(
                child: const Icon(Icons.add),
                label: 'Nueva Cuenta',
                onTap: () => _openEditModal(context, null),
              ),
              SpeedDialChild(
                child: const Icon(Icons.refresh),
                label: 'Refrescar',
                onTap: () => provider.refresh(),
              ),
            ],
          ),
        );
      },
    );
  }
}
