import 'package:ads_frontend/UserSession.dart';
import 'package:ads_frontend/services/api_service.dart';
import 'package:flutter/material.dart';
import '../../models/app_user.dart';

import '../../theme/apptheme.dart';


class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;

  void _login() async{
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // TEMP AUTH LOGIC (replace with API)
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("All fields are required"),
          backgroundColor: Colors.red,
        ),
      );
      return; // 🔴 VERY IMPORTANT
    }

    final AppUser? result = await ApiService.login(email, password);
    if (result != null) {
      await UserSession.saveUser(result.userId, result.name, result.role);
      if(result.role=='a'){
        Navigator.pushReplacementNamed(context, '/advertiserDashboard');
      }else{
        Navigator.pushReplacementNamed(context, '/driverDashboard');
      }

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Invalid Credentials"),
          backgroundColor: Colors.red,
        ),
      );
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),

              /// LOGO
              CircleAvatar(
                radius: 45,
                backgroundColor: AppTheme.primaryTeal,
                child: Icon(
                  Icons.arrow_forward,
                  color: AppTheme.white,
                  size: 40,
                ),
              ),

              const SizedBox(height: 12),

              /// APP NAME
              Text(
                "MOVING ADS",
                style: Theme.of(context)
                    .textTheme
                    .headlineLarge
                    ?.copyWith(color: AppTheme.primaryTeal),
              ),

              const SizedBox(height: 4),

              /// TAGLINE
              const Text(
                "Ad lagao, paisa kamao",
                style: TextStyle(fontSize: 13),
              ),

              const SizedBox(height: 40),

              /// WELCOME
              Text(
                "Welcome Back",
                style: Theme.of(context).textTheme.headlineLarge,
              ),

              const SizedBox(height: 30),

              /// EMAIL / USERNAME
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  hintText: "Email or Username",
                ),
              ),

              const SizedBox(height: 16),

              /// PASSWORD
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: "Password",
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 24),

              /// LOGIN BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryTeal,
                  ),
                  child: const Text("Login"),
                ),
              ),

              const SizedBox(height: 30),

              /// SIGNUP TEXT
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don’t have an account? "),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/signup');
                    },
                    child: Text(
                      "SignUp",
                      style: TextStyle(
                        color: AppTheme.actionBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
