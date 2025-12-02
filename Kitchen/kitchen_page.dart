import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:printing/printing.dart';

import 'login_page.dart';
import 'kitchen_pdf_service.dart';

class KitchenPage extends StatelessWidget {
  final String location;
  final bool showBackArrow;

  const KitchenPage({
    super.key,
    required this.location,
    this.showBackArrow = false,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> listIds = [
      "kitchen1",
      "kitchen2",
      "kitchen3",
      "kitchen4",
      "kitchen5",
      "kitchen6",
      "kitchen7",
      "kitchen8",
      "kitchen9",
      "kitchen10",
      "kitchen11",
    ];

    // Nomes bonitos que aparecem na tela (fornecedores da cozinha)
    final List<String> listNames = [
      "Wismettac Asian",
      "KGI",
      "Luso Foods",
      "BAVE",
      "Costco",
      "Walmart",
      "Amazon",
      "Asiatico Boca",
      "CHerney Brother",
      "Sysco & US Foods",
      "Restaurant Depot",
    ];

    const category = "Kitchen"; // essa tela é da Kitchen
    final finishedColl =
        FirebaseFirestore.instance.collection('finishedLists');

    // 👇 Campos que mudam conforme a unidade (3 unidades)
    late final String valueField;
    late final String minField;
    late final String orderField;
    late final String urgentField;
    late final String zeroXField;

    if (location == "Kingdom Fort Lauderdale") {
      valueField  = "valueKFL";
      minField    = "minStockKFL";
      orderField  = "orderKFL";
      urgentField = "isUrgentKFL";
      zeroXField  = "isZeroXKFL";
    } else if (location == "Kingdom Port St. Lucie") {
      valueField  = "valueKPL";
      minField    = "minStockKPL";
      orderField  = "orderKPL";
      urgentField = "isUrgentKPL";
      zeroXField  = "isZeroXKPL";
    } else {
      valueField  = "valueKBR";
      minField    = "minStockKBR";
      orderField  = "orderKBR";
      urgentField = "isUrgentKBR";
      zeroXField  = "isZeroXKBR";
    }

    Future<void> finalizeAllLists() async {
      bool anySent = false;

      try {
        for (int i = 0; i < listIds.length; i++) {
          final listId = listIds[i];
          final listName = listNames[i];

          final listRef = FirebaseFirestore.instance
              .collection('lists')
              .doc(listId)
              .collection('items');

          final snap = await listRef.get();
          if (snap.docs.isEmpty) {
            continue;
          }

          final items = snap.docs.map((doc) {
            final data = Map<String, dynamic>.from(doc.data() as Map);

            final num valueNum = (data[valueField] ?? 0) as num;
            final num minNum   = (data[minField]   ?? 0) as num;
            final num orderNum = (data[orderField] ?? 0) as num;
            final bool isUrgent = (data[urgentField] ?? false) as bool;
            final bool isZeroX  = (data[zeroXField]  ?? false) as bool;

            return {
              "name": data["name"],
              "value": valueNum.toInt(),
              "minStock": minNum,
              "order": orderNum.toInt(),
              "isUrgent": isUrgent,
              "isZeroX": isZeroX,
            };
          }).toList();

          final old = await finishedColl
              .where('location', isEqualTo: location)
              .where('category', isEqualTo: category)
              .where('listId', isEqualTo: listId)
              .get();

          for (final d in old.docs) {
            await d.reference.delete();
          }

          await finishedColl.add({
            "location": location,
            "category": category,
            "listId": listId,
            "listName": listName,
            "items": items,
            "createdAt": FieldValue.serverTimestamp(),
          });

          anySent = true;
        }

        if (!anySent) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Nenhuma lista com itens para finalizar."),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Todas as listas da cozinha de $location foram enviadas para o admin!",
              ),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao finalizar listas: $e")),
        );
      }
    }

