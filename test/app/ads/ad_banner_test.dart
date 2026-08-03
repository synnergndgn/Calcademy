import 'package:calcademy/app/ads/ad_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders nothing and never touches the plugin when disabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(bottomNavigationBar: AdBanner(enabled: false)),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // No ad space is reserved: the banner collapses to zero height, so it
    // cannot push or clip surrounding content.
    expect(tester.getSize(find.byType(AdBanner)).height, 0);
  });

  testWidgets('defaults to AdConfig gating (disabled on the test host)', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(bottomNavigationBar: AdBanner())),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(AdBanner)).height, 0);
  });

  testWidgets('adds no overflow at 320px width and 200% text scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('content')),
          bottomNavigationBar: AdBanner(enabled: false),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('content'), findsOneWidget);
  });

  testWidgets('enabled:true still stays hidden and safe on the test host', (
    tester,
  ) async {
    // Even when explicitly enabled, the SDK-init gate keeps the banner inert
    // on the test host, so no plugin call is made and nothing crashes.
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(bottomNavigationBar: AdBanner(enabled: true)),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(AdBanner)).height, 0);
  });

  testWidgets('builds without error in dark theme', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: const Scaffold(bottomNavigationBar: AdBanner(enabled: false)),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
