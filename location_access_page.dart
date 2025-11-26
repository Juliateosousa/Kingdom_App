import 'package:flutter/material.dart';

import 'hall_access_page.dart';
import 'kitchen_page.dart';

class LocationAccessPage extends StatelessWidget {
  final String location;

  const LocationAccessPage({
    super.key,
    required this.location,
  });

  String get shortLoc {
    if (location == "Kingdom Fort Lauderdale") return "KFL";
    if (location == "Kingdom Boca Raton") return "KBR";
    if (location == "Kingdom Port St. Lucie") return "KPL";
    return location;
  }

  // ⭐ Reusable style: black text + black edge, NO white background
  ButtonStyle get customButtonStyle {
    return ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 20),
      minimumSize: const Size(double.infinity, 60),
      foregroundColor: Colors.black, // text color
      // backgroundColor: not set → uses default theme color
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
        title: Text("Select Area - $shortLoc"),
        // aqui a seta de voltar já aparece automaticamente,
        // porque essa página foi aberta com Navigator.push
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // HALL BUTTON
            ElevatedButton(
              style: customButtonStyle,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HallAccessPage(
                      location: location,
                    ),
                  ),
                );
              },
              child: const Text("Salão"),
            ),

            const SizedBox(height: 20),

            // KITCHEN BUTTON (com seta de voltar na KitchenPage)
            ElevatedButton(
              style: customButtonStyle,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => KitchenPage(
                      location: location,
                      showBackArrow: true, // 👈 seta só nesse fluxo
                    ),
                  ),
                );
              },
              child: const Text("Kitchen"),
            ),
          ],
        ),
      ),
    );
  }
}
