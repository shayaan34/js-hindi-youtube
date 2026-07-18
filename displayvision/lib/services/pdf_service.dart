import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../core/app_config.dart';
import '../models/models.dart';

/// Generates and shares the client proposal PDF.
class PdfService {
  static final _currency =
      NumberFormat.currency(locale: 'en_IN', symbol: AppConfig.currencySymbol);

  static const _orange = PdfColor.fromInt(0xFFFF6A00);
  static const _dark = PdfColor.fromInt(0xFF121216);
  static const _grey = PdfColor.fromInt(0xFF71717A);

  static Future<Uint8List> buildProposal({
    required Client client,
    required List<ProposalLineItem> items,
    required List<Uint8List> mockupImages,
    String preparedBy = 'Sales Team',
  }) async {
    final doc = pw.Document();
    final subtotal = items.fold<double>(0, (sum, i) => sum + i.total);
    final gst = subtotal * AppConfig.gstRate;
    final total = subtotal + gst;
    final date = DateFormat('dd MMM yyyy').format(DateTime.now());

    pw.Widget header() => pw.Container(
          padding: const pw.EdgeInsets.all(24),
          color: _dark,
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(children: [
                    pw.Container(
                      width: 26,
                      height: 26,
                      decoration: pw.BoxDecoration(
                        color: _orange,
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      alignment: pw.Alignment.center,
                      child: pw.Text('DV',
                          style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Text('DisplayVision',
                        style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold)),
                  ]),
                  pw.SizedBox(height: 4),
                  pw.Text(AppConfig.companyName,
                      style: const pw.TextStyle(color: _grey, fontSize: 9)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('DIGITAL SIGNAGE PROPOSAL',
                      style: pw.TextStyle(
                          color: _orange,
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text('Date: $date',
                      style: const pw.TextStyle(color: _grey, fontSize: 9)),
                ],
              ),
            ],
          ),
        );

    pw.Widget clientBlock() => pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('PREPARED FOR',
                      style: pw.TextStyle(
                          fontSize: 8,
                          color: _grey,
                          fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text(client.businessName,
                      style: pw.TextStyle(
                          fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.Text('${client.contactPerson}  •  ${client.phone}',
                      style: const pw.TextStyle(fontSize: 9)),
                  pw.Text(client.email, style: const pw.TextStyle(fontSize: 9)),
                  pw.SizedBox(height: 2),
                  pw.Text(client.address,
                      style: const pw.TextStyle(fontSize: 9, color: _grey)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('CATEGORY',
                      style: pw.TextStyle(
                          fontSize: 8,
                          color: _grey,
                          fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text(client.category.label,
                      style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ],
          ),
        );

    pw.Widget itemsTable() => pw.TableHelper.fromTextArray(
          headers: [
            'Item', 'Dimensions', 'Location', 'Qty', 'Unit Price', 'Total'
          ],
          data: items
              .map((i) => [
                    i.description,
                    i.dimensions,
                    i.location,
                    '${i.quantity}',
                    _currency.format(i.unitPrice),
                    _currency.format(i.total),
                  ])
              .toList(),
          headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 9,
              fontWeight: pw.FontWeight.bold),
          headerDecoration: const pw.BoxDecoration(color: _dark),
          cellStyle: const pw.TextStyle(fontSize: 9),
          cellAlignments: {
            3: pw.Alignment.center,
            4: pw.Alignment.centerRight,
            5: pw.Alignment.centerRight,
          },
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
        );

    pw.Widget totals() => pw.Container(
          alignment: pw.Alignment.centerRight,
          child: pw.SizedBox(
            width: 220,
            child: pw.Column(children: [
              _totalRow('Subtotal', _currency.format(subtotal)),
              _totalRow(
                  'GST (${(AppConfig.gstRate * 100).toStringAsFixed(0)}%)',
                  _currency.format(gst)),
              pw.Divider(color: PdfColors.grey400),
              _totalRow('Grand Total', _currency.format(total), bold: true),
            ]),
          ),
        );

    pw.Widget signatures() => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _signatureBox('Prepared by\n$preparedBy'),
            _signatureBox('Client acceptance\n${client.contactPerson}'),
          ],
        );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (context) => [
          header(),
          pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                clientBlock(),
                pw.SizedBox(height: 16),
                if (mockupImages.isNotEmpty) ...[
                  pw.Text('Proposed Mockups',
                      style: pw.TextStyle(
                          fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 8),
                  pw.Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: mockupImages
                        .take(4)
                        .map((bytes) => pw.Container(
                              width: 250,
                              height: 150,
                              decoration: pw.BoxDecoration(
                                borderRadius: pw.BorderRadius.circular(6),
                                image: pw.DecorationImage(
                                  image: pw.MemoryImage(bytes),
                                  fit: pw.BoxFit.cover,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                  pw.SizedBox(height: 16),
                ],
                pw.Text('Scope & Pricing',
                    style: pw.TextStyle(
                        fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                itemsTable(),
                pw.SizedBox(height: 12),
                totals(),
                pw.SizedBox(height: 32),
                signatures(),
              ],
            ),
          ),
        ],
        footer: (context) => pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(AppConfig.companyName,
                  style: const pw.TextStyle(fontSize: 8, color: _grey)),
              pw.Text('Page ${context.pageNumber} of ${context.pagesCount}',
                  style: const pw.TextStyle(fontSize: 8, color: _grey)),
            ],
          ),
        ),
      ),
    );

    return doc.save();
  }

  static pw.Widget _totalRow(String label, String value, {bool bold = false}) {
    final style = pw.TextStyle(
        fontSize: bold ? 11 : 9,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        color: bold ? _orange : PdfColors.black);
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [pw.Text(label, style: style), pw.Text(value, style: style)],
      ),
    );
  }

  static pw.Widget _signatureBox(String label) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(width: 180, height: 1, color: PdfColors.grey600),
          pw.SizedBox(height: 4),
          pw.Text(label,
              style: const pw.TextStyle(fontSize: 8, color: _grey)),
        ],
      );

  /// Opens the platform share/print sheet for the PDF.
  static Future<void> sharePdf(Uint8List bytes, String filename) =>
      Printing.sharePdf(bytes: bytes, filename: filename);
}
