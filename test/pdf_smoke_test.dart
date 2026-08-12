import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:orcamentos/models/orcamento.dart';
import 'package:orcamentos/services/pdf_service.dart';
import 'package:orcamentos/utils/extenso.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('valor por extenso', () {
    expect(valorPorExtenso(4150), 'QUATRO MIL CENTO E CINQUENTA REAIS');
    expect(valorPorExtenso(1260.50),
        'MIL DUZENTOS E SESSENTA REAIS E CINQUENTA CENTAVOS');
    expect(valorPorExtenso(100), 'CEM REAIS');
    expect(valorPorExtenso(1100), 'MIL E CEM REAIS');
    expect(valorPorExtenso(1), 'UM REAL');
    expect(valorPorExtenso(0.05), 'CINCO CENTAVOS');
    expect(valorPorExtenso(2000000), 'DOIS MILHÕES DE REAIS');
  });

  test('gera PDF de exemplo com logo e dados da empresa', () async {
    await initializeDateFormatting('pt_BR');

    final orcamento = Orcamento(
      id: '1',
      numero: 1,
      cliente: 'Cliente de Teste',
      telefone: '(95) 90000-0000',
      titulo: 'Manutenção de CFTV IP',
      data: DateTime(2026, 8, 12),
      itens: [
        ItemOrcamento(
            descricao: 'Câmera de segurança',
            unidade: 'UND',
            quantidade: 4,
            valorUnitario: 250),
        ItemOrcamento(
            descricao: 'Instalação',
            unidade: 'SVÇ',
            quantidade: 1,
            valorUnitario: 400),
      ],
      descontoPercentual: true,
      desconto: 10,
    );

    final bytes = await PdfService().gerar(orcamento, DadosEmpresa.padrao());
    expect(bytes.length, greaterThan(10000));

    File('build/orcamento_exemplo.pdf').writeAsBytesSync(bytes);
  });
}
