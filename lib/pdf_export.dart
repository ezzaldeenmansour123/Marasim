import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

/// Exports Arabic (RTL, Amiri font) text as a PDF and opens the share sheet.
/// v1 exports PDF only — DOCX export is deferred (see README).
Future<void> sharePdf(String fileName, String title, String body) async {
  final regular =
      pw.Font.ttf(await rootBundle.load('assets/fonts/Amiri-Regular.ttf'));
  final bold =
      pw.Font.ttf(await rootBundle.load('assets/fonts/Amiri-Bold.ttf'));
  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      theme: pw.ThemeData.withFont(base: regular, bold: bold),
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      header: (ctx) => pw.Directionality(
        textDirection: pw.TextDirection.rtl,
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('مراسم | MARASIM',
                style: pw.TextStyle(font: bold, fontSize: 12, color: PdfColors.grey700)),
            pw.Text('منصة البروتوكول الدولي',
                style: pw.TextStyle(font: regular, fontSize: 10, color: PdfColors.grey700)),
          ],
        ),
      ),
      footer: (ctx) => pw.Center(
        child: pw.Text('أُعدّ بواسطة تطبيق مراسم — ${DateTime.now().year}',
            style: pw.TextStyle(font: regular, fontSize: 9, color: PdfColors.grey600)),
      ),
      build: (ctx) => [
        pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(title,
                  style: pw.TextStyle(font: bold, fontSize: 20)),
              pw.SizedBox(height: 6),
              pw.Divider(color: PdfColors.amber800, thickness: 2),
              pw.SizedBox(height: 12),
              pw.Text(body,
                  style: pw.TextStyle(font: regular, fontSize: 13, lineSpacing: 6)),
            ],
          ),
        ),
      ],
    ),
  );
  final dir = await getTemporaryDirectory();
  final safeName = fileName.replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_');
  final file = File('${dir.path}/$safeName');
  await file.writeAsBytes(await doc.save());
  await Share.shareXFiles([XFile(file.path)], text: title);
}
