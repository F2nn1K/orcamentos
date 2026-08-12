import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:orcamentos/main.dart';

void main() {
  testWidgets('abre a tela inicial de orçamentos', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('pt_BR');
    await tester.pumpWidget(const OrcamentosApp());
    await tester.pumpAndSettle();

    expect(find.text('Orçamentos'), findsOneWidget);
    expect(find.text('Novo orçamento'), findsOneWidget);
  });
}
