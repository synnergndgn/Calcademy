import 'package:calcademy/app/tools/calcademy_tool_registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tool registry contains expected routable tools', () {
    const expected = {
      'scientific_calculator',
      'graph_plotter',
      'matrix',
      'equation_solver',
      'calculus',
      'statistics',
      'financial_calculator',
      'linear_programming',
      'integer_programming',
      'operations_research',
      'saved',
    };
    expect(
      CalcademyToolRegistry.tools.map((tool) => tool.id).toSet(),
      expected,
    );
    for (final tool in CalcademyToolRegistry.tools) {
      expect(tool.route, startsWith('/'), reason: tool.id);
      expect(tool.titleEn, isNotEmpty);
      expect(tool.titleTr, isNotEmpty);
    }
  });
}
