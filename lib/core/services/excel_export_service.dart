import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../leaders/models/church_leader.dart';
import '../utils/file_share.dart';
import '../../members/models/church_member.dart';

/// Exporta listas a CSV (UTF-8 con BOM); Excel lo abre sin paquete `excel`.
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

    await _shareSpreadsheet(
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
        l.churchOfficeLabel ?? '',
        l.gender?.label ?? '',
        l.cellCode ?? '',
        l.mobilePhone,
        l.email ?? '',
        l.formattedAddress,
        l.locality ?? '',
        _formatDate(l.registeredAt),
      ];
    }).toList();

    await _shareSpreadsheet(
      fileName: fileName,
      sheetTitle: sheetTitle,
      headers: headers,
      rows: rows,
    );
  }

  Future<void> _shareSpreadsheet({
    required String fileName,
    required String sheetTitle,
    required List<String> headers,
    required List<List<String>> rows,
  }) async {
    final csvBytes = utf8.encode(_buildCsv(headers, rows));

    final baseName = fileName.replaceAll(RegExp(r'\.xlsx$'), '');
    final safeName =
        baseName.endsWith('.csv') ? baseName : '$baseName.csv';

    if (kIsWeb) {
      throw UnsupportedError(
        'La exportación solo está disponible en la app móvil.',
      );
    }

    final shared = await shareCsvFile(
      bytes: csvBytes,
      fileName: safeName,
      subject: sheetTitle,
    );
    if (!shared) {
      throw StateError('No se pudo abrir el diálogo para compartir el archivo.');
    }
  }

  static String _buildCsv(List<String> headers, List<List<String>> rows) {
    final buffer = StringBuffer('\uFEFF');
    buffer.writeln(headers.map(_escapeCsvField).join(','));
    for (final row in rows) {
      buffer.writeln(row.map(_escapeCsvField).join(','));
    }
    return buffer.toString();
  }

  static String _escapeCsvField(String value) {
    final needsQuotes =
        value.contains(',') || value.contains('"') || value.contains('\n');
    if (!needsQuotes) return value;
    return '"${value.replaceAll('"', '""')}"';
  }
}
