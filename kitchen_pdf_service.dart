import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class KitchenPdfService {
  static Future<Uint8List> generateKitchenPdf({
    required String location,
    required List<String> listIds,
    required List<String> listNames,
    required String valueField,
    required String minField,
    required String orderField, // ainda recebido, mas não usado
  }) async {
    final pdf = pw.Document();
    final firestore = FirebaseFirestore.instance;

    final List<pw.Widget> content = [];

    // Título geral: só a localização no topo
    content.add(
      pw.Text(
        location, // ex: "Kingdom Boca Raton"
        style: pw.TextStyle(
          fontSize: 18,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
    content.add(pw.SizedBox(height: 10));

    // Para cada lista/categoria da cozinha
    for (int i = 0; i < listIds.length; i++) {
      final listId = listIds[i];
      final listName = listNames[i];

      final listRef =
          firestore.collection('lists').doc(listId).collection('items');

      final snap = await listRef.orderBy('name').get();
      if (snap.docs.isEmpty) {
        continue;
      }

      // Cabeçalho da categoria
      content.add(
        pw.Text(
          listName,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      );
      content.add(pw.SizedBox(height: 4));

      // Montar linhas da tabela
      final List<pw.TableRow> rows = [];

      // Linha de cabeçalho da tabela
      final headerStyle = pw.TextStyle(
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
      );

      rows.add(
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: PdfColors.grey300,
          ),
          children: [
            _cell('Item', headerStyle),
            _cell('Current Stock', headerStyle, alignCenter: true),
            _cell('Minimum Stock', headerStyle, alignCenter: true),
          ],
        ),
      );

      // Linhas de itens
      for (final doc in snap.docs) {
        final data = doc.data();

        final String name = data['name']?.toString() ?? '';

        final num valueNum =
            (data[valueField] ?? data['value'] ?? 0) as num;
        final num minNum =
            (data[minField] ?? data['minStock'] ?? 0) as num;

        // final bool isUrgent = (data['isUrgent'] ?? false) as bool;
        final bool isZeroX = (data['isZeroX'] ?? false) as bool;

        // Regras:
        // - se X => linha cinza, QTY = '---'
        // - (sem urgente aqui, igual ao Hall atual que você mandou)
        PdfColor? bgColor;
        PdfColor textColor = PdfColors.black;
        String qtyText = valueNum.toStringAsFixed(1);
        String minText = minNum.toStringAsFixed(1);

        if (isZeroX) {
          bgColor = PdfColors.grey300;
          qtyText = '----';
        }

        final rowTextStyle = pw.TextStyle(
          fontSize: 10,
          color: textColor,
        );

        rows.add(
          pw.TableRow(
            decoration:
                bgColor != null ? pw.BoxDecoration(color: bgColor) : null,
            children: [
              _cell(name, rowTextStyle),
              _cell(qtyText, rowTextStyle, alignCenter: true),
              _cell(minText, rowTextStyle, alignCenter: true),
            ],
          ),
        );
      }

      content.add(
        pw.Table(
          border: pw.TableBorder.all(width: 0.3, color: PdfColors.grey600),
          defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
          columnWidths: {
            0: pw.FlexColumnWidth(3), // Item
            1: pw.FlexColumnWidth(1), // QTY
            2: pw.FlexColumnWidth(1), // Min
          },
          children: rows,
        ),
      );

      content.add(pw.SizedBox(height: 12));
    }

    // Se nada foi adicionado (nenhuma lista com itens)
    if (content.length <= 3) {
      content.add(
        pw.Text(
          'No items to show.',
          style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
        ),
      );
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) => content,
      ),
    );

    return pdf.save();
  }

  // Helper para criar células com padding e alinhamento
  static pw.Widget _cell(
    String text,
    pw.TextStyle style, {
    bool alignCenter = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: pw.Align(
        alignment:
            alignCenter ? pw.Alignment.center : pw.Alignment.centerLeft,
        child: pw.Text(
          text,
          style: style,
          maxLines: 2,
          overflow: pw.TextOverflow.clip,
        ),
      ),
    );
  }
}
