import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'login_page.dart';
import 'admin_page.dart';
import 'location_access_page.dart';

class SuperAdminHomePage extends StatelessWidget {
  const SuperAdminHomePage({super.key});

  // BOTÃO REUSÁVEL PRETO
  Widget buildOutlinedButton(
    BuildContext context,
    String text,
    VoidCallback onPressed,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 20),
          minimumSize: const Size(double.infinity, 60),
          foregroundColor: Colors.black,      // text/icon color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(
              color: Colors.black54,
              width: 1,
            ),
          ),
          textStyle: const TextStyle(
            fontSize: 20,
            color: Colors.black,
          ),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Super Admin"),
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

      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            buildOutlinedButton(
              context,
              "Administrator",
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminPage()),
                );
              },
            ),

            buildOutlinedButton(
              context,
              "Kingdom Fort Lauderdale",
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LocationAccessPage(
                      location: "Kingdom Fort Lauderdale",
                    ),
                  ),
                );
              },
            ),

            buildOutlinedButton(
              context,
              "Kingdom Boca Raton",
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LocationAccessPage(
                      location: "Kingdom Boca Raton",
                    ),
                  ),
                );
              },
            ),

            buildOutlinedButton(
              context,
              "Kingdom Port St. Lucie",
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LocationAccessPage(
                      location: "Kingdom Port St. Lucie",
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}