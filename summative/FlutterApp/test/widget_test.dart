import 'package:flutter_test/flutter_test.dart';
import 'package:crop_yield_app/main.dart';

void main() {
  testWidgets('Crop Yield Predictor loads correctly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CropYieldApp());

    expect(find.text('Crop Yield Predictor'), findsOneWidget);
    expect(find.text('Country'), findsOneWidget);
    expect(find.text('Crop'), findsOneWidget);
    expect(find.text('Predict'), findsOneWidget);
  });
}
