import 'package:church_register/cells/models/church_cell.dart';
import 'package:church_register/cells/services/cell_over_capacity_service.dart';
import 'package:flutter_test/flutter_test.dart';

ChurchCell _cell({
  required String id,
  required String code,
  int? memberCount,
}) {
  return ChurchCell(
    id: id,
    code: code,
    registeredAt: DateTime(2025, 1, 1),
    registeredBy: 'admin@test.com',
    memberCount: memberCount,
  );
}

void main() {
  group('CellOverCapacityService.buildOverCapacityEntries', () {
    test('incluye todas las células con más de 12 integrantes reales', () {
      final cells = [
        _cell(id: 'cell-1', code: 'C01', memberCount: 10),
        _cell(id: 'cell-2', code: 'C02', memberCount: 10),
        _cell(id: 'cell-3', code: 'C03', memberCount: 15),
      ];
      final counts = {
        'cell-1': 13,
        'cell-2': 14,
        'cell-3': 8,
      };

      final entries = CellOverCapacityService.buildOverCapacityEntries(
        cells: cells,
        countsByCellId: counts,
      );

      expect(entries, hasLength(2));
      expect(entries.map((e) => e.cell.id).toList(), ['cell-2', 'cell-1']);
      expect(entries[0].memberCount, 14);
      expect(entries[1].memberCount, 13);
    });

    test('no omite células aunque todas tengan memberCount guardado', () {
      final cells = [
        _cell(id: 'cell-1', code: 'C01', memberCount: 8),
        _cell(id: 'cell-2', code: 'C02', memberCount: 8),
      ];

      final entries = CellOverCapacityService.buildOverCapacityEntries(
        cells: cells,
        countsByCellId: {
          'cell-1': 13,
          'cell-2': 15,
        },
      );

      expect(entries, hasLength(2));
    });

    test('usa memberCount del documento si no hay integrantes asignados', () {
      final entries = CellOverCapacityService.buildOverCapacityEntries(
        cells: [_cell(id: 'cell-1', code: 'C01', memberCount: 16)],
        countsByCellId: const {},
      );

      expect(entries, hasLength(1));
      expect(entries.single.memberCount, 16);
    });
  });
}
