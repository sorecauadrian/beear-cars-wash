import 'dart:io';
import 'package:flutter/services.dart';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../../data/models/service_record_model.dart';
import '../../../../features/companies/data/models/company_model.dart';
import '../../../../features/bookings/data/models/booking_model.dart';
import '../../../../features/vehicles/data/models/vehicle_model.dart';
import '../../../../features/pricing/data/models/pricing_model.dart';

/// Service for exporting service records to Excel and PDF
class ExportService {
  static double _getBookingPrice(BookingModel booking, Map<String, VehicleModel> vehicles, PricingModel? pricing) {
    if (pricing == null) return 0.0;
    final vehicle = vehicles[booking.vehicleId];
    final vehicleType = vehicle?.vehicleType ?? VehicleType.small;
    return pricing.getPrice(vehicleType, booking.washType);
  }

  /// Export single service record with booking details to Excel
  static Future<void> exportRecordToExcel(
    ServiceRecordModel record,
    CompanyModel? company,
    List<BookingModel> bookings,
    Map<String, VehicleModel> vehicles,
    PricingModel? pricing,
  ) async {
    try {
      final excel = Excel.createExcel();
      if (excel.sheets.keys.contains('Sheet1')) {
        excel.delete('Sheet1');
      }
      final sheet = excel['Registre Servicii'];

      final monthDate = _parseMonth(record.month);
      final companyName = company?.name ?? 'Companie necunoscută';
      final monthName = DateFormat('MMMM yyyy', 'ro_RO').format(monthDate);

      final summaryHeaders = [
        'Companie',
        'Lună',
        'Interior',
        'Exterior',
        'Interior + Exterior',
        'Total Servicii',
      ];
      
      for (var i = 0; i < summaryHeaders.length; i++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(summaryHeaders[i]);
        cell.cellStyle = CellStyle(bold: true);
      }

      final summaryData = [
        companyName,
        monthName,
        record.interiorWashes,
        record.exteriorWashes,
        record.completeWashes,
        record.totalServices,
      ];
      
      for (var i = 0; i < summaryData.length; i++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1));
        if (summaryData[i] is int) {
          cell.value = IntCellValue(summaryData[i] as int);
        } else {
          cell.value = TextCellValue(summaryData[i].toString());
        }
      }

      int rowIndex = 3;

      final bookingHeaders = [
        'Data',
        'Ora',
        'Număr Înmatriculare',
        'Tip Vehicul',
        'Tip Serviciu',
        'Preț',
        'Locație',
        'Note',
      ];
      
