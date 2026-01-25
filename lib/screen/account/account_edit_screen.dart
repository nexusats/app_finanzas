import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_finanzas/app/model/account.dart';
import 'package:app_finanzas/app/controller/account_provider.dart';

class AccountEditModal extends StatefulWidget {
  final Account? account;

  const AccountEditModal({super.key, this.account});

  @override
  State<AccountEditModal> createState() => _AccountEditModalState();
}

class _AccountEditModalState extends State<AccountEditModal> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _initialBalanceController;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.account?.name ?? '');

    final initial = widget.account?.initialBalance;
    _initialBalanceController = TextEditingController(
      text: initial != null ? initial.toString() : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _initialBalanceController.dispose();
    super.dispose();
  }

  double? _parseBalance(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return null;
    // Soporta "12,34" y "12.34"
    final normalized = v.replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  Future<void> _saveAccount() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<AccountProvider>(context, listen: false);

    final name = _nameController.text.trim();
    final initialBalance = _parseBalance(_initialBalanceController.text);

    // API store: name, initial_balance (required)
    // API update: name, initial_balance, is_archived (optional)
    final body = <String, dynamic>{
      'name': name,
      'initial_balance': initialBalance,
    };

    bool success;
    if (widget.account == null) {
      success = await provider.createAccount(body);
    } else {
      success = await provider.updateAccount(widget.account!.id!, body);
    }

    if (!mounted) return;

    Navigator.pop(context, success);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Cuenta guardada correctamente' : 'Error al guardar cuenta',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.account != null;

    return Material(
      type: MaterialType.transparency,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 15),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        isEditing ? "Editar Cuenta" : "Nueva Cuenta",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3A3A8C),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final v = value?.trim() ?? '';
                        if (v.isEmpty) return 'Ingrese un nombre';
                        if (v.length > 80) return 'Máximo 80 caracteres';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _initialBalanceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: false,
                      ),
                      decoration: InputDecoration(
                        labelText: isEditing
                            ? 'Saldo inicial'
                            : 'Saldo inicial (requerido)',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.attach_money),
                      ),
                      validator: (value) {
                        final v = value?.trim() ?? '';
                        if (!isEditing && v.isEmpty) {
                          return 'Ingrese el saldo inicial';
                        }
                        if (v.isEmpty) return null;

                        final parsed = _parseBalance(v);
                        if (parsed == null) return 'Saldo inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 26),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3A3A8C),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _saveAccount,
                        child: const Text(
                          "Guardar",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
