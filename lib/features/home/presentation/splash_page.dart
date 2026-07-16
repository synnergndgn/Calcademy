import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (mounted) context.go('/home');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.primary,
      body: Center(
        child: FadeTransition(
          opacity: CurvedAnimation(parent: _controller, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween(begin: 0.82, end: 1.0).animate(
              CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: colors.onPrimary,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Icon(
                    Icons.functions_rounded,
                    size: 58,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  context.l10n.t('appName'),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: colors.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.t('tagline'),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: colors.onPrimary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