      for (var i = 0; i < bookingHeaders.length; i++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: rowIndex));
        cell.value = TextCellValue(bookingHeaders[i]);
        cell.cellStyle = CellStyle(bold: true);
      }
      rowIndex++;

      double totalAmount = 0.0;
      for (var booking in bookings) {
        final bookingDate = DateTime.parse(booking.date);
        final vehicle = vehicles[booking.vehicleId];
        final price = _getBookingPrice(booking, vehicles, pricing);
        totalAmount += price;
        
        final rowData = [
          DateFormat('dd.MM.yyyy', 'ro_RO').format(bookingDate),
          '${booking.slotStart} - ${booking.slotEnd}',
          vehicle?.plateNumber ?? 'Necunoscut',
          vehicle?.vehicleType.label ?? '-',
          _getWashTypeLabel(booking.washType),
          price > 0 ? '${price.toStringAsFixed(2)} RON' : '-',
          booking.addressText,
          booking.description ?? '',
        ];
        
        for (var i = 0; i < rowData.length; i++) {
          final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: rowIndex));
          cell.value = TextCellValue(rowData[i]);
        }
        rowIndex++;
      }

      rowIndex++;
      final totalRow = [
        'TOTAL',
        '',
        '',
        '',
        '',
        '${totalAmount.toStringAsFixed(2)} RON',
        '',
        '',
      ];
      for (var i = 0; i < totalRow.length; i++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: rowIndex));
        cell.value = TextCellValue(totalRow[i]);
        cell.cellStyle = CellStyle(bold: true);
      }

      for (var i = 0; i < 8; i++) {
        sheet.setColumnWidth(i, 20);
      }

      if (excel.sheets.keys.contains('Sheet1')) {
        excel.delete('Sheet1');
      }

      final directory = await getApplicationDocumentsDirectory();
      final safeCompanyName = companyName.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
      final fileName = 'Registru_${safeCompanyName}_${record.month}.xlsx';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(excel.encode()!);

      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Registru Servicii - $companyName - $monthName',
        text: 'Registru servicii pentru $companyName - $monthName',
      );
    } catch (e) {
      throw Exception('Eroare la exportul Excel: ${e.toString()}');
    }
  }

  /// Export single service record with booking details to PDF
  static Future<void> exportRecordToPDF(
    ServiceRecordModel record,
    CompanyModel? company,
    List<BookingModel> bookings,
    Map<String, VehicleModel> vehicles,
    PricingModel? pricing,
  ) async {
    try {
      final pdf = pw.Document();
      final monthDate = _parseMonth(record.month);
      final companyName = company?.name ?? 'Companie necunoscută';
      final monthName = DateFormat('MMMM yyyy', 'ro_RO').format(monthDate);
      
      pw.MemoryImage? logoImage;
      try {
        final ByteData logoData = await rootBundle.load('assets/images/beear-cars-wash-no-text.png');
        final Uint8List logoBytes = logoData.buffer.asUint8List();
        logoImage = pw.MemoryImage(logoBytes);
      } catch (e) {
        logoImage = null;
      }

      pw.Font? customFont;
      try {
        final fontData = await rootBundle.load('assets/fonts/NotoSans.ttf');
        customFont = pw.Font.ttf(fontData);
      } catch (e) {
        customFont = null;
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          theme: customFont != null ? pw.ThemeData.withFont(base: customFont) : null,
          build: (pw.Context context) {
            pw.TextStyle textStyle({
              double? fontSize,
              pw.FontWeight? fontWeight,
              PdfColor? color,
            }) {
              return pw.TextStyle(
                fontSize: fontSize,
                fontWeight: fontWeight,
                color: color,
                font: customFont,
              );
            }

            double totalAmount = 0.0;
            final serviceTotals = <WashType, double>{
              WashType.interior: 0.0,
              WashType.exterior: 0.0,
              WashType.all: 0.0,
            };
            
            for (var booking in bookings) {
              final price = _getBookingPrice(booking, vehicles, pricing);
              totalAmount += price;
              serviceTotals[booking.washType] = serviceTotals[booking.washType]! + price;
            }
            return [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        children: [
                          if (logoImage != null) ...[
                            pw.Image(logoImage, width: 60, height: 60),
                            pw.SizedBox(width: 12),
                          ],
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'Beear Cars Wash',
                                style: textStyle(
                                  fontSize: 20,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColor.fromHex('#E93A1F'),
                                ),
                              ),
                              pw.Text(
                                'Registru Servicii',
                                style: textStyle(
                                  fontSize: 14,
                                  color: PdfColors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Generat: ${DateFormat('dd.MM.yyyy', 'ro_RO').format(DateTime.now())}',
                        style: textStyle(fontSize: 10, color: PdfColors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColor(233 / 255, 58 / 255, 31 / 255, 0.1),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Row(
                  children: [
                    pw.Text(
                      'Client: ',
                      style: textStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      '$companyName - $monthName',
                      style: textStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  border: pw.Border.all(color: PdfColors.grey),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Rezumat',
                      style: textStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Interior: ${record.interiorWashes} servicii = ${serviceTotals[WashType.interior]!.toStringAsFixed(2)} RON',
                          style: textStyle(),
                        ),
                        pw.Text(
                          'Exterior: ${record.exteriorWashes} servicii = ${serviceTotals[WashType.exterior]!.toStringAsFixed(2)} RON',
                          style: textStyle(),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Int + Ext: ${record.completeWashes} servicii = ${serviceTotals[WashType.all]!.toStringAsFixed(2)} RON',
                      style: textStyle(),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Divider(),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Total servicii: ${record.totalServices}',
                          style: textStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          'Total sumă: ${totalAmount.toStringAsFixed(2)} RON',
                          style: textStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromHex('#E93A1F'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              pw.Text(
                'Detalii servicii',
                style: textStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey200,
                    ),
                    children: [
                      _buildTableCell('Data', isHeader: true, customFont: customFont),
                      _buildTableCell('Ora', isHeader: true, customFont: customFont),
                      _buildTableCell('Nr. Înmatriculare', isHeader: true, customFont: customFont),
                      _buildTableCell('Tip Vehicul', isHeader: true, customFont: customFont),
                      _buildTableCell('Tip Serviciu', isHeader: true, customFont: customFont),
                      _buildTableCell('Preț', isHeader: true, customFont: customFont),
                      _buildTableCell('Locație', isHeader: true, customFont: customFont),
                    ],
                  ),
                  ...bookings.map((booking) {
                    final bookingDate = DateTime.parse(booking.date);
                    final vehicle = vehicles[booking.vehicleId];
                    final price = _getBookingPrice(booking, vehicles, pricing);
                    return pw.TableRow(
                      children: [
                        _buildTableCell(
                          DateFormat('dd.MM.yyyy', 'ro_RO').format(bookingDate),
                          customFont: customFont,
                        ),
                        _buildTableCell('${booking.slotStart} - ${booking.slotEnd}', customFont: customFont),
                        _buildTableCell(vehicle?.plateNumber ?? 'Necunoscut', customFont: customFont),
                        _buildTableCell(vehicle?.vehicleType.label ?? '-', customFont: customFont),
                        _buildTableCell(_getWashTypeLabel(booking.washType), customFont: customFont),
                        _buildTableCell(price > 0 ? '${price.toStringAsFixed(2)} RON' : '-', customFont: customFont),
                        _buildTableCell(booking.addressText, customFont: customFont),
                      ],
                    );
                  }),
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: [
                      _buildTableCell('TOTAL', isHeader: true, customFont: customFont),
                      _buildTableCell('', isHeader: true, customFont: customFont),
                      _buildTableCell('', isHeader: true, customFont: customFont),
                      _buildTableCell('', isHeader: true, customFont: customFont),
                      _buildTableCell('', isHeader: true, customFont: customFont),
                      _buildTableCell('${totalAmount.toStringAsFixed(2)} RON', isHeader: true, customFont: customFont),
                      _buildTableCell('', isHeader: true, customFont: customFont),
                    ],
                  ),
                ],
              ),

              if (bookings.any((b) => b.description != null && b.description!.isNotEmpty)) ...[
                pw.SizedBox(height: 20),
                pw.Text(
                  'Note',
                  style: textStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                ...bookings
                    .where((b) => b.description != null && b.description!.isNotEmpty)
                    .map((booking) {
                  final bookingDate = DateTime.parse(booking.date);
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 8),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          '${DateFormat('dd.MM.yyyy', 'ro_RO').format(bookingDate)}:',
                          style: textStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          booking.description!,
                          style: textStyle(),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ];
          },
        ),
      );

      final directory = await getApplicationDocumentsDirectory();
      final safeCompanyName = companyName.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
      final fileName = 'Registru_${safeCompanyName}_${record.month}.pdf';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Registru Servicii - $companyName - $monthName',
        text: 'Registru servicii pentru $companyName - $monthName',
      );
    } catch (e) {
      throw Exception('Eroare la exportul PDF: ${e.toString()}');
    }
  }

  static pw.Widget _buildTableCell(String text, {bool isHeader = false, pw.Font? customFont}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          font: customFont,
        ),
      ),
    );
  }

  static DateTime _parseMonth(String month) {
    final parts = month.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]));
  }

  static String _getWashTypeLabel(WashType type) {
    switch (type) {
      case WashType.interior:
        return 'Spălare Interior';
      case WashType.exterior:
        return 'Spălare Exterior';
      case WashType.all:
        return 'Spălare Interior + Exterior';
    }
  }
}
