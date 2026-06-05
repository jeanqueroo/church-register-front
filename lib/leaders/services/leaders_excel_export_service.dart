import 'dart:io';

import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/church_leader.dart';

class LeadersExcelExportService {
  Future<void> shareLeaders(List<ChurchLeader> leaders) async {
    if (leaders.isEmpty) {
      throw LeadersExcelExportException('No hay líderes para exportar');
    }

    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet();
    if (defaultSheet != null) {
      excel.delete(defaultSheet);
    }

    const sheetName = 'Líderes';
    final sheet = excel[sheetName];
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    sheet.appendRow(_headers.map(TextCellValue.new).toList());

    for (final leader in leaders) {
      sheet.appendRow([
        TextCellValue(leader.lastName),
        TextCellValue(leader.firstName),
        TextCellValue(leader.churchOffice?.label ?? ''),
        TextCellValue(leader.gender?.label ?? ''),
        TextCellValue(leader.cellCode ?? ''),
        TextCellValue(leader.mobilePhone),
        TextCellValue(leader.email ?? ''),
        TextCellValue(leader.street ?? ''),
        TextCellValue(leader.streetNumber ?? ''),
        TextCellValue(leader.neighborhood ?? ''),
        TextCellValue(leader.locality ?? ''),
        TextCellValue(leader.stateProvince ?? ''),
        TextCellValue(leader.postalCode ?? ''),
        TextCellValue(leader.formattedAddress),
        TextCellValue(dateFormat.format(leader.registeredAt)),
      ]);
    }

    final bytes = excel.save();
    if (bytes == null) {
      throw LeadersExcelExportException('No se pudo generar el archivo Excel');
    }

    final dir = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${dir.path}/lideres_$timestamp.xlsx');
    await file.writeAsBytes(bytes);

    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(
            file.path,
            mimeType:
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            name: 'lideres_$timestamp.xlsx',
          ),
        ],
        subject: 'Líderes registrados',
        text: 'Listado de ${leaders.length} líder(es)',
      ),
    );
  }

  static const _headers = [
    'Apellido',
    'Nombre',
    'Cargo',
    'Género',
    'Célula',
    'Teléfono móvil',
    'Correo',
    'Calle',
    'Número',
    'Colonia',
    'Localidad',
    'Estado',
    'C.P.',
    'Dirección completa',
    'Fecha de registro',
  ];
}

class LeadersExcelExportException implements Exception {
  LeadersExcelExportException(this.message);

  final String message;

  @override
  String toString() => message;
}
