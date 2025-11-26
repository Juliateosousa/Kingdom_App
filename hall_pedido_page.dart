import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'login_page.dart';

/// Converte a categoria em texto amigável
String translateCategory(String category) {
  switch (category) {
    case 'Hall':
      return 'Salão';
    case 'Kitchen':
      return 'Cozinha';
    default:
      return category;
  }
}

class HallPedidoPage extends StatelessWidget {
  final String location;

  const HallPedidoPage({
    super.key,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    final String shortLoc;
    if (location == "Kingdom Fort Lauderdale") {
      shortLoc = "KFL";
    } else if (location == "Kingdom Port St. Lucie") {
      shortLoc = "KPL";
    } else {
      // padrão: Kingdom Boca Raton
      shortLoc = "KBR";
    }
    // Lê os pedidos enviados pelo Admin para esta unidade
    final pedidosQuery = FirebaseFirestore.instance
        .collection('hallPedidos')
        .where('location', isEqualTo: location);
    // sem orderBy para evitar problemas de índice

    // 🔹 FUNÇÃO: limpar todos os "checked == true" desta unidade
    Future<void> cleanChecked() async {
      try {
        final snapshot = await pedidosQuery
            .where('checked', isEqualTo: true)
            .get();

        if (snapshot.docs.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Não há itens marcados para limpar.')),
          );
          return;
        }

        final batch = FirebaseFirestore.instance.batch();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }

        await batch.commit();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Itens marcados limpos com sucesso!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao limpar itens: $e')),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
  title: Text("Salão - Pedidos - $shortLoc"),
  actions: [
    TextButton(
      onPressed: cleanChecked,
      child: const Text(
        "Clean Checked",
        style: TextStyle(
          color: Colors.red,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    ),

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

      body: StreamBuilder<QuerySnapshot>(
        stream: pedidosQuery.snapshots(),
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
                "Nenhum pedido recebido do Admin ainda.",
                textAlign: TextAlign.center,
              ),
            );
          }

          // Agrupa por fornecedor (supplier)
          final Map<String, List<QueryDocumentSnapshot>> docsBySupplier = {};

          for (final doc in docs) {
            final data = Map<String, dynamic>.from(doc.data() as Map);
            final supplier =
                (data['supplier'] ?? 'Sem fornecedor').toString();
            docsBySupplier.putIfAbsent(supplier, () => []);
            docsBySupplier[supplier]!.add(doc);
          }

          final suppliers = docsBySupplier.keys.toList()..sort();

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: suppliers.length,
            itemBuilder: (context, index) {
              final supplier = suppliers[index];
              final supplierDocs = docsBySupplier[supplier]!;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cabeçalho: nome do fornecedor
                      Text(
                        supplier,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),

                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: supplierDocs.length,
                        itemBuilder: (context, i) {
                          final doc = supplierDocs[i];
                          final data =
                              Map<String, dynamic>.from(doc.data() as Map);

                          final itemName =
                              (data['itemName'] ?? '').toString();
                          final order =
                              (data['order'] ?? 0) as int;
                          final categoryRaw =
                              (data['category'] ?? '').toString();
                          final categoryText =
                              translateCategory(categoryRaw);
                          final checked =
                              (data['checked'] ?? false) as bool;

                          return Row(
                            children: [
                              // ✅ Checkbox à esquerda
                              Checkbox(
                                value: checked,
                                onChanged: (value) async {
                                  final newChecked = value ?? false;
                                  await doc.reference.update({
                                    'checked': newChecked,
                                  });
                                },
                              ),

                              // Nome + categoria no meio
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      itemName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      categoryText,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Quantidade (pedido) à direita
                              Padding(
                                padding:
                                    const EdgeInsets.only(left: 8.0),
                                child: Text(
                                  "Pedido: $order",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
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
    );
  }
}
