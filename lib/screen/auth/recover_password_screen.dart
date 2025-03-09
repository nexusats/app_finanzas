import 'package:flutter/material.dart';
import 'package:app_finanzas/config/pallete.dart';
import 'package:app_finanzas/widgets/login_field.dart';
import 'package:app_finanzas/widgets/gradient_button.dart';

class RecoverPasswordScreen extends StatelessWidget {
  const RecoverPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Recover Password"),
        backgroundColor: Pallete.backgroundColor,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Enter your email to reset password",
                  style: TextStyle(fontSize: 20)),
              const SizedBox(height: 20),
              LoginField(hintText: "Email"),
              const SizedBox(height: 20),
              GradientButton(onPressed: () {}, label: "Send Reset Link"),
            ],
          ),
        ),
      ),
    );
  }
}
