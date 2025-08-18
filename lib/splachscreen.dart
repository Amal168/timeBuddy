
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timebuddy/main.dart';
import 'package:timebuddy/model.dart';
import 'package:timebuddy/screens/admin.dart';
import 'package:timebuddy/screens/intern.dart';
import 'package:timebuddy/screens/login.dart';
import 'firebase_options.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late String imageUrl;
  final List<String> imageUrls = const [
    'https://images.unsplash.com/photo-1553877522-43269d4ea984?q=80&w=1200',
    'https://images.unsplash.com/photo-1531482615713-2afd69097998?q=80&w=1200',
    'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?q=80&w=1200',
    'https://images.unsplash.com/photo-1519389950473-47ba0277781c?q=80&w=1200',
  ];

  @override
  void initState() {
    super.initState();
    imageUrl = imageUrls[Random().nextInt(imageUrls.length)];
    Future.delayed(const Duration(seconds: 2), () async {
      if (!mounted) return;
      // If already signed in, route by role
      final u = FirebaseAuth.instance.currentUser;
      if (u != null) {
        final role = await fireRepo.getUserRole(u.uid);
        if (!mounted) return;
        if (role == 'admin') {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const AdminDashboard()));
          return;
        }
        if (role == 'intern') {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const InternDashboard()));
          return;
        }
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (c, w, p) =>
                  const Center(child: CircularProgressIndicator()),
              errorBuilder: (c, e, s) => const Center(
                child: Icon(Icons.image_not_supported, size: 48),
              ),
            ),
          ),
          Container(color: Colors.white.withOpacity(0.1)),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Time Buddy',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      shadows: const [
                        Shadow(color: Colors.black54, blurRadius: 8)
                      ],
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

