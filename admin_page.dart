import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'login_page.dart';

String translateCategory(String category) {
  switch (category) {
    case "Hall":
      return "Salão";
    case "Kitchen":
      return "Kitchen";
    default:
      return category;
  }
}
/// Location
String shortLocation(String location) {
  if (location == "Kingdom Boca Raton") return "KBR";
  if (location == "Kingdom Fort Lauderdale") return "KFL";
  if (location == "Kingdom Port St. Lucie") return "KPL";
  return location;
}

/// =======================================
/// 1 - Selecionar Local
/// =======================================
class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  void _goToLocation(BuildContext context, String location) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminCategoryPage(location: location),
      ),
    );
  }

  /// Carregar itens base (seed)
  Future<void> _seedAllItems(BuildContext context) async {
    final firestore = FirebaseFirestore.instance;

    WriteBatch batch = firestore.batch();
    int count = 0;

    hallSeedData.forEach((listId, items) {
      final listRef =
          firestore.collection('lists').doc(listId).collection('items');

      for (final item in items) {
        final minKBR = (item['minStockKBR'] as num?)?.toDouble() ?? 0.0;
        final minKFL = (item['minStockKFL'] as num?)?.toDouble() ?? 0.0;
        final minKPL = (item['minStockKPL'] as num?)?.toDouble() ?? 0.0;

        final docRef = listRef.doc(); // id automático

        batch.set(docRef, {
          "name": item['name'] ?? "",
          "valueKBR": 0,
          "valueKFL": 0,
          "valueKPL": 0,
          "minStockKBR": minKBR,
          "minStockKFL": minKFL,
          "minStockKPL": minKPL,
          "orderKBR": 0,
          "orderKFL": 0,
          "orderKPL": 0,
        });

        count++;

        if (count % 450 == 0) {
          batch.commit();
          batch = firestore.batch();
        }
      }
    });

    await batch.commit();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Itens base carregados em lists/{kitchenX}/items e lists/{listX}/items.",
          ),
        ),
      );
    }
  }

  /// Cor do botão da unidade (Boca/Fort) baseado em Hall + Kitchen
  Color _locationStatusColor(List<QueryDocumentSnapshot> docsForLocation) {
    // Vamos olhar apenas listas que ainda NÃO foram finalizadas pelo admin
    bool hallHas = false;
    bool kitchenHas = false;

    for (final d in docsForLocation) {
      final data = Map<String, dynamic>.from(d.data() as Map);
      final cat = (data['category'] ?? '').toString();
      final sentToHall = data['sentToHall'] == true;

      if (sentToHall) continue; // ignorar pedidos já finalizados

      if (cat == 'Hall') {
        hallHas = true;
      } else if (cat == 'Kitchen') {
        kitchenHas = true;
      }
    }

    final countGreen = (hallHas ? 1 : 0) + (kitchenHas ? 1 : 0);

    // 0 botões internos verdes → VERMELHO
    if (countGreen == 0) {
      return const Color(0xFF752A1B); // RED
    }

    // 1 botão interno verde → AMARELO
    if (countGreen == 1) {
      return const Color(0xFFD19E2A); // YELLOW
    }

    // 2 botões internos verdes → VERDE
    return const Color(0xFF557847); // GREEN
  }

  @override
  Widget build(BuildContext context) {
    final finishedColl =
        FirebaseFirestore.instance.collection('finishedLists');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin - Selecionar Unidade"),
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
      body: StreamBuilder<QuerySnapshot>(
        stream: finishedColl.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          final bocaDocs = docs.where((d) {
            final data = Map<String, dynamic>.from(d.data() as Map);
            return (data['location'] ?? '') == "Kingdom Boca Raton";
          }).toList();

          final fortDocs = docs.where((d) {
            final data = Map<String, dynamic>.from(d.data() as Map);
            return (data['location'] ?? '') == "Kingdom Fort Lauderdale";
          }).toList();
          final portDocs = docs.where((d) {
            final data = Map<String, dynamic>.from(d.data() as Map);
            return (data['location'] ?? '') == "Kingdom Port St. Lucie";
          }).toList();

          final bocaColor = _locationStatusColor(bocaDocs);
          final fortColor = _locationStatusColor(fortDocs);
          final portColor = _locationStatusColor(portDocs);

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Kingdom Boca Raton
                // Boca
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () =>
                        _goToLocation(context, "Kingdom Boca Raton"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      textStyle: const TextStyle(fontSize: 18),
                      backgroundColor: bocaColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Kingdom Boca Raton"),
                  ),
                ),

                const SizedBox(height: 16),

                // Fort
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () =>
                        _goToLocation(context, "Kingdom Fort Lauderdale"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      textStyle: const TextStyle(fontSize: 18),
                      backgroundColor: fortColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Kingdom Fort Lauderdale"),
                  ),
                ),

                const SizedBox(height: 16),

                // ✅ Port St. Lucie
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () =>
                        _goToLocation(context, "Kingdom Port St. Lucie"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      textStyle: const TextStyle(fontSize: 18),
                      backgroundColor: portColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Kingdom Port St. Lucie"),
                  ),
                ),


                // 👉 Botão: Carregar itens base (seed)
                // SizedBox(
                  // width: double.infinity,
                  // child: ElevatedButton(
                    // onPressed: () async {
                      // await _seedAllItems(context);
                    // },
                    // style: ElevatedButton.styleFrom(
                      // padding: const EdgeInsets.symmetric(vertical: 16),
                      // backgroundColor: Colors.blueGrey,
                      // foregroundColor: Colors.white,
                    // ),
                    // child: const Text(
                      // "Carregar itens base",
                      // style: TextStyle(fontSize: 16),
                    // ),
                  // ),
                // ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// =======================================
