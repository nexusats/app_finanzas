import 'package:flutter/material.dart';
import 'package:app_finanzas/widgets/login_field.dart';
import 'package:app_finanzas/widgets/gradient_button.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Register")
        // backgroundColor: Pallete.backgroundColor
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Create a new account", style: TextStyle(fontSize: 24)),
              const SizedBox(height: 20),
              LoginField(hintText: "Username"),
              const SizedBox(height: 20),
              LoginField(hintText: "Email"),
              const SizedBox(height: 15),
              LoginField(hintText: "Password", isPassword: true),
              const SizedBox(height: 15),
              LoginField(hintText: "Confirm Password", isPassword: true),
              const SizedBox(height: 20),
              GradientButton(onPressed: () {}, label: "Register"),
            ],
          ),
        ),
      ),
    );
  }
}