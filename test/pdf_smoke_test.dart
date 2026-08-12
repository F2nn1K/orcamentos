import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:orcamentos/models/orcamento.dart';
import 'package:orcamentos/services/pdf_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('gera PDF de exemplo com logo e dados da empresa', () async {
    final orcamento = Orcamento(
      id: '1',
      numero: 1,
      cliente: 'Cliente de Teste',
      telefone: '(95) 90000-0000',
      data: DateTime(2026, 8, 11),
      itens: [
        ItemOrcamento(descricao: 'Câmera de segurança', quantidade: 4, valorUnitario: 250),
        ItemOrcamento(descricao: 'Instalação', quantidade: 1, valorUnitario: 400),
      ],
      descontoPercentual: true,
      desconto: 10,
    );

    final bytes = await PdfService().gerar(orcamento, DadosEmpresa.padrao());
    expect(bytes.length, greaterThan(10000));

    File('build/orcamento_exemplo.pdf').writeAsBytesSync(bytes);
  });
}
