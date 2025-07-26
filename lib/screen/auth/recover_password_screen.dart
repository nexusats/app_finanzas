import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_finanzas/config/pallete.dart';
import 'package:app_finanzas/widgets/login_field.dart';
import 'package:app_finanzas/widgets/gradient_button.dart';
import 'package:app_finanzas/app/controller/auth_provider.dart';

class RecoverPasswordScreen extends StatefulWidget {
  const RecoverPasswordScreen({super.key});

  @override
  State<RecoverPasswordScreen> createState() => _RecoverPasswordScreenState();
}

class _RecoverPasswordScreenState extends State<RecoverPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      final email = _emailController.text.trim();

      final userData = {
        "email": email,
      };

      context.read<AuthProvider>().resetPassword(context, userData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Recover Password"),
        backgroundColor: Pallete.backgroundColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text(
                "Enter your email to reset password",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              LoginField(
                hintText: "Email",
                controller: _emailController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Email is required";
                  }
                  final emailRegex = RegExp(r"^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$");
                  if (!emailRegex.hasMatch(value)) {
                    return "Invalid email format";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              GradientButton(
                onPressed: _submitForm,
                label: "Send Reset Link",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
