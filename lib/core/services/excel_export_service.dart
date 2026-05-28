import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../leaders/models/church_leader.dart';
import '../../members/models/church_member.dart';

class ExcelExportService {
  ExcelExportService._();

  static final ExcelExportService instance = ExcelExportService._();

  static String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  static String _yesNo(bool value) => value ? 'Sí' : 'No';

  Future<void> shareMembersExcel({
    required List<ChurchMember> members,
    required String fileName,
    String sheetTitle = 'Nuevos creyentes',
  }) async {
    if (members.isEmpty) {
      throw StateError('No hay datos para exportar.');
    }

    const headers = [
      'Nombre',
      'Apellido',
      'Teléfono',
      'Género',
      'Dirección',
      'Localidad',
      'Líder asignado',
      'Célula del líder',
      'Distancia al líder (km)',
      'Solicita visita',
      'Ocupación',
      'Estado civil',
      'Edad',
      'Día de célula',
      'Horario célula',
      'Zona célula',
      'Fecha formulario',
      'Fecha registro',
      'Observaciones',
    ];

    final rows = members.map((m) {
      return <String>[
        m.firstName,
        m.lastName,
        m.phone,
        m.gender?.label ?? '',
        m.formattedAddress,
        m.locality ?? '',
        m.assignedLeaderName ?? 'Sin líder',
        m.assignedLeaderCellCode ?? '',
        m.assignedDistanceKm?.toStringAsFixed(1) ?? '',
        _yesNo(m.wantsVisit),
        m.occupation ?? '',
        m.maritalStatus?.label ?? '',
        m.age?.toString() ?? '',
        m.cellDay ?? '',
        m.cellTime ?? '',
        m.cellZone ?? '',
        _formatDate(m.formDate),
        _formatDate(m.registeredAt),
        m.observations ?? '',
      ];
    }).toList();

    await _shareExcel(
      fileName: fileName,
      sheetTitle: sheetTitle,
      headers: headers,
      rows: rows,
    );
  }

  Future<void> shareLeadersExcel({
    required List<ChurchLeader> leaders,
    required String fileName,
    String sheetTitle = 'Líderes',
  }) async {
    if (leaders.isEmpty) {
      throw StateError('No hay datos para exportar.');
    }

    const headers = [
      'Apellido',
      'Nombres',
      'Cargo en la iglesia',
      'Género',
      'Célula',
      'Teléfono',
      'Correo',
      'Dirección',
      'Localidad',
      'Fecha registro',
    ];

    final rows = leaders.map((l) {
      return <String>[
        l.lastName,
        l.firstName,
        l.churchOffice?.label ?? '',
        l.gender?.label ?? '',
        l.cellCode ?? '',
        l.mobilePhone,
        l.email ?? '',
        l.formattedAddress,
        l.locality ?? '',
        _formatDate(l.registeredAt),
      ];
    }).toList();

    await _shareExcel(
      fileName: fileName,
      sheetTitle: sheetTitle,
      headers: headers,
      rows: rows,
    );
  }

  Future<void> _shareExcel({
    required String fileName,
    required String sheetTitle,
    required List<String> headers,
    required List<List<String>> rows,
  }) async {
    final excel = Excel.createExcel();
    final defaultName = excel.getDefaultSheet()!;
    excel.rename(defaultName, sheetTitle);
    final sheet = excel[sheetTitle];

    _writeRow(sheet, 0, headers);
    for (var i = 0; i < rows.length; i++) {
      _writeRow(sheet, i + 1, rows[i]);
    }

    final bytes = excel.encode();
    if (bytes == null) {
      throw StateError('No se pudo generar el archivo Excel.');
    }

    final safeName = fileName.endsWith('.xlsx') ? fileName : '$fileName.xlsx';
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/$safeName';
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);

    await Share.shareXFiles(
      [XFile(path, mimeType: _excelMimeType, name: safeName)],
      subject: sheetTitle,
    );
  }

  static void _writeRow(Sheet sheet, int rowIndex, List<String> values) {
    for (var col = 0; col < values.length; col++) {
      sheet
          .cell(
            CellIndex.indexByColumnRow(
              columnIndex: col,
              rowIndex: rowIndex,
            ),
          )
          .value = TextCellValue(values[col]);
    }
  }

  static String get _excelMimeType {
    if (kIsWeb) {
      return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    }
    return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
  }
}
