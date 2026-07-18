import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CalcademyLogo extends StatelessWidget {
  const CalcademyLogo({
    this.size = 72,
    this.showWordmark = false,
    this.showTagline = false,
    this.direction = Axis.horizontal,
    this.decorative = false,
    this.semanticLabel,
    super.key,
  }) : assert(showWordmark || !showTagline);

  static const assetPath = 'assets/branding/calcademy_logo.svg';

  final double size;
  final bool showWordmark;
  final bool showTagline;
  final Axis direction;
  final bool decorative;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final mark = SizedBox.square(
      key: const Key('calcademyLogoMark'),
      dimension: size,
      child: SvgPicture.asset(
        assetPath,
        fit: BoxFit.contain,
        excludeFromSemantics: true,
      ),
    );

    if (!showWordmark) {
      if (decorative) return ExcludeSemantics(child: mark);
      return Semantics(
        image: true,
        label: semanticLabel ?? context.l10n.t('logoSemantics'),
        child: mark,
      );
    }

    final theme = Theme.of(context);
    final text = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: direction == Axis.horizontal
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Text(
          context.l10n.t('appName'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style:
              (size >= 64
                      ? theme.textTheme.headlineMedium
                      : theme.textTheme.titleLarge)
                  ?.copyWith(color: theme.colorScheme.onSurface),
        ),
        if (showTagline) ...[
          const SizedBox(height: AppSpacing.xxs),
          Text(
            context.l10n.t('tagline'),
            textAlign: direction == Axis.horizontal
                ? TextAlign.start
                : TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );

    final content = direction == Axis.horizontal
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              mark,
              const SizedBox(width: AppSpacing.sm),
              Flexible(child: text),
            ],
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              mark,
              const SizedBox(height: AppSpacing.md),
              text,
            ],
          );
    return Semantics(container: true, child: content);
  }
}
