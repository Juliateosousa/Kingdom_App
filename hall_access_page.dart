import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'login_page.dart';
import 'hall_page.dart';
import 'hall_pedido_page.dart';

class HallAccessPage extends StatelessWidget {
  final String location;

  const HallAccessPage({
    super.key,
    required this.location,
  });

  String get shortLoc {
    if (location == "Kingdom Boca Raton") return "KBR";
    if (location == "Kingdom Fort Lauderdale") return "KFL";
    if (location == "Kingdom Port St. Lucie") return "KPL";
    return location;
  }

  // ⭐ REUSABLE BUTTON (black text + black edge, NO white background)
  ButtonStyle get customButtonStyle {
    return ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 20),
      minimumSize: const Size(double.infinity, 60),

      // black text
      foregroundColor: Colors.black,

      // keep default background (NO white!!!)

      // black border
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(
          color: Colors.black,
          width: 1.2,
        ),
      ),

      textStyle: const TextStyle(
        fontSize: 18,
        color: Colors.black,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Salão - $shortLoc"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // LISTA BUTTON
            ElevatedButton(
              style: customButtonStyle,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HallPage(location: location),
                  ),
                );
              },
              child: const Text("Lista"),
            ),

            const SizedBox(height: 20),

            // PEDIDO BUTTON
            ElevatedButton(
              style: customButtonStyle,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HallPedidoPage(location: location),
                  ),
                );
              },
              child: const Text("Pedido"),
            ),
          ],
        ),
      ),
    );
  }
}
