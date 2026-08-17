import 'package:calcademy/app/theme/app_colors.dart';
import 'package:calcademy/app/theme/app_radius.dart';
import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/app/theme/app_typography.dart';
import 'package:flutter/material.dart';

abstract final class AppTheme {
  static ThemeData light() => _theme(Brightness.light);
  static ThemeData dark() => _theme(Brightness.dark);

  static ThemeData _theme(Brightness brightness) {
    final colors = brightness == Brightness.light
        ? AppColors.lightScheme()
        : AppColors.darkScheme();
    return ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      textTheme: AppTypography.textTheme(brightness),
      // The app-level GraphPaperBackground is shared by every route. Keeping
      // scaffolds transparent lets legacy and refactored pages use one canvas.
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: AppTypography.textTheme(brightness).titleLarge
            ?.copyWith(color: colors.onSurface, fontWeight: FontWeight.w700),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: _AcademicCardBorder(
          accent: BorderSide(color: colors.primary, width: 3),
          divider: BorderSide(color: colors.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: AppRadius.control,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.control,
          borderSide: BorderSide(color: colors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.control,
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.control,
          borderSide: BorderSide(color: colors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.control,
          borderSide: BorderSide(color: colors.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: colors.surfaceContainerLowest,
        indicatorColor: colors.primaryContainer,
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: AppRadius.control,
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? TextStyle(color: colors.onSurface, fontWeight: FontWeight.w600)
              : TextStyle(color: colors.onSurfaceVariant);
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceContainerLowest,
        selectedColor: colors.primaryContainer,
        side: BorderSide(color: colors.outlineVariant),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colors.primary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xxs,
        ),
        minVerticalPadding: AppSpacing.sm,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.control),
      ),
      tabBarTheme: TabBarThemeData(
        dividerColor: colors.outlineVariant,
        indicatorColor: colors.primary,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: colors.onSurface,
        unselectedLabelColor: colors.onSurfaceVariant,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: AppRadius.button),
          ),
          side: WidgetStatePropertyAll(
            BorderSide(color: colors.outlineVariant),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.inverseSurface,
        contentTextStyle: TextStyle(color: colors.onInverseSurface),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.control),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.hero),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.heroValue),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 2,
        highlightElevation: 1,
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.control),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colors.inverseSurface,
          borderRadius: AppRadius.button,
        ),
        textStyle: TextStyle(color: colors.onInverseSurface),
      ),
      dividerTheme: DividerThemeData(color: colors.outlineVariant),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.onPrimary
              : colors.outline,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.primary
              : colors.surfaceContainerHighest,
        ),
      ),
    );
  }
}

/// Shared notebook edges for Material [Card] widgets that predate the
/// Academic Calculator OS surfaces.
class _AcademicCardBorder extends ShapeBorder {
  const _AcademicCardBorder({required this.accent, required this.divider});

  final BorderSide accent;
  final BorderSide divider;

  @override
  EdgeInsetsGeometry get dimensions =>
      EdgeInsets.only(left: accent.width, bottom: divider.width);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(
        RRect.fromRectAndRadius(
          rect.deflate(divider.width),
          const Radius.circular(AppRadius.cardValue - 1),
        ),
      );

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => Path()
    ..addRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(AppRadius.cardValue)),
    );

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    canvas.drawLine(
      Offset(rect.left + accent.width / 2, rect.top + AppRadius.cardValue),
      Offset(rect.left + accent.width / 2, rect.bottom - AppRadius.cardValue),
      accent.toPaint(),
    );
    canvas.drawLine(
      Offset(rect.left + AppRadius.cardValue, rect.bottom - divider.width / 2),
      Offset(rect.right - AppRadius.cardValue, rect.bottom - divider.width / 2),
      divider.toPaint(),
    );
  }

  @override
  ShapeBorder scale(double t) =>
      _AcademicCardBorder(accent: accent.scale(t), divider: divider.scale(t));
}
