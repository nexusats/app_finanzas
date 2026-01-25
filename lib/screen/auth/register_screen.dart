import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_finanzas/widgets/login_field.dart';
import 'package:app_finanzas/widgets/gradient_button.dart';
import 'package:app_finanzas/app/controller/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final passwordConfirmation = _confirmPasswordController.text.trim();
      final username = _usernameController.text.trim();
      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();

      final userData = {
        "email": email,
        "password": password,
        "password_confirmation": passwordConfirmation,
        "username": username,
        "firstname": firstName,
        "lastname": lastName,
      };

      context.read<AuthProvider>().register(context, userData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 30),
              const Text(
                "Create a new account",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              /* LoginField(
                hintText: "Username",
                controller: _usernameController,
                validator: (value) => value == null || value.isEmpty
                    ? "Username is required"
                    : null,
              ),
              const SizedBox(height: 16), */
              LoginField(
                hintText: "First Name",
                controller: _firstNameController,
                validator: (value) => value == null || value.isEmpty
                    ? "First Name is required"
                    : null,
              ),
              const SizedBox(height: 16),
              LoginField(
                hintText: "Last Name",
                controller: _lastNameController,
                validator: (value) => value == null || value.isEmpty
                    ? "Last Name is required"
                    : null,
              ),
              const SizedBox(height: 16),
              LoginField(
                hintText: "Email",
                controller: _emailController,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return "Email is required";
                  final emailRegex = RegExp(r"^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$");
                  if (!emailRegex.hasMatch(value))
                    return "Invalid email format";
                  return null;
                },
              ),
              const SizedBox(height: 16),
              LoginField(
                hintText: "Password",
                isPassword: true,
                controller: _passwordController,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return "Password is required";
                  if (value.length < 6)
                    return "Password must be at least 6 characters";
                  return null;
                },
              ),
              const SizedBox(height: 16),
              LoginField(
                hintText: "Confirm Password",
                isPassword: true,
                controller: _confirmPasswordController,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return "Please confirm your password";
                  if (value != _passwordController.text)
                    return "Passwords do not match";
                  return null;
                },
              ),
              const SizedBox(height: 30),
              GradientButton(
                onPressed: _submitForm,
                label: "Register",
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
