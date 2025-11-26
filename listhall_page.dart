import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ListHallPage extends StatelessWidget {
  final String listId;      // "list1", "list2", ...
  final String? listName;   // pretty name, pode ser null

  const ListHallPage({
    super.key,
    required this.listId,
    this.listName,
  });

  @override
  Widget build(BuildContext context) {
    final listRef = FirebaseFirestore.instance
        .collection('lists')
        .doc(listId)
        .collection('items');

    void addItem() {
      final nameController = TextEditingController();

      showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text("Add Item"),
            content: TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Name"),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  if (name.isNotEmpty) {
                    listRef.add({
                      "name": name,
                      "value": 0, // always starts at 0
                    });
                  }
                  Navigator.pop(ctx);
                },
                child: const Text("Add"),
              ),
            ],
          );
        },
      );
    }

    /// 👉 FINALIZAR: manda essa lista para o admin
    Future<void> finalizeList() async {
      try {
        // pega os itens atuais dessa lista
        final snap = await listRef.get();
        final items = snap.docs.map((doc) {
        final Map<String, dynamic> data =
        Map<String, dynamic>.from(doc.data() as Map);

          return {
            "name": data["name"],
            "value": data["value"],
          };
        }).toList();

        // se não tiver itens, pode mandar mesmo assim ou avisar
        if (items.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Lista vazia, nada para finalizar.")),
          );
          return;
        }

        final titleText = listName ?? "List: $listId";

        await FirebaseFirestore.instance
            .collection('finishedLists')
            .add({
          "listId": listId,
          "listName": titleText,
          "items": items,
          "createdAt": FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lista '$titleText' enviada para o admin!")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao finalizar lista: $e")),
        );
      }
    }

    final titleText = listName ?? "List: $listId";

    return Scaffold(
      appBar: AppBar(
        title: Text(titleText),
        actions: [
          // 👇 botão FINALIZAR
          TextButton(
            onPressed: finalizeList,
            child: const Text(
              "Finalizar",
              style: TextStyle(color: Colors.white),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: addItem, // add item with value 0
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: listRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text("Error: ${snapshot.error}"),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data!.docs;

          if (items.isEmpty) {
            return const Center(child: Text("No items. Add one!"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final data = item.data() as Map<String, dynamic>;
              final name = data['name'];
              final value = data['value'];

              return Card(
                child: ListTile(
                  title: Text(name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          if (value > 0) {
                            item.reference.update({"value": value - 1});
                          }
                        },
                      ),
                      Text(
                        value.toString(),
                        style: const TextStyle(fontSize: 18),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          item.reference.update({"value": value + 1});
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
