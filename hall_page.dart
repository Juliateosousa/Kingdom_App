import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:printing/printing.dart';

import 'hall_pdf_service.dart';
import 'login_page.dart';

class HallPage extends StatelessWidget {
  /// "Kingdom Boca Raton", "Kingdom Fort Lauderdale" ou "Kingdom Port St. Lucie"
  final String location;

  const HallPage({
    super.key,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    // IDs dos documentos no Firestore (salão)
    final List<String> listIds = [
      "list1",
      "list2",
      "list3",
      "list4",
      "list5",
      "list6",
      "list7",
      "list8",
      "list9",
    ];

    // Nomes bonitos que aparecem na tela (salão)
    final List<String> listNames = [
      "All Brazillian",
      "Walmart",
      "Costco",
      "Restaurant Depot",
      "Southern Glazer's",
      "Beers",
      "Bottles",
      "To Go",
      "Fruits",
    ];

    const String category = "Hall";
    final finishedColl =
        FirebaseFirestore.instance.collection('finishedLists');

    // ========= CAMPOS POR UNIDADE =========
    late final String valueField;
    late final String minField;
    late final String orderField;

    if (location == "Kingdom Fort Lauderdale") {
      valueField = "valueKFL";
      minField = "minStockKFL";
      orderField = "orderKFL";
    } else if (location == "Kingdom Port St. Lucie") {
      valueField = "valueKPL";
      minField = "minStockKPL";
      orderField = "orderKPL";
    } else {
      valueField = "valueKBR";
      minField = "minStockKBR";
      orderField = "orderKBR";
    }

    // ========= FINALIZAR TODAS AS LISTAS =========
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
          if (snap.docs.isEmpty) continue;

          final items = snap.docs.map((doc) {
            final data = Map<String, dynamic>.from(doc.data() as Map);

            final num valueNum =
                (data[valueField] ?? data["value"] ?? 0) as num;
            final num minNum =
                (data[minField] ?? data["minStock"] ?? 0) as num;
            final num orderNum =
                (data[orderField] ?? data["order"] ?? 0) as num;

            final bool isUrgent =
                (data['isUrgent'] ?? false) as bool;
            final bool isZeroX =
                (data['isZeroX'] ?? false) as bool;

            return {
              "name": data["name"],
              "value": valueNum.toInt(),
              "minStock": minNum,
              "order": orderNum.toInt(),
              "isUrgent": isUrgent,
              "isZeroX": isZeroX,
            };
          }).toList();

          // remove docs antigos dessa combinação
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
            "sentToHall": false,
          });

          anySent = true;
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(anySent
                  ? "Listas enviadas para o Admin!"
                  : "Nenhuma lista continha itens."),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erro ao finalizar listas: $e")),
          );
        }
      }
    }

    // ========= LIMPAR TODAS AS LISTAS =========
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

            final num currentValue =
                (data[valueField] ?? data["value"] ?? 0) as num;
            final bool isUrgent =
                (data['isUrgent'] ?? false) as bool;
            final bool isZeroX =
                (data['isZeroX'] ?? false) as bool;

            if (currentValue != 0 || isUrgent || isZeroX) {
              await doc.reference.update({
                valueField: 0,
                'isUrgent': false,
                'isZeroX': false,
              });
              anyUpdated = true;
            }
          }
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(anyUpdated
                  ? "Todas as listas foram limpas!"
                  : "Nenhum valor para limpar."),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erro ao limpar listas: $e")),
          );
        }
      }
    }

    final shortLoc = location == "Kingdom Fort Lauderdale"
        ? "KFL"
        : location == "Kingdom Port St. Lucie"
            ? "KPL"
            : "KBR";

    return Scaffold(
      appBar: AppBar(
        title: Text("Salão - $shortLoc"),
        actions: [
          // Botão Limpar Lista
          TextButton(
            onPressed: clearAllLists,
            child: const Text(
              "Limpar Lista",
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // 🔴 AGORA ESTE É O BOTÃO DE PDF — NO LUGAR DO LOGOUT
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () async {
              try {
                final bytes = await HallPdfService.generateHallPdf(
                  location: location,
                  shortLoc: shortLoc,
                  listIds: listIds,
                  listNames: listNames,
                  valueField: valueField,
                  minField: minField,
                  orderField: orderField,
                );

                await Printing.sharePdf(
                  bytes: bytes,
                  filename: 'hall_$shortLoc.pdf',
                );
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao gerar PDF: $e'),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),

      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              key: PageStorageKey('hall-$location'),
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
                          stream: listRef.orderBy('name').snapshots(),
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
                                    (data[valueField] ??
                                            data["value"] ??
                                            0) as num;
                                final int value = valueNum.toInt();

                                final bool isUrgent =
                                    (data['isUrgent'] ?? false) as bool;
                                final bool isZeroX =
                                    (data['isZeroX'] ?? false) as bool;

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
                                    final snap =
                                        await item.reference.get();
                                    final latest =
                                        Map<String, dynamic>.from(
                                            snap.data() as Map);
                                    final bool currentX =
                                        (latest['isZeroX'] ?? false)
                                            as bool;

                                    await item.reference.update({
                                      'isZeroX': !currentX,
                                    });

                                    return false;
                                  },
                                  child: Card(
                                    color: cardColor,
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 4),
                                    child: ListTile(
                                      title: Text(name),
                                      trailing: Row(
                                        mainAxisSize:
                                            MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon:
                                                const Icon(Icons.remove),
                                            onPressed: () {
                                              if (!showX &&
                                                  value > 0) {
                                                item.reference
                                                    .update({
                                                  valueField:
                                                      value - 1,
                                                });
                                              }
                                            },
                                          ),
                                          Text(
                                            valueLabel,
                                            style:
                                                const TextStyle(
                                              fontSize: 16,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.add),
                                            onPressed: () {
                                              if (!showX) {
                                                item.reference
                                                    .update({
                                                  valueField:
                                                      value + 1,
                                                });
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                      onLongPress: () {
                                        item.reference.update({
                                          'isUrgent': !isUrgent,
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

          // BOTÃO FINALIZAR
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
