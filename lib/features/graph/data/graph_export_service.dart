import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

final graphShareGatewayProvider = Provider<GraphShareGateway>(
  (ref) => const SystemGraphShareGateway(),
);

final graphExportServiceProvider = Provider<GraphExportService>(
  (ref) =>
      GraphExportService(shareGateway: ref.watch(graphShareGatewayProvider)),
);

enum GraphExportFailure { notReady, capture, share }

class GraphExportException implements Exception {
  const GraphExportException(this.failure);

  final GraphExportFailure failure;
}

abstract interface class GraphShareGateway {
  Future<void> share({
    required Uint8List bytes,
    required String fileName,
    required String title,
    Rect? sharePositionOrigin,
  });
}

class SystemGraphShareGateway implements GraphShareGateway {
  const SystemGraphShareGateway();

  @override
  Future<void> share({
    required Uint8List bytes,
    required String fileName,
    required String title,
    Rect? sharePositionOrigin,
  }) async {
    await SharePlus.instance.share(
      ShareParams(
        title: title,
        files: [XFile.fromData(bytes, mimeType: 'image/png')],
        fileNameOverrides: [fileName],
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
  }
}

typedef GraphPngEncoder =
    Future<Uint8List> Function(GlobalKey boundaryKey, double pixelRatio);

class GraphExportService {
  GraphExportService({
    required GraphShareGateway shareGateway,
    GraphPngEncoder? pngEncoder,
  }) : this._(shareGateway, pngEncoder ?? _encodeBoundary);

  GraphExportService._(this._shareGateway, this._pngEncoder);

  final GraphShareGateway _shareGateway;
  final GraphPngEncoder _pngEncoder;

  Future<Uint8List> createPngBytes(
    GlobalKey boundaryKey, {
    double devicePixelRatio = 1,
  }) => _pngEncoder(boundaryKey, devicePixelRatio.clamp(1.0, 3.0));

  static Future<Uint8List> _encodeBoundary(
    GlobalKey boundaryKey,
    double pixelRatio,
  ) async {
    final context = boundaryKey.currentContext;
    final renderObject = context?.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) {
      throw const GraphExportException(GraphExportFailure.notReady);
    }
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 16));
    final refreshed = boundaryKey.currentContext?.findRenderObject();
    if (refreshed is! RenderRepaintBoundary) {
      throw const GraphExportException(GraphExportFailure.notReady);
    }
    final boundary = refreshed;
    try {
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (data == null || data.lengthInBytes == 0) {
        throw const GraphExportException(GraphExportFailure.capture);
      }
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } on GraphExportException {
      rethrow;
    } on Object {
      throw const GraphExportException(GraphExportFailure.capture);
    }
  }

  Future<String> exportAndShare({
    required GlobalKey boundaryKey,
    required String title,
    required double devicePixelRatio,
    Rect? sharePositionOrigin,
    DateTime? now,
  }) async {
    final Uint8List bytes;
    try {
      bytes = await createPngBytes(
        boundaryKey,
        devicePixelRatio: devicePixelRatio,
      );
    } on GraphExportException {
      rethrow;
    } on Object catch (error) {
      debugPrint('Graph capture failed unexpectedly: $error');
      throw const GraphExportException(GraphExportFailure.capture);
    }
    final fileName = buildFileName(now ?? DateTime.now());
    try {
      await _shareGateway.share(
        bytes: bytes,
        fileName: fileName,
        title: title,
        sharePositionOrigin: sharePositionOrigin,
      );
    } on Object catch (error) {
      debugPrint('Graph share gateway failed: $error');
      throw const GraphExportException(GraphExportFailure.share);
    }
    return fileName;
  }

  String buildFileName(DateTime value) {
    String two(int number) => number.toString().padLeft(2, '0');
    return 'calcademy_graph_${value.year}-${two(value.month)}-'
        '${two(value.day)}_${two(value.hour)}${two(value.minute)}'
        '${two(value.second)}.png';
  }
}