    Future<void> clearAllLists() async {
      bool anyUpdated = false;

      try {
        for (final listId in listIds) {
          final listRef = FirebaseFirestore.instance
              .collection('lists')
              .doc(listId)
              .collection('items');

          final snap = await listRef.get();
          if (snap.docs.isEmpty) continue;

          for (final doc in snap.docs) {
            final data = Map<String, dynamic>.from(doc.data() as Map);
            final num currentValue = (data[valueField] ?? 0) as num;
            final bool isUrgent = (data[urgentField] ?? false) as bool;
            final bool isZeroX  = (data[zeroXField]  ?? false) as bool;

            if (currentValue != 0 || isUrgent || isZeroX) {
              await doc.reference.update({
                valueField: 0,
                urgentField: false,
                zeroXField: false,
              });
              anyUpdated = true;
            }
          }
        }

        if (!anyUpdated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Nenhum valor para limpar."),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Todas as listas da cozinha foram limpas!"),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao limpar listas: $e")),
        );
      }
    }

    Future<void> shareKitchenPdf() async {
      try {
        final bytes = await KitchenPdfService.generateKitchenPdf(
          location: location,
          listIds: listIds,
          listNames: listNames,
          valueField: valueField,
          minField: minField,
          orderField: orderField,
        );

        await Printing.sharePdf(
          bytes: bytes,
          filename: 'Kitchen_${location.replaceAll(" ", "_")}.pdf',
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao gerar PDF da Kitchen: $e'),
          ),
        );
      }
    }

    Future<void> confirmAndClear() async {
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text("Limpar listas"),
            content: const Text(
              "Tem certeza que deseja limpar TODAS as listas da cozinha?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text("Não"),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text(
                  "Sim",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      );

      if (confirm == true) {
        await clearAllLists();
      }
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: showBackArrow,

        leading: showBackArrow
            ? null
            : IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                onPressed: shareKitchenPdf,
              ),

        title: Text("Kitchen - $location"),

        actions: [
          TextButton(
            onPressed: () async {
              await confirmAndClear();
            },
            child: const Text(
              "Limpar Lista",
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          if (showBackArrow)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: shareKitchenPdf,
            )
          else
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
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              key: PageStorageKey('kitchen-$location'),
              padding: const EdgeInsets.all(12),
              itemCount: listIds.length,
              itemBuilder: (context, index) {
                final listId = listIds[index];
                final listName = listNames[index];

                final listRef = FirebaseFirestore.instance
                    .collection('lists')
                    .doc(listId)
                    .collection('items');

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          listName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(),

                        StreamBuilder<QuerySnapshot>(
                          stream: listRef.snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Text("Error: ${snapshot.error}");
                            }
                            if (!snapshot.hasData) {
                              return const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            }

                            final docs = snapshot.data!.docs;

                            if (docs.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  "No items.",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              );
                            }

                            return ListView.builder(
                              key: PageStorageKey(
                                  'kitchen-$location-$listId'),
                              shrinkWrap: true,
                              physics:
                                  const NeverScrollableScrollPhysics(),
                              itemCount: docs.length,
                              itemBuilder: (context, i) {
                                final item = docs[i];
                                final data = Map<String, dynamic>.from(
                                  item.data() as Map,
                                );

                                final String name =
                                    data['name']?.toString() ?? '';

                                final num valueNum =
                                    (data[valueField] ?? 0) as num;
                                final int value = valueNum.toInt();

                                final bool isUrgent =
                                    (data[urgentField] ?? false) as bool;
                                final bool isZeroX =
                                    (data[zeroXField] ?? false) as bool;

                                final bool showX = isZeroX;

                                Color? cardColor;
                                if (isUrgent) {
                                  cardColor = Colors.red.shade100;
                                }
                                if (showX) {
                                  cardColor = Colors.grey.shade300;
                                }

                                final String valueLabel =
                                    showX ? "X" : value.toString();

                                return Dismissible(
                                  key: ValueKey(item.id),
                                  direction:
                                      DismissDirection.startToEnd,
                                  background: Container(
                                    alignment: Alignment.centerLeft,
                                    padding:
                                        const EdgeInsets.only(left: 16),
                                    color: Colors.grey.shade500,
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                    ),
                                  ),
                                  confirmDismiss:
                                      (DismissDirection direction) async {
                                    final bool current =
                                        (data[zeroXField] ?? false) as bool;
                                    await item.reference.update({
                                      zeroXField: !current,
                                    });
                                    return false;
                                  },
                                  child: Card(
                                    color: cardColor,
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: ListTile(
                                      title: Text(name),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon:
                                                const Icon(Icons.remove),
                                            onPressed: () {
                                              if (!showX && value > 0) {
                                                item.reference.update({
                                                  valueField: value - 1,
                                                });
                                              }
                                            },
                                          ),
                                          Text(
                                            valueLabel,
                                            style: const TextStyle(
                                              fontSize: 16,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.add),
                                            onPressed: () {
                                              if (!showX) {
                                                item.reference.update({
                                                  valueField: value + 1,
                                                });
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                      onLongPress: () {
                                        item.reference.update({
                                          urgentField: !isUrgent,
                                        });
                                      },
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // BOTÃO FINALIZAR NO RODAPÉ
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: finalizeAllLists,
                child: const Text(
                  "Finalizar",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
