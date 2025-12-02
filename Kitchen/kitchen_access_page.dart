import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'login_page.dart';

const List<String> kLocations = [
  "Kingdom Boca Raton",
  "Kingdom Fort Lauderdale",
  "Kingdom Port St. Lucie",
];

const List<String> kitchenExpectedListIds = [
  "kitchen1",
  "kitchen2",
  "kitchen3",
  "kitchen4",
];

const List<String> kitchenListNames = [
  "Meats",
  "Veggies",
  "Dry Storage",
  "Frozen",
];

String shortLocation(String location) {
  if (location == "Kingdom Boca Raton") return "KBR";
  if (location == "Kingdom Fort Lauderdale") return "KFL";
  if (location == "Kingdom Port St. Lucie") return "KPL";   // 👈 ADICIONADO
  return location;
}

/// =======================================
/// TELA INICIAL DA COZINHA
/// =======================================
class KitchenAccessPage extends StatefulWidget {
  const KitchenAccessPage({super.key});

  @override
  State<KitchenAccessPage> createState() => _KitchenAccessPageState();
}

class _KitchenAccessPageState extends State<KitchenAccessPage> {
  String selectedLocation = kLocations.first;

  @override
  Widget build(BuildContext context) {
    final title = "Kitchen - ${shortLocation(selectedLocation)}";

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Selecione a unidade:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Row(
              children: kLocations.map((loc) {
                final bool isSelected = loc == selectedLocation;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected
                            ? const Color(0xFF557847)
                            : const Color(0xFFA3A3A3),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          selectedLocation = loc;
                        });
                      },
                      child: Text(loc, textAlign: TextAlign.center),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            const Text(
              "Selecione a lista da cozinha:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: ListView.builder(
                itemCount: kitchenExpectedListIds.length,
                itemBuilder: (context, index) {
                  final listId = kitchenExpectedListIds[index];
                  final listName = kitchenListNames[index];

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Text(listName),
                      subtitle: Text("Lista: $listId"),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => KitchenListPage(
                              location: selectedLocation,
                              listId: listId,
                              listName: listName,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// =======================================
/// TELA DE UMA LISTA DA COZINHA
/// =======================================
class KitchenListPage extends StatelessWidget {
  final String location;
  final String listId;
  final String listName;

  const KitchenListPage({
    super.key,
    required this.location,
    required this.listId,
    required this.listName,
  });

  @override
  Widget build(BuildContext context) {
    final itemsRef = FirebaseFirestore.instance
        .collection('lists')
        .doc(listId)
        .collection('items');

    final title =
        "Kitchen - ${shortLocation(location)} - $listName";

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: itemsRef.orderBy('name').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          Future<void> sendToFinished() async {
            final itemsData = docs.map((d) {
              final data = Map<String, dynamic>.from(d.data() as Map);
              return {
                'name': data['name'] ?? '',
                'value': data['value'] ?? 0,
                'minStockKBR': data['minStockKBR'] ?? 0,
                'order': data['order'] ?? 0,
              };
            }).toList();

            final finishedRef = FirebaseFirestore.instance
                .collection('finishedLists')
                .doc(
                  "${shortLocation(location)}-Kitchen-$listId",
                );

            await finishedRef.set({
              'location': location,
              'category': 'Kitchen',
              'listName': listName,
              'listId': listId,
              'items': itemsData,
              'createdAt': FieldValue.serverTimestamp(),
            });

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Pedido da cozinha enviado para o admin!"),
                ),
              );
            }
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data =
                        Map<String, dynamic>.from(doc.data() as Map);

                    final name = data['name']?.toString() ?? '';
                    final estoque = data['value'] ?? 0;
                    final minStock = data['minStockKBR'] ?? 0;
                    final order =
                        ((data['order'] ?? 0) as num).toInt();

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text(name),
                        subtitle: Text(
                          "Estoque: $estoque   Min: $minStock",
                          style: const TextStyle(fontSize: 13),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () {
                                itemsRef.doc(doc.id).update({
                                  'order': order > 0 ? order - 1 : 0,
                                });
                              },
                            ),
                            Text("$order"),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                itemsRef.doc(doc.id).update({
                                  'order': order + 1,
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Botão enviar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton(
                  onPressed: sendToFinished,
                  child: const Text(
                    "Enviar pedido desta lista",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
