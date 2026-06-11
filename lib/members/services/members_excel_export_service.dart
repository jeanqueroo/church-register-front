import 'dart:io';

import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/church_member.dart';

class MembersExcelExportService {
  Future<void> shareMembers(List<ChurchMember> members) async {
    if (members.isEmpty) {
      throw MembersExcelExportException('No hay creyentes para exportar');
    }

    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet();
    if (defaultSheet != null) {
      excel.delete(defaultSheet);
    }

    const sheetName = 'Creyentes';
    final sheet = excel[sheetName];
    final dateFormat = DateFormat('dd/MM/yyyy');
    final dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');

    sheet.appendRow(_headers.map(TextCellValue.new).toList());

    for (final member in members) {
      sheet.appendRow([
        TextCellValue(member.lastName),
        TextCellValue(member.firstName),
        TextCellValue(member.gender?.label ?? ''),
        TextCellValue(member.idDocumentType?.label ?? ''),
        TextCellValue(member.idDocumentNumber ?? ''),
        TextCellValue(member.phone),
        TextCellValue(
          member.birthDate != null
              ? dateFormat.format(member.birthDate!)
              : '',
        ),
        TextCellValue(member.age?.toString() ?? ''),
        TextCellValue(member.maritalStatus?.label ?? ''),
        TextCellValue(member.entrySource?.label ?? ''),
        TextCellValue(member.occupation ?? ''),
        TextCellValue(member.volunteer ?? ''),
        TextCellValue(member.street ?? ''),
        TextCellValue(member.streetNumber ?? ''),
        TextCellValue(member.neighborhood ?? ''),
        TextCellValue(member.locality ?? ''),
        TextCellValue(member.stateProvince ?? ''),
        TextCellValue(member.postalCode ?? ''),
        TextCellValue(member.formattedAddress),
        TextCellValue(member.cellDay ?? ''),
        TextCellValue(member.cellTime ?? ''),
        TextCellValue(member.cellZone ?? ''),
        TextCellValue(member.assignedLeaderName ?? ''),
        TextCellValue(member.assignedLeaderCellCode ?? ''),
        TextCellValue(
          member.assignedDistanceKm != null
              ? member.assignedDistanceKm!.toStringAsFixed(2)
              : '',
        ),
        TextCellValue(member.wantsVisit ? 'Sí' : 'No'),
        TextCellValue(member.observations ?? ''),
        TextCellValue(dateFormat.format(member.formDate)),
        TextCellValue(dateTimeFormat.format(member.registeredAt)),
      ]);
    }

    final bytes = excel.save();
    if (bytes == null) {
      throw MembersExcelExportException('No se pudo generar el archivo Excel');
    }

    final dir = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${dir.path}/creyentes_$timestamp.xlsx');
    await file.writeAsBytes(bytes);

    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(
            file.path,
            mimeType:
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            name: 'creyentes_$timestamp.xlsx',
          ),
        ],
        subject: 'Creyentes registrados',
        text: 'Listado de ${members.length} creyente(s)',
      ),
    );
  }

  static const _headers = [
    'Apellido',
    'Nombre',
    'Género',
    'Tipo documento',
    'Número documento',
    'Teléfono',
    'Fecha de nacimiento',
    'Edad',
    'Estado civil',
    'Dónde entró',
    'Ocupación',
    'Voluntario',
    'Calle',
    'Número',
    'Colonia',
    'Localidad',
    'Estado',
    'C.P.',
    'Dirección completa',
    'Día de célula',
    'Hora de célula',
    'Zona de célula',
    'Líder asignado',
    'Célula del líder',
    'Distancia al líder (km)',
    'Desea visita',
    'Observaciones',
    'Fecha del formulario',
    'Fecha de registro',
  ];
}

class MembersExcelExportException implements Exception {
  MembersExcelExportException(this.message);

  final String message;

  @override
  String toString() => message;
}
