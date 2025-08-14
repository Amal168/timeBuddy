import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:timebuddy/main.dart';

enum UserRole { admin, intern }


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  UserRole _selectedRole = UserRole.admin; // default role
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Widget _roleSegment() {
    return CupertinoSegmentedControl<UserRole>(
      groupValue: _selectedRole,
      padding: const EdgeInsets.all(2),
      children: const {
        UserRole.admin: Padding(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Text('Admin'),
        ),
        UserRole.intern: Padding(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Text('Intern'),
        ),
      },
      onValueChanged: (val) => setState(() => _selectedRole = val),
    );
  }

  void _login() {
    if (_formKey.currentState?.validate() != true) return;

    // Simple navigation based on role
    if (_selectedRole == UserRole.admin) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboard()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const InternDashboard()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final card = Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Time Buddy',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              _roleSegment(),
              const SizedBox(height: 16),
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Email required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                        _obscure ? Icons.visibility : Icons.visibility_off),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Password required' : null,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _login,
                  child: const Text('Login'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(padding: const EdgeInsets.all(16.0), child: card),
        ),
      ),
    );
  }
}