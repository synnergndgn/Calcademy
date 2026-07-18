import 'dart:typed_data';

import 'package:calcademy/features/graph/data/graph_export_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'export service writes PNG bytes and invokes the share abstraction',
    () async {
      final key = GlobalKey();
      final share = _FakeShareGateway();
      final png = <int>[137, 80, 78, 71, 13, 10, 26, 10, 1, 2, 3];
      final service = GraphExportService(
        shareGateway: share,
        pngEncoder: (boundaryKey, pixelRatio) async {
          expect(boundaryKey, same(key));
          expect(pixelRatio, 2);
          return Uint8List.fromList(png);
        },
      );

      final bytes = await service.createPngBytes(key, devicePixelRatio: 2);
      expect(bytes, isNotEmpty);
      expect(bytes.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);

      final fileName = await service.exportAndShare(
        boundaryKey: key,
        title: 'Graph',
        devicePixelRatio: 2,
        now: DateTime(2026, 7, 17, 20, 35),
      );
      expect(fileName, 'calcademy_graph_2026-07-17_203500.png');
      expect(share.fileName, fileName);
      expect(share.bytes, png);
    },
  );

  test('export service rejects an unrendered boundary', () async {
    final service = GraphExportService(shareGateway: _FakeShareGateway());

    expect(
      service.createPngBytes(GlobalKey()),
      throwsA(isA<GraphExportException>()),
    );
  });

  test('export filename is safe and deterministic', () {
    final service = GraphExportService(shareGateway: _FakeShareGateway());

    expect(
      service.buildFileName(DateTime(2026, 7, 17, 20, 35, 9)),
      'calcademy_graph_2026-07-17_203509.png',
    );
    expect(
      service.buildFileName(DateTime(2026, 7, 17, 20, 35, 9)),
      isNot(matches(RegExp(r'[<>:"/\\|?*]'))),
    );
  });
}

class _FakeShareGateway implements GraphShareGateway {
  List<int>? bytes;
  String? fileName;

  @override
  Future<void> share({
    required Uint8List bytes,
    required String fileName,
    required String title,
    Rect? sharePositionOrigin,
  }) async {
    this.bytes = bytes;
    this.fileName = fileName;
  }
}
