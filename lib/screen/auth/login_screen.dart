import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_finanzas/widgets/login_field.dart';
import 'package:app_finanzas/widgets/gradient_button.dart';
import 'package:app_finanzas/app/controller/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>(); // Llave para el formulario
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      String email = _emailController.text.trim();
      String password = _passwordController.text.trim();

      // Enviamos los datos como un Map en lugar de un objeto User
      Map<String, dynamic> userData = {
        "email": email,
        "password": password,
      };

      context.read<AuthProvider>().login(context, userData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Image.asset('assets/images/signin_balls.png'),
                const Text(
                  'Sign in.',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 50,
                  ),
                ),
                const SizedBox(height: 80),
                LoginField(
                  hintText: 'Email',
                  controller: _emailController,
                ),
                const SizedBox(height: 15),
                LoginField(
                  hintText: 'Password',
                  isPassword: true,
                  controller: _passwordController,
                ),
                const SizedBox(height: 20),
                GradientButton(onPressed: _submitForm),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
