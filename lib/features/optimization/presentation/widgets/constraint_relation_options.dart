import 'package:calcademy/features/linear_programming/domain/linear_program.dart';
import 'package:calcademy/features/optimization/presentation/widgets/responsive_constraint_card.dart';
import 'package:calcademy/l10n/app_localizations.dart';

/// The ≤ / ≥ / = options both optimization editors feed into
/// [ResponsiveConstraintCard]. This adapter is the only place that binds
/// the domain's [ConstraintRelation] to the domain-free card widget, so
/// the mapping (and its accessibility labels) stays in one spot.
List<RelationOption<ConstraintRelation>> constraintRelationOptions(
  AppLocalizations l10n,
) => [
  RelationOption(
    value: ConstraintRelation.lessOrEqual,
    symbol: '≤',
    semanticLabel: l10n.t('relationLessOrEqual'),
  ),
  RelationOption(
    value: ConstraintRelation.greaterOrEqual,
    symbol: '≥',
    semanticLabel: l10n.t('relationGreaterOrEqual'),
  ),
  RelationOption(
    value: ConstraintRelation.equal,
    symbol: '=',
    semanticLabel: l10n.t('relationEqual'),
  ),
];
