import 'package:ads_frontend/models/app_user.dart';
import 'package:ads_frontend/services/api_service.dart';
import 'package:flutter/material.dart';
import '../../theme/apptheme.dart';

class SignupView extends StatefulWidget {
  const SignupView({super.key});

  @override
  State<SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<SignupView> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedRole = "Driver";

  void _signup() async{
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showMessage("All fields are required", isError: true);
      return;
    }

    if (password != confirmPassword) {
      _showMessage("Passwords do not match", isError: true);
      return;
    }
    String role="";
    if(_selectedRole=="Driver") {
      role = 'd';
    }
    else if(_selectedRole=="Advertiser") {
      role = 'a';
    }
    final user=AppUser(name: name, email: email, password: password, role: role);
    final result=await ApiService.signup(user);
    if(result=='success'){
      _showMessage("Account created successfully");

      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pop(context); // Back to Login
      });
    }else{
      _showMessage(result,isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : AppTheme.primaryTeal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),

              /// LOGO
              Center(
                child: Column(
                  children: [
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
                    Text(
                      "MOVING ADS",
                      style: Theme.of(context)
                          .textTheme
                          .headlineLarge
                          ?.copyWith(color: AppTheme.primaryTeal),
                    ),
                    const SizedBox(height: 4),
                    const Text("Ad lagao, paisa kamao"),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              /// TITLE
              Text(
                "Create your account",
                style: Theme.of(context).textTheme.headlineLarge,
              ),

              const SizedBox(height: 24),

              /// FULL NAME
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: "Full Name",
                ),
              ),

              const SizedBox(height: 16),

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

              const SizedBox(height: 16),

              /// CONFIRM PASSWORD
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  hintText: "Confirm Password",
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              /// ROLE SELECTOR
              InkWell(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (_) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: ["Driver", "Advertiser"]
                          .map(
                            (role) => ListTile(
                          title: Text(role),
                          onTap: () {
                            setState(() {
                              _selectedRole = role;
                            });
                            Navigator.pop(context);
                          },
                        ),
                      )
                          .toList(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black26),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Role"),
                      Row(
                        children: [
                          Text(_selectedRole),
                          const SizedBox(width: 6),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              /// SIGNUP BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _signup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryTeal,
                  ),
                  child: const Text("Sign Up"),
                ),
              ),

              const SizedBox(height: 30),

              /// LOGIN LINK
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account? "),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text(
                      "Login",
                      style: TextStyle(
                        color: AppTheme.actionBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
