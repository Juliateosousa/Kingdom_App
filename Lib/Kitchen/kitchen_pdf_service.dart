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
    required String orderField,
  }) async {
    final pdf = pw.Document();
    final firestore = FirebaseFirestore.instance;

    final List<pw.Widget> content = [];

    content.add(
      pw.Text(
        location,
        style: pw.TextStyle(
          fontSize: 18,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
    content.add(pw.SizedBox(height: 10));

    for (int i = 0; i < listIds.length; i++) {
      final listId = listIds[i];
      final listName = listNames[i];

      final listRef =
          firestore.collection('lists').doc(listId).collection('items');

      final snap = await listRef.orderBy('name').get();
      if (snap.docs.isEmpty) {
        continue;
      }

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

      final List<pw.TableRow> rows = [];

      final headerStyle = pw.TextStyle(
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
      );

      rows.add(
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: PdfColor.fromInt(0xBA5000),
          ),
          children: [
            _cell('Item', headerStyle),
            _cell('Estoque Atual', headerStyle, alignCenter: true),
            _cell('Estoque Mínimo', headerStyle, alignCenter: true),
          ],
        ),
      );

      for (final doc in snap.docs) {
        final data = doc.data();

        final String name = data['name']?.toString() ?? '';

        final num valueNum =
            (data[valueField] ?? data['value'] ?? 0) as num;
        final num minNum =
            (data[minField] ?? data['minStock'] ?? 0) as num;

        final bool isZeroX = (data['isZeroX'] ?? false) as bool;

        PdfColor? bgColor;
        PdfColor textColor = PdfColors.black;
        String qtyText = valueNum.toStringAsFixed(1);

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
              _cell(qtyText, rowTextStyle, alignCenter: true, bgColor: PdfColor.fromInt(0xE06666)),
              _cell(minNum.toString(), rowTextStyle, alignCenter: true, bgColor: PdfColor.fromInt(0xFF6D9EEB)),
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
            1: pw.FlexColumnWidth(1), // Estoque Atual
            2: pw.FlexColumnWidth(1), // Estoque Mínimo
          },
          children: rows,
        ),
      );

      content.add(pw.SizedBox(height: 12));
    }

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

  static pw.Widget _cell(
    String text,
    pw.TextStyle style, {
    bool alignCenter = false,
    PdfColor? bgColor,
  }) {
    return pw.Container(
      color: bgColor,
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
