import 'package:calcademy/features/saved_calculations/domain/saved_calculation_module.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculations_limits.dart';

typedef SavedJson = Map<String, Object?>;

class SavedCalculationDraft {
  const SavedCalculationDraft({
    required this.title,
    required this.module,
    required this.calculationType,
    required this.inputSummary,
    required this.resultSummary,
    this.fullInputJson = const {},
    this.resultJson = const {},
    this.tags = const [],
  });

  final String title;
  final SavedCalculationModule module;
  final String calculationType;
  final String inputSummary;
  final String resultSummary;
  final SavedJson fullInputJson;
  final SavedJson resultJson;
  final List<String> tags;
}

class SavedCalculation {
  const SavedCalculation({
    required this.id,
    required this.title,
    required this.module,
    required this.calculationType,
    required this.createdAt,
    required this.updatedAt,
    required this.isFavorite,
    required this.inputSummary,
    required this.resultSummary,
    required this.fullInputJson,
    required this.resultJson,
    required this.tags,
    this.schemaVersion = SavedCalculationsLimits.schemaVersion,
  });

  final String id;
  final String title;
  final SavedCalculationModule module;
  final String calculationType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFavorite;
  final String inputSummary;
  final String resultSummary;
  final SavedJson fullInputJson;
  final SavedJson resultJson;
  final List<String> tags;
  final int schemaVersion;

  String get moduleId => module.id;
  String get moduleName => module.titleKey;

  SavedCalculation copyWith({
    String? title,
    DateTime? updatedAt,
    bool? isFavorite,
  }) => SavedCalculation(
    id: id,
    title: title ?? this.title,
    module: module,
    calculationType: calculationType,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    isFavorite: isFavorite ?? this.isFavorite,
    inputSummary: inputSummary,
    resultSummary: resultSummary,
    fullInputJson: fullInputJson,
    resultJson: resultJson,
    tags: tags,
    schemaVersion: schemaVersion,
  );

  SavedJson toJson() => {
    'schemaVersion': schemaVersion,
    'id': id,
    'title': title,
    'moduleId': moduleId,
    'moduleName': moduleName,
    'calculationType': calculationType,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
    'isFavorite': isFavorite,
    'inputSummary': inputSummary,
    'resultSummary': resultSummary,
    'fullInputJson': fullInputJson,
    'resultJson': resultJson,
    'tags': tags,
  };

  factory SavedCalculation.fromJson(SavedJson json) {
    final schemaVersion = _requiredInt(json, 'schemaVersion');
    if (schemaVersion != SavedCalculationsLimits.schemaVersion) {
      throw const FormatException('Unsupported saved calculation schema.');
    }
    return SavedCalculation(
      id: _requiredString(json, 'id'),
      title: _requiredString(json, 'title'),
      module: SavedCalculationModule.fromId(_requiredString(json, 'moduleId')),
      calculationType: _requiredString(json, 'calculationType'),
      createdAt: DateTime.parse(_requiredString(json, 'createdAt')),
      updatedAt: DateTime.parse(_requiredString(json, 'updatedAt')),
      isFavorite: json['isFavorite'] as bool? ?? false,
      inputSummary: _requiredString(json, 'inputSummary'),
      resultSummary: _requiredString(json, 'resultSummary'),
      fullInputJson: _jsonMap(json['fullInputJson']),
      resultJson: _jsonMap(json['resultJson']),
      tags: (json['tags'] as List<Object?>? ?? const [])
          .whereType<String>()
          .toList(growable: false),
      schemaVersion: schemaVersion,
    );
  }

  static String _requiredString(SavedJson json, String key) {
    final value = json[key];
    if (value is! String || value.isEmpty) {
      throw FormatException('Invalid $key.');
    }
    return value;
  }

  static int _requiredInt(SavedJson json, String key) {
    final value = json[key];
    if (value is! int) throw FormatException('Invalid $key.');
    return value;
  }

  static SavedJson _jsonMap(Object? value) {
    if (value == null) return const {};
    if (value is! Map) throw const FormatException('Invalid JSON payload.');
    return Map<String, Object?>.from(value);
  }
}
