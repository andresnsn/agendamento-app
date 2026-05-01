import 'package:flutter_test/flutter_test.dart';
import 'package:agendamento_app/main.dart';

void main() {
  testWidgets('App renders login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const AgendamentoApp());
    expect(find.text('Agendamento'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });
}
