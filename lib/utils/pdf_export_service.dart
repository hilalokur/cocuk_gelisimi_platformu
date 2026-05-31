import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PdfExportService {
  static Future<void> exportGrowthRecords({
    required String childName,
    required List<QueryDocumentSnapshot> records,
  }) async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.nunitoRegular();
    final fontBold = await PdfGoogleFonts.nunitoBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Minik Adimlar - Gelisim Raporu',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 24,
                      color: PdfColors.brown,
                    ),
                  ),
                  pw.Text(
                    DateFormat('dd.MM.yyyy').format(DateTime.now()),
                    style: pw.TextStyle(font: font, fontSize: 12),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Cocuk: $childName',
              style: pw.TextStyle(font: fontBold, fontSize: 18),
            ),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headers: ['Tarih', 'Boy (cm)', 'Kilo (kg)', 'Bas (cm)'],
              data: records.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final date = (data['date'] as Timestamp).toDate();
                return [
                  DateFormat('dd.MM.yyyy').format(date),
                  data['height'].toString(),
                  data['weight'].toString(),
                  data['head'].toString(),
                ];
              }).toList(),
              headerStyle: pw.TextStyle(font: fontBold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.brown),
              cellStyle: pw.TextStyle(font: font),
              cellAlignment: pw.Alignment.center,
            ),
          ];
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File(
      "${output.path}/gelisim_raporu_${childName.toLowerCase()}.pdf",
    );
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles([
      XFile(file.path),
    ], text: '$childName Gelisim Raporu');
  }

  static Future<void> exportJournal({
    required String childName,
    required List<QueryDocumentSnapshot> entries,
  }) async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.nunitoRegular();
    final fontBold = await PdfGoogleFonts.nunitoBold();

    // Pre-load images before building the PDF structure
    final List<Map<String, dynamic>> processedEntries = await Future.wait(
      entries.map((doc) async {
        final data = doc.data() as Map<String, dynamic>;
        final imageUrl = data['imageUrl'] as String?;
        pw.ImageProvider? netImage;

        if (imageUrl != null && imageUrl.isNotEmpty) {
          try {
            netImage = await networkImage(imageUrl);
          } catch (e) {
            debugPrint('Error loading image for PDF: $e');
          }
        }

        return {
          'date': (data['date'] as Timestamp).toDate(),
          'authorName': data['authorName'],
          'note': data['note'],
          'image': netImage,
        };
      }),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text(
                'Minik Adimlar - Gunluk Anilar',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 24,
                  color: PdfColors.brown,
                ),
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'Cocuk: $childName',
              style: pw.TextStyle(font: fontBold, fontSize: 18),
            ),
            pw.SizedBox(height: 20),
            ...processedEntries.map((entry) {
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 15),
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(10),
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          DateFormat(
                            'dd MMMM yyyy HH:mm',
                          ).format(entry['date']),
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 12,
                            color: PdfColors.brown700,
                          ),
                        ),
                        if (entry['authorName'] != null)
                          pw.Text(
                            'Ekleyen: ${entry['authorName']}',
                            style: pw.TextStyle(
                              font: font,
                              fontSize: 10,
                              color: PdfColors.grey700,
                            ),
                          ),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    if (entry['image'] != null)
                      pw.Container(
                        height: 150,
                        width: double.infinity,
                        margin: const pw.EdgeInsets.only(bottom: 10),
                        child: pw.Image(
                          entry['image'] as pw.ImageProvider,
                          fit: pw.BoxFit.cover,
                        ),
                      ),
                    pw.Text(
                      entry['note'] ?? '',
                      style: pw.TextStyle(font: font, fontSize: 13),
                    ),
                  ],
                ),
              );
            }),
          ];
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/gunluk_${childName.toLowerCase()}.pdf");
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles([
      XFile(file.path),
    ], text: '$childName Gunluk Anilar');
  }
}
