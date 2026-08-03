import 'package:calcademy/app/tools/calcademy_tool_registry.dart';
import 'package:calcademy/features/formula_library/domain/formula_category.dart';
import 'package:calcademy/features/formula_library/domain/formula_entry.dart';
import 'package:calcademy/features/formula_library/domain/formula_example.dart';
import 'package:calcademy/features/formula_library/domain/formula_registry.dart';
import 'package:calcademy/features/formula_library/domain/formula_variable.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FormulaEntry can be created with bilingual educational content', () {
    const entry = FormulaEntry(
      id: 'sample',
      titleEn: 'Sample',
      titleTr: 'Örnek',
      category: FormulaCategory.mathematics,
      formulaText: 'x=1',
      plainTextFormula: 'x=1',
      descriptionEn: 'Description',
      descriptionTr: 'Açıklama',
      variables: [
        FormulaVariable(
          symbol: 'x',
          nameEn: 'value',
          nameTr: 'değer',
          descriptionEn: 'A value.',
          descriptionTr: 'Bir değer.',
        ),
      ],
      examples: [
        FormulaExample(
          titleEn: 'Example',
          titleTr: 'Örnek',
          givenValues: {'x': '1'},
          stepsEn: ['Substitute.'],
          stepsTr: ['Yerine koyun.'],
          result: '1',
        ),
      ],
      tags: ['sample'],
      relatedTools: [],
      difficulty: FormulaDifficulty.basic,
    );
    expect(entry.title('tr'), 'Örnek');
    expect(entry.supportedLocales, containsAll(['en', 'tr']));
  });

  test('registry is complete, unique, bilingual, and connected', () {
    final entries = FormulaRegistry.entries;
    expect(entries.length, greaterThanOrEqualTo(45));
    expect(entries.map((entry) => entry.id).toSet(), hasLength(entries.length));
    expect(entries.map((entry) => entry.category).toSet(), hasLength(9));
    for (final entry in entries) {
      expect(entry.titleEn.trim(), isNotEmpty, reason: entry.id);
      expect(entry.titleTr.trim(), isNotEmpty, reason: entry.id);
      expect(entry.descriptionEn.trim(), isNotEmpty, reason: entry.id);
      expect(entry.descriptionTr.trim(), isNotEmpty, reason: entry.id);
      expect(entry.variables, isNotEmpty, reason: entry.id);
      expect(entry.examples, isNotEmpty, reason: entry.id);
      for (final link in entry.relatedTools) {
        final tool = CalcademyToolRegistry.byId(link.toolId);
        expect(tool, isNotNull, reason: '${entry.id}: ${link.toolId}');
        expect(link.route, tool!.route);
      }
    }
  });

  test('search supports title, tags, category, Turkish, and no result', () {
    expect(
      FormulaRegistry.search(query: 'Quadratic').single.id,
      'quadratic-formula',
    );
    expect(
      FormulaRegistry.search(query: 'kökler').single.id,
      'quadratic-formula',
    );
    expect(FormulaRegistry.search(query: 'Bugünkü Değer'), isNotEmpty);
    final calculus = FormulaRegistry.search(category: FormulaCategory.calculus);
    expect(calculus, isNotEmpty);
    expect(
      calculus.every((entry) => entry.category == FormulaCategory.calculus),
      isTrue,
    );
    expect(
      FormulaRegistry.search(query: 'definitely-no-such-formula'),
      isEmpty,
    );
  });
}