/// 2 - Selecionar Categoria(Salão + Kitchen + Pedido)
/// =======================================
class AdminCategoryPage extends StatelessWidget {
  final String location;

  const AdminCategoryPage({
    super.key,
    required this.location,
  });

  void _goToCategory(BuildContext context, String category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminListsPage(
          location: location,
          category: category,
        ),
      ),
    );
  }

  // Pedido do ADMIN, usa AdminPedidoPage
  void _goToPedido(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminPedidoPage(location: location),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = "Admin - ${shortLocation(location)}";

    final finishedColl =
        FirebaseFirestore.instance.collection('finishedLists');

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
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
      body: StreamBuilder<QuerySnapshot>(
        stream: finishedColl.where('location', isEqualTo: location).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          bool hasCategory(String category) {
            return docs.any((d) {
              final data = Map<String, dynamic>.from(d.data() as Map);

              final cat = (data['category'] ?? '').toString();
              final sentToHall = data['sentToHall'] == true;

              // Só conta listas que AINDA NÃO foram finalizadas pelo admin
              return cat == category && !sentToHall;
            });
          }

          final hallHas = hasCategory('Hall');
          final kitchenHas = hasCategory('Kitchen');

          Color colorFor(bool has) =>
              has ? const Color(0xFF557847) : const Color(0xFFA3A3A3);

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Hall (Salão)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _goToCategory(context, "Hall"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      textStyle: const TextStyle(fontSize: 18),
                      backgroundColor: colorFor(hallHas),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Salão"),
                  ),
                ),
                const SizedBox(height: 16),

                // Kitchen
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _goToCategory(context, "Kitchen"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      textStyle: const TextStyle(fontSize: 18),
                      backgroundColor: colorFor(kitchenHas),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Kitchen"),
                  ),
                ),

                const SizedBox(height: 32),

                // PEDIDO (AdminPedidoPage)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _goToPedido(context),
                    icon: const Icon(Icons.shopping_cart),
                    label: const Text(
                      "Pedido",
                      style: TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blueGrey,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// =======================================
/// 3 - Visualização da lista
/// =======================================
class AdminListsPage extends StatelessWidget {
  final String location;
  final String category;

  const AdminListsPage({
    super.key,
    required this.location,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final label = category == "Hall" ? "Salão" : category;
    final title = "Admin - ${shortLocation(location)} - $label";

    // 👉 Confirmação antes de limpar os pedidos
    Future<void> confirmAndClearOrders() async {
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text("Limpar pedidos"),
            content: const Text(
              "Tem certeza que deseja zerar TODOS os pedidos desta categoria?",
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

      if (confirm != true) return;

      try {
        final query = await FirebaseFirestore.instance
            .collection('finishedLists')
            .where('location', isEqualTo: location)
            .where('category', isEqualTo: category)
            .get();

        final batch = FirebaseFirestore.instance.batch();

        for (final d in query.docs) {
          final data = Map<String, dynamic>.from(d.data() as Map);
          final itemsRaw = data['items'] as List<dynamic>? ?? [];
          final items = itemsRaw
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();

          for (final item in items) {
            item['order'] = 0; // zera SÓ o pedido
          }

          batch.update(d.reference, {'items': items});
        }

        await batch.commit();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Todos os pedidos foram zerados!"),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Erro ao limpar lista: $e"),
            ),
          );
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          // 👉 BOTÃO: LIMPAR LISTA (zera apenas PEDIDO / order) COM CONFIRMAÇÃO
          TextButton(
            onPressed: () async {
              await confirmAndClearOrders();
            },
            child: const Text(
              "Limpar Lista",
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

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

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('finishedLists')
            .where('location', isEqualTo: location)
            .where('category', isEqualTo: category)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (category == "Hall" || category == "Kitchen") {
            return Column(
              children: [
                Expanded(
                  child: _buildSections(context, docs, category),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () async {
                        try {
                          final batch =
                              FirebaseFirestore.instance.batch();

                          // marca TODOS os docs dessa categoria/unidade
                          // como "enviados" (desliga status, mantém pedido)
                          for (final d in docs) {
                            batch.update(d.reference, {
                              'sentToHall': true,
                              'lastFinalizedAt':
                                  FieldValue.serverTimestamp(),
                            });
                          }

                          await batch.commit();

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Pedido enviado para o $label e status desligado!",
                              ),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text("Erro ao finalizar pedido: $e"),
                            ),
                          );
                        }
                      },
                      child: const Text(
                        "Finalizar",
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else {
            return _buildSimpleList(docs);
          }
        },
      ),
    );
  }

  // ===========================================================================
  // LISTA DE SEÇÕES (cada lista)
  // ===========================================================================
  Widget _buildSections(
    BuildContext context,
    List<QueryDocumentSnapshot> docs,
    String category,
  ) {
    final listIds =
        category == "Kitchen" ? kitchenExpectedListIds : hallExpectedListIds;

    final listNames =
        category == "Kitchen" ? kitchenListNames : hallListNames;

    final Map<String, QueryDocumentSnapshot> docByListId = {};

    for (final d in docs) {
      final data = Map<String, dynamic>.from(d.data() as Map);
      final id = (data['listId'] ?? d.id).toString();
      docByListId[id] = d;
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: listIds.length,
      itemBuilder: (context, index) {
        final listId = listIds[index];
        final listName = listNames[index];

        final doc = docByListId[listId];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // header com nome + botão de editar
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      listName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AdminListItemsEditPage(
                              listId: listId,
                              listName: listName,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const Divider(),

                if (doc == null)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      "Nenhuma lista enviada ainda.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                else
                  _HallSectionTable(docRef: doc.reference),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Usado só se surgir outra categoria no futuro
  Widget _buildSimpleList(List<QueryDocumentSnapshot> docs) {
    if (docs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "Nenhuma lista finalizada para:\n"
            "$location → $category",
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        final data = Map<String, dynamic>.from(doc.data() as Map);

        final listName = (data['listName'] ?? data['listId']).toString();

        return Card(
          child: ListTile(
            title: Text(listName),
            subtitle: Text(translateCategory(category)),
          ),
        );
      },
    );
  }
}

// ============================================================================
// 4 - Tabela de Itens
// ============================================================================
class _HallSectionTable extends StatelessWidget {
  final DocumentReference docRef;

  const _HallSectionTable({
    required this.docRef,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: docRef.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text("Erro: ${snapshot.error}");
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Text("Sem dados dessa lista.");
        }

        final raw = snapshot.data!.data();
        if (raw == null) {
          return const Text("Sem dados.");
        }

        final data = raw as Map<String, dynamic>;
        final itemsRaw = data['items'] as List<dynamic>? ?? [];

        final items = itemsRaw
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

        if (items.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text("Lista vazia."),
          );
        }

        Future<void> updateOrder(
          List<Map<String, dynamic>> currentItems,
          int index,
          int newOrder,
        ) async {
          if (newOrder < 0) newOrder = 0;

          final updated = List<Map<String, dynamic>>.from(currentItems);

          final item = Map<String, dynamic>.from(updated[index]);
          item['order'] = newOrder;

          updated[index] = item;
          await docRef.update({'items': updated});
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];

            final String name = (item['name'] ?? '').toString();
            final int estoque = (item['value'] as num?)?.toInt() ?? 0;
            final int min = (item['minStock'] as num?)?.toInt() ?? 0;
            final int order = (item['order'] as num?)?.toInt() ?? 0;

            // urgente = vermelho
            final bool urgent =
                (item['isUrgent'] == true) || (item['urgent'] == true);

            // >>> NOVO: flag "X"
            final bool isZeroX = (item['isZeroX'] ?? false) as bool;

            // 0 normal (sem X)
            final bool isZeroNormal = estoque == 0 && !isZeroX;

            // Texto que aparece no Estoque: X ou número
            final String estoqueText = isZeroX ? "X" : estoque.toString();

            // Cor do card (fundo do item)
            Color cardColor = Colors.white;
            Color cardBorderColor = Colors.grey.shade300;

            if (urgent) {
              cardColor = Colors.red.shade100;
              cardBorderColor = Colors.red;
            }

            if (isZeroX) {
              // X sobrescreve fundo para cinza
              cardColor = Colors.grey.shade300;
              cardBorderColor = Colors.grey.shade600;
            }

            // Cor de fundo/borda do quadrado do Estoque
            Color estoqueBoxColor;
            Color estoqueBorderColor;

            if (isZeroX) {
              // X: caixa cinza
              estoqueBoxColor = const Color.fromARGB(255, 200, 200, 200);
              estoqueBorderColor = const Color.fromARGB(255, 120, 120, 120);
            } else if (isZeroNormal) {
              // 0 normal: caixa roxa
              estoqueBoxColor = const Color(0xFFCA9AD6);
              estoqueBorderColor = const Color.fromARGB(255, 113, 47, 129);
            } else {
              // qualquer outro número
              estoqueBoxColor = const Color.fromARGB(255, 230, 214, 188);
              estoqueBorderColor = const Color.fromARGB(255, 194, 166, 121);
            }

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: cardBorderColor),
              ),
              child: ListTile(
                title: Text(
                  name,
                ),
                subtitle: Row(
                  children: [
                    // 👉 Quadrado (roxo se 0 normal, cinza se X, bege se outro número)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: estoqueBoxColor,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: estoqueBorderColor,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        "Estoque: $estoqueText",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isZeroNormal || isZeroX
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // 👉 "Min: X" NORMAL FORA DO QUADRADO
                    const SizedBox(width: 4),
                    Text(
                      "Min: $min",
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 20),
                      onPressed: () {
                        updateOrder(items, index, order - 1);
                      },
                    ),
                    Text(
                      order.toString(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 20),
                      onPressed: () {
                        updateOrder(items, index, order + 1);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
// ============================================================================
// 5 — AdminListItemsEditPage + AdminPedidoPage
// ============================================================================
class AdminListItemsEditPage extends StatelessWidget {
  final String listId;
  final String listName;

  const AdminListItemsEditPage({
    super.key,
    required this.listId,
    required this.listName,
  });

  double _parseMin(String input) {
    if (input.trim().isEmpty) return 0;

    // aceita fração tipo "1/2"
    if (input.contains("/")) {
      final parts = input.split("/");
      if (parts.length == 2) {
        final a = double.tryParse(parts[0].trim());
        final b = double.tryParse(parts[1].trim());
        if (a != null && b != null && b != 0) {
          return a / b;
        }
      }
    }

    return double.tryParse(input.trim().replaceAll(',', '.')) ?? 0;
  }

  // ==========================================================
  // POPUP DE EDITAR ITEM
  // ==========================================================
  void _showEditDialog(
    BuildContext context,
    DocumentReference<Map<String, dynamic>> docRef,
    Map<String, dynamic> data,
  ) {
    final nameController = TextEditingController(text: data['name']);
    final minController =
        TextEditingController(text: data['minStockKBR'].toString());
    final value = data['value']; // estoque atual (read-only)

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Editar Item"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Nome"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: minController,
                decoration: const InputDecoration(labelText: "Min"),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            // APAGAR
            TextButton(
              onPressed: () async {
                await docRef.delete();

                // remove também de finishedLists
                final snap = await FirebaseFirestore.instance
                    .collection('finishedLists')
                    .where('listId', isEqualTo: listId)
                    .get();

                for (final d in snap.docs) {
                  final listData = d.data();
                  final itemsRaw =
                      listData['items'] as List<dynamic>? ?? [];
                  final items = itemsRaw
                      .map((e) => Map<String, dynamic>.from(e as Map))
                      .toList();

                  final newItems = items
                      .where((item) => item['name'] != data['name'])
                      .toList();

                  if (newItems.length != items.length) {
                    await d.reference.update({'items': newItems});
                  }
                }

                Navigator.pop(ctx);
              },
              child: const Text(
                "Apagar",
                style: TextStyle(color: Colors.red),
              ),
            ),

            // CANCELAR
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancelar"),
            ),

            // OK / SALVAR
            ElevatedButton(
              onPressed: () async {
                final newName = nameController.text.trim();
                final newMin = _parseMin(minController.text.trim());

                if (newName.isEmpty) return;

                await docRef.update({
                  "name": newName,
                  "minStockKBR": newMin,
                });

                // atualiza também finishedLists
                final snap = await FirebaseFirestore.instance
                    .collection('finishedLists')
                    .where('listId', isEqualTo: listId)
                    .get();

                for (final d in snap.docs) {
                  final listData = d.data();
                  final itemsRaw =
                      listData['items'] as List<dynamic>? ?? [];
                  final items = itemsRaw
                      .map((e) => Map<String, dynamic>.from(e as Map))
                      .toList();

                  for (final item in items) {
                    if (item['name'] == data['name']) {
                      item['name'] = newName;
                      item['minStockKBR'] = newMin;
                    }
                  }

                  await d.reference.update({'items': items});
                }

                Navigator.pop(ctx);
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  // ==========================================================
  // POPUP DE ADICIONAR ITEM (SEU CÓDIGO ORIGINAL)
  // ==========================================================
  Future<void> _showAddDialog(
    BuildContext context,
    CollectionReference<Map<String, dynamic>> listRef,
  ) async {
    final nameController = TextEditingController();
    final minController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text("Adicionar item - $listName"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration:
                    const InputDecoration(labelText: "Nome do item"),
              ),
              TextField(
                controller: minController,
                decoration: const InputDecoration(
                  labelText: "Min (ex: 1/2, 0.5, 3)",
                ),
                keyboardType: TextInputType.text,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final min = _parseMin(minController.text.trim());

                if (name.isEmpty) return;

                final newDoc = await listRef.add({
                  "name": name,
                  "value": 0,
                  "minStockKBR": min,
                  "order": 0,
                });

                // sincroniza finishedLists (SEU CÓDIGO ORIGINAL)
                try {
                  final snap = await FirebaseFirestore.instance
                      .collection('finishedLists')
                      .where('listId', isEqualTo: listId)
                      .get();

                  for (final d in snap.docs) {
                    final data = Map<String, dynamic>.from(
                        d.data() as Map<String, dynamic>);
                    final itemsRaw =
                        data['items'] as List<dynamic>? ?? [];
                    final items = itemsRaw
                        .map((e) =>
                            Map<String, dynamic>.from(e as Map))
                        .toList();

                    items.add({
                      'name': name,
                      'value': 0,
                      'minStockKBR': min,
                      'order': 0,
                      'docId': newDoc.id,
                    });

                    await d.reference.update({'items': items});
                  }
                } catch (_) {}

                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text("Adicionar"),
            ),
          ],
        );
      },
    );
  }

  // ==========================================================
  // TELA PRINCIPAL — NÃO MEXI EM NADA!
  // ==========================================================
  @override
  Widget build(BuildContext context) {
    final listRef = FirebaseFirestore.instance
        .collection('lists')
        .doc(listId)
        .collection('items')
        .withConverter<Map<String, dynamic>>(
          fromFirestore: (snap, _) =>
              Map<String, dynamic>.from(snap.data() ?? {}),
          toFirestore: (data, _) => data,
        );

    return Scaffold(
      appBar: AppBar(
        title: Text("Itens - $listName"),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, listRef),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: listRef.orderBy('name').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Erro: ${snapshot.error}"));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "Nenhum item cadastrado.",
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();

              final name = data['name'] ?? "";
              final min = data['minStockKBR'] ?? 0;
              final value = data['value'] ?? 0;

              return Card(
                child: ListTile(
                  title: Text(name),
                  subtitle: Text(
                    "Estoque atual: $value   Min: $min",
                    style: const TextStyle(fontSize: 13),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      _showEditDialog(context, doc.reference, data);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
/// ============================================================================
/// 6 - Resumo do pedido - AdminPedidoPage
/// ============================================================================
class AdminPedidoPage extends StatefulWidget {
  final String location;

  const AdminPedidoPage({
    super.key,
    required this.location,
  });

  @override
  State<AdminPedidoPage> createState() => _AdminPedidoPageState();
}

class _AdminPedidoPageState extends State<AdminPedidoPage> {
  // id -> checked (id = "${doc.id}::$index")
  final Map<String, bool> _checked = {};

  bool get _hasChecked => _checked.values.any((v) => v == true);

  Future<void> _cleanChecked() async {
    final ids = _checked.entries
        .where((e) => e.value == true)
        .map((e) => e.key)
        .toList();

    if (ids.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nenhum item marcado.")),
      );
      return;
    }

    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      // Agrupa por documento (finishedLists/{docId})
      final Map<String, List<int>> byDocId = {};

      for (final id in ids) {
        final parts = id.split("::");
        if (parts.length != 2) continue;

        final docId = parts[0];
        final index = int.tryParse(parts[1]) ?? -1;
        if (index < 0) continue;

        byDocId.putIfAbsent(docId, () => []).add(index);
      }

      // Para cada doc, zera o "order" dos itens marcados
      for (final entry in byDocId.entries) {
        final docId = entry.key;
        final indices = entry.value;

        final docRef =
            firestore.collection('finishedLists').doc(docId);
        final snap = await docRef.get();
        if (!snap.exists) continue;

        final data = snap.data() as Map<String, dynamic>;
        final itemsRaw = data['items'] as List<dynamic>? ?? [];
        final items = itemsRaw
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

        for (final idx in indices) {
          if (idx >= 0 && idx < items.length) {
            final item = Map<String, dynamic>.from(items[idx]);
            item['order'] = 0; // limpa o pedido
            items[idx] = item;
          }
        }

        batch.update(docRef, {'items': items});
      }

      await batch.commit();

      setState(() {
        _checked.clear();
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Itens marcados foram limpos do pedido."),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro ao limpar itens: $e"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final title =
        "Admin - ${shortLocation(widget.location)} - Pedido";

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          // 👇 NEW: botão para ver histórico por dia
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: "Ver pedidos por dia",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AdminPedidoHistoryPage(
                    location: widget.location,
                  ),
                ),
              );
            },
          ),

          // 🔘 BOTÃO CLEAN CHECKED (já existia)
          TextButton(
            onPressed: _hasChecked ? _cleanChecked : null,
            child: const Text(
              "Clean checked",
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => const LoginPage(),
                ),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('finishedLists')
            .where('location', isEqualTo: widget.location)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text("Erro: ${snapshot.error}"),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final docs = snapshot.data!.docs;

          // Agrupar por listName (independente se é Hall ou Kitchen)
          final Map<String, List<_EnvioItem>> byList = {};

          for (final doc in docs) {
            final data =
                Map<String, dynamic>.from(doc.data() as Map);

            final category =
                (data['category'] ?? "").toString();
            final listName = (data['listName'] ?? data['listId'] ?? "")
                .toString();

            final itemsRaw =
                data['items'] as List<dynamic>? ?? [];

            for (int i = 0; i < itemsRaw.length; i++) {
              final itemMap =
                  Map<String, dynamic>.from(itemsRaw[i] as Map);
              final order =
                  (itemMap['order'] ?? 0) as int;

              if (order <= 0) continue; // só itens em pedido

              final id = "${doc.id}::$i";
              _checked.putIfAbsent(id, () => false);

              final envioItem = _EnvioItem(
                id: id,
                finishedRef: doc.reference,
                itemIndex: i,
                listName: listName,
                category: category,
                name: itemMap['name'] ?? "",
                order: order,
              );

              byList.putIfAbsent(listName, () => []);
              byList[listName]!.add(envioItem);
            }
          }

          if (byList.isEmpty) {
            return const Center(
              child: Text(
                "Nenhum item em pedido.",
                textAlign: TextAlign.center,
              ),
            );
          }

          final listNames = byList.keys.toList()..sort();

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: listNames.length,
                  itemBuilder: (context, index) {
                    final listName = listNames[index];
                    final listItems = byList[listName]!;

                    // 👉 Verifica se TODOS os itens dessa lista estão marcados
                    final bool allChecked = listItems.isNotEmpty &&
                        listItems.every(
                          (item) => _checked[item.id] == true,
                        );

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            // 🔹 Cabeçalho com nome da lista + botão circular
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  listName,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  tooltip: "Marcar/Desmarcar todos",
                                  onPressed: () {
                                    setState(() {
                                      final newValue = !allChecked;
                                      for (final item in listItems) {
                                        _checked[item.id] = newValue;
                                      }
                                    });
                                  },
                                  icon: CircleAvatar(
                                    radius: 14,
                                    backgroundColor: allChecked
                                        ? Colors.green
                                        : Colors.grey.shade300,
                                    child: Icon(
                                      Icons.done_all,
                                      size: 18,
                                      color: allChecked
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const Divider(),

                            // 🔽 Itens dessa lista
                            ListView.builder(
                              shrinkWrap: true,
                              physics:
                                  const NeverScrollableScrollPhysics(),
                              itemCount: listItems.length,
                              itemBuilder: (context, i) {
                                final item = listItems[i];
                                final checked =
                                    _checked[item.id] ?? false;
                                final catLabel =
                                    translateCategory(
                                  item.category,
                                );

                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                      vertical: 6),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius:
                                        BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withOpacity(0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      // ⬜ Checkbox
                                      Checkbox(
                                        value: checked,
                                        onChanged: (val) {
                                          setState(() {
                                            _checked[item.id] =
                                                val ?? false;
                                          });
                                        },
                                      ),

                                      // 📝 Nome + categoria
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.name,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight:
                                                    FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              catLabel,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(width: 8),

                                      // 🔢 Quantidade
                                      Text(
                                        "Pedido: ${item.order}",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
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

              // Botão ENVIAR continua igual
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.send),
                      label: const Text(
                        "Encaminhar",
                        style: TextStyle(fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blueGrey,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AdminPedidoEnviarPage(
                              location: widget.location,
                            ),
                          ),
                        );
                      },
                    ),
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

// ============================================================================
// Modelo interno para envio
// ============================================================================
class _EnvioItem {
  final String id; // chave única para checkbox/dropdown
  final DocumentReference finishedRef;
  final int itemIndex;
  final String listName;
  final String category;
  final String name;
  final int order;

  _EnvioItem({
    required this.id,
    required this.finishedRef,
    required this.itemIndex,
    required this.listName,
    required this.category,
    required this.name,
    required this.order,
  });
}

// ============================================================================
// Página envio do pedido
// ============================================================================
class AdminPedidoEnviarPage extends StatefulWidget {
  final String location;

  const AdminPedidoEnviarPage({
    super.key,
    required this.location,
  });

  @override
  State<AdminPedidoEnviarPage> createState() =>
      _AdminPedidoEnviarPageState();
}

class _AdminPedidoEnviarPageState extends State<AdminPedidoEnviarPage> {
  // checkbox selecionado por item.id
  final Map<String, bool> _selected = {};
  // fornecedor escolhido por item.id
  final Map<String, String> _supplierById = {};

  static const List<String> _suppliers = [
    'Restaurant Depot',
    'Costco',
    'Walmart',
    'Publix',
  ];

  bool get _hasSelection =>
      _selected.values.any((v) => v == true);

  Future<void> _finalizar(List<_EnvioItem> allItems) async {
    final selectedItems = allItems
        .where((item) => _selected[item.id] == true)
        .toList();

    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Nenhum item selecionado para enviar."),
        ),
      );
      return;
    }

    final firestore = FirebaseFirestore.instance;
    final hallPedidosColl = firestore.collection('hallPedidos');

    final batch = firestore.batch();

    // gera chave de data para agrupar por dia: "YYYY-MM-DD"
    final now = DateTime.now();
    final String dateKey =
        "${now.year.toString().padLeft(4, '0')}-"
        "${now.month.toString().padLeft(2, '0')}-"
        "${now.day.toString().padLeft(2, '0')}";

    // 1) Criar docs em hallPedidos
    for (final item in selectedItems) {
      final supplier = _supplierById[item.id] ?? _suppliers.first;

      final ref = hallPedidosColl.doc();
      batch.set(ref, {
        'location': widget.location,
        // "Hall" ou "Kitchen"
        'category': item.category,
        'listName': item.listName,
        'itemName': item.name,
        'order': item.order,
        'supplier': supplier,
        'createdAt': FieldValue.serverTimestamp(),
        'dateKey': dateKey, // 👈 NOVO: chave de data textual
        'sent': false,
      });

    }

    // 2) Zerar order (e opcionalmente "checked") em finishedLists
    //    Agrupar por documento para minimizar leituras
    final Map<DocumentReference, List<_EnvioItem>> byDoc = {};
    for (final item in selectedItems) {
      byDoc.putIfAbsent(item.finishedRef, () => []).add(item);
    }

    for (final entry in byDoc.entries) {
      final docRef = entry.key;
      final docSnap = await docRef.get();
      if (!docSnap.exists) continue;

      final data = docSnap.data() as Map<String, dynamic>;
      final itemsRaw = data['items'] as List<dynamic>? ?? [];
      final items = itemsRaw
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      for (final envioItem in entry.value) {
        if (envioItem.itemIndex >= 0 &&
            envioItem.itemIndex < items.length) {
          final itemMap =
              Map<String, dynamic>.from(items[envioItem.itemIndex]);
          itemMap['order'] = 0;
          itemMap['checked'] = false; // se você usa flag de checklist
          items[envioItem.itemIndex] = itemMap;
        }
      }

      batch.update(docRef, {'items': items});
    }

    await batch.commit();

    if (!mounted) return;

    setState(() {
      _selected.clear();
      _supplierById.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Itens enviados para o Salão e removidos do pedido!"),
      ),
    );

    Navigator.pop(context); // volta para AdminPedidoPage
  }

  @override
  Widget build(BuildContext context) {
    final title =
        "Admin - ${shortLocation(widget.location)} - Enviar Pedido";

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('finishedLists')
            .where('location', isEqualTo: widget.location)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text("Erro: ${snapshot.error}"),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final docs = snapshot.data!.docs;

          // Montar lista de _EnvioItem + agrupar por listName
          final List<_EnvioItem> allItems = [];
          final Map<String, List<_EnvioItem>> byListName = {};

          for (final doc in docs) {
            final data = Map<String, dynamic>.from(doc.data() as Map);

            final category = (data['category'] ?? "").toString();
            final listName =
                (data['listName'] ?? data['listId'] ?? "").toString();

            final itemsRaw = data['items'] as List<dynamic>? ?? [];
            for (int i = 0; i < itemsRaw.length; i++) {
              final itemMap =
                  Map<String, dynamic>.from(itemsRaw[i] as Map);
              final order = (itemMap['order'] ?? 0) as int;

              if (order <= 0) continue;

              final id = "${doc.id}::$i";

              // garantir defaults sem perder o estado ao rebuildar
              _selected.putIfAbsent(id, () => false);
              _supplierById.putIfAbsent(id, () => _suppliers.first);

              final envioItem = _EnvioItem(
                id: id,
                finishedRef: doc.reference,
                itemIndex: i,
                listName: listName,
                category: category,
                name: itemMap['name'] ?? "",
                order: order,
              );

              allItems.add(envioItem);
              byListName.putIfAbsent(listName, () => []);
              byListName[listName]!.add(envioItem);
            }
          }

          if (allItems.isEmpty) {
            return const Center(
              child: Text(
                "Nenhum item em pedido para enviar.",
                textAlign: TextAlign.center,
              ),
            );
          }

          final listNames = byListName.keys.toList()..sort();

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: listNames.length,
                  itemBuilder: (context, index) {
                    final listName = listNames[index];
                    final listItems = byListName[listName]!;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              listName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Divider(),
                            ListView.builder(
                              shrinkWrap: true,
                              physics:
                                  const NeverScrollableScrollPhysics(),
                              itemCount: listItems.length,
                              itemBuilder: (context, i) {
                                final item = listItems[i];
                                final checked =
                                    _selected[item.id] ?? false;
                                final supplier =
                                    _supplierById[item.id] ??
                                        _suppliers.first;

                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(
                                          vertical: 4),
                                  child: Row(
                                    children: [
                                      // Checkbox
                                      Checkbox(
                                        value: checked,
                                        onChanged: (val) {
                                          setState(() {
                                            _selected[item.id] =
                                                val ?? false;
                                          });
                                        },
                                      ),

                                      // Nome do item + categoria
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.name,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              "${translateCategory(item.category)} • Pedido: ${item.order}",
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),

                                      // Dropdown fornecedor
                                      DropdownButton<String>(
                                        value: supplier,
                                        items: _suppliers
                                            .map(
                                              (s) =>
                                                  DropdownMenuItem(
                                                value: s,
                                                child: Text(s),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (val) {
                                          if (val == null) return;
                                          setState(() {
                                            _supplierById[item.id] =
                                                val;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
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

              // Botão FINALIZAR
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _hasSelection
                          ? () => _finalizar(allItems)
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 16),
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text(
                        "Enviar",
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
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
// ============================================================================
// Página do histórico do pedido
// ============================================================================
class AdminPedidoHistoryPage extends StatefulWidget {
  final String location;

  const AdminPedidoHistoryPage({
    super.key,
    required this.location,
  });

  @override
  State<AdminPedidoHistoryPage> createState() =>
      _AdminPedidoHistoryPageState();
}

class _AdminPedidoHistoryPageState extends State<AdminPedidoHistoryPage> {
  DateTime _selectedDate = DateTime.now();

  // formato simples: DD/MM/YYYY
  String get _formattedDate {
    final d = _selectedDate;
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    return "$dd/$mm/$yyyy";
  }

  // limites de data no Firestore (início e fim do dia)
  DateTime get _startOfDay =>
      DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);

  DateTime get _endOfDay => _startOfDay.add(const Duration(days: 1));

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final first = DateTime(now.year - 2); // 2 anos pra trás
    final last = DateTime(now.year + 1);  // 1 ano pra frente

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: first,
      lastDate: last,
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title =
        "Admin - ${shortLocation(widget.location)} - Histórico";

    // gera a mesma chave que salvamos em hallPedidos
    final String dateKey =
        "${_selectedDate.year.toString().padLeft(4, '0')}-"
        "${_selectedDate.month.toString().padLeft(2, '0')}-"
        "${_selectedDate.day.toString().padLeft(2, '0')}";

    final query = FirebaseFirestore.instance
        .collection('hallPedidos')
        .where('location', isEqualTo: widget.location)
        .where('dateKey', isEqualTo: dateKey);


    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Column(
        children: [
          // 🔹 BARRA FIXA COM O DIA SELECIONADO (NÃO ROLA JUNTO)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Pedidos enviados nesse dia:",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _formattedDate,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: const Text("Escolher dia"),
                ),
              ],
            ),
          ),

          // 🔽 LISTA ROLÁVEL DO CONTEÚDO
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text("Erro: ${snapshot.error}"),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "Nenhum pedido enviado nesse dia.",
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                // Agrupa por listName (Rest Depot, Walmart, etc)
                final Map<String, List<QueryDocumentSnapshot>> byListName = {};
                for (final d in docs) {
                  final data =
                      Map<String, dynamic>.from(d.data() as Map);
                  final listName =
                      (data['listName'] ?? 'Sem nome').toString();

                  byListName.putIfAbsent(listName, () => []);
                  byListName[listName]!.add(d);
                }

                final listNames = byListName.keys.toList()..sort();

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: listNames.length,
                  itemBuilder: (context, index) {
                    final listName = listNames[index];
                    final itemsDocs = byListName[listName]!;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              listName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Divider(),
                            ListView.builder(
                              shrinkWrap: true,
                              physics:
                                  const NeverScrollableScrollPhysics(),
                              itemCount: itemsDocs.length,
                              itemBuilder: (context, i) {
                                final d = itemsDocs[i];
                                final data =
                                    Map<String, dynamic>.from(
                                        d.data() as Map);

                                final itemName =
                                    (data['itemName'] ?? '').toString();
                                final supplier =
                                    (data['supplier'] ?? '').toString();
                                final category =
                                    (data['category'] ?? '').toString();
                                final order =
                                    (data['order'] ?? 0) as int;

                                final catLabel =
                                    translateCategory(category);

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 4),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              itemName,
                                              style:
                                                  const TextStyle(
                                                fontSize: 16,
                                                fontWeight:
                                                    FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              "$catLabel • Fornecedor: $supplier",
                                              style:
                                                  const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Qtd: $order",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
