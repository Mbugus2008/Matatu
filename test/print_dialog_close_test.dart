import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// Guards the print-spinner dismissal mechanism used by the receipt page
/// (`_closePrintDialog`): the dialog is popped through the navigator with the
/// context captured INSIDE the dialog route.
///
/// GetX 4.7.2's `Get.back()` is NOT used for that: while a snackbar is open it
/// closes the snackbar and RETURNS without popping the dialog, and clearing
/// snackbars first does not help — their state only clears after the closing
/// animation (verified in the package's snackbar_controller.dart), which left
/// the print spinner up "forever". The navigator pop below is immune to all
/// of that.
void main() {
  setUp(() => Get.testMode = true);
  tearDown(() => Get.testMode = false);

  testWidgets('spinner dialog closes via its own context', (tester) async {
    BuildContext? dialogContext;

    await tester.pumpWidget(
      GetMaterialApp(home: const Scaffold(body: SizedBox())),
    );
    await tester.pump();

    Get.dialog(
      Builder(builder: (ctx) {
        dialogContext = ctx;
        return const Center(child: CircularProgressIndicator());
      }),
      barrierDismissible: false,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(dialogContext, isNotNull);
    expect(dialogContext!.mounted, isTrue);

    // Exactly what _closePrintDialog does.
    Navigator.of(dialogContext!).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
