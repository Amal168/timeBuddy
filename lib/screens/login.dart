import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:timebuddy/main.dart';
import 'package:timebuddy/model.dart';
import 'package:timebuddy/screens/admin.dart';
import 'package:timebuddy/screens/intern.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  UserRole _selectedRole = UserRole.admin;
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  // Hardcoded credentials
  final adminEmail = "admin@example.com";
  final adminPassword = "admin123";

  final internEmail = "intern@example.com";
  final internPassword = "intern123";

  void _login() {
    String email = _email.text.trim();
    String pass = _password.text.trim();

    if (_selectedRole == UserRole.admin &&
        email == adminEmail &&
        pass == adminPassword) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboard()),
      );
    } else if (_selectedRole == UserRole.intern &&
        email == internEmail &&
        pass == internPassword) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const InternDashboard()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid email or password")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Time Buddy",
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    CupertinoSegmentedControl<UserRole>(
                      groupValue: _selectedRole,
                      children: const {
                        UserRole.admin: Padding(
                          padding: EdgeInsets.all(8),
                          child: Text("Admin"),
                        ),
                        UserRole.intern: Padding(
                          padding: EdgeInsets.all(8),
                          child: Text("Intern"),
                        ),
                      },
                      onValueChanged: (role) {
                        setState(() => _selectedRole = role);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _email,
                      decoration: const InputDecoration(
                        labelText: "Email",
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _password,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: "Password",
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _login,
                        child: const Text("Login"),
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