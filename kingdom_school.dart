import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'kingdom_school_page.dart';
import 'login_page.dart';

class KingdomSchoolHomePage extends StatelessWidget {
  const KingdomSchoolHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(16),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 100, vertical: 20),
              minimumSize: const Size(0, 60),    // white bg
              foregroundColor: Colors.black,     // text/icon color
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(
                  color: Colors.black54,
                  width: 1,
                ),
              ),
              textStyle: const TextStyle(
                fontSize: 22,
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const KingdomSchoolPage(),
                ),
              );
            },
            child: const Text(
              "KingdomSchool",
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
