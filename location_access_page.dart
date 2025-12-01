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

  ButtonStyle get customButtonStyle {
    return ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 20),
      minimumSize: const Size(double.infinity, 60),
      foregroundColor: Colors.black, // text color
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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

            ElevatedButton(
              style: customButtonStyle,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => KitchenPage(
                      location: location,
                      showBackArrow: true,
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