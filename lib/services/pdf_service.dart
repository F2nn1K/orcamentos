import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/orcamento.dart';

class PdfService {
  static final _moeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  static final _dataFmt = DateFormat('dd/MM/yyyy');

  static String formatarQuantidade(double qtd) {
    return qtd == qtd.truncateToDouble()
        ? qtd.toInt().toString()
        : qtd.toString().replaceAll('.', ',');
  }

  Future<pw.MemoryImage?> _carregarLogo() async {
    for (final caminho in ['assets/logo.png', 'assets/logo.jpg']) {
      try {
        final dados = await rootBundle.load(caminho);
        return pw.MemoryImage(dados.buffer.asUint8List());
      } catch (_) {
        // Logo ainda não foi adicionada; o PDF sai só com o nome da empresa.
      }
    }
    return null;
  }

  Future<Uint8List> gerar(Orcamento orcamento, DadosEmpresa empresa) async {
    final doc = pw.Document();
    final logo = await _carregarLogo();

    const corPrimaria = PdfColor.fromInt(0xFF1565C0);
    const corCinza = PdfColor.fromInt(0xFF757575);
    const corFundoTabela = PdfColor.fromInt(0xFFE3F0FB);

    final contatoEmpresa = [
      if (empresa.telefone.isNotEmpty) empresa.telefone,
      if (empresa.instagram.isNotEmpty) empresa.instagram,
      if (empresa.email.isNotEmpty) empresa.email,
    ].join('  |  ');

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          // Cabeçalho: logo e empresa à esquerda, dados do orçamento à direita
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (logo != null)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(right: 16),
                  child: pw.ClipRRect(
                    horizontalRadius: 8,
                    verticalRadius: 8,
                    child: pw.Image(
                      logo,
                      height: 64,
                      fit: pw.BoxFit.contain,
                    ),
                  ),
                ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      empresa.nome.isNotEmpty ? empresa.nome : 'Orçamento',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: corPrimaria,
                      ),
                    ),
                    if (contatoEmpresa.isNotEmpty)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 4),
                        child: pw.Text(
                          contatoEmpresa,
                          style: const pw.TextStyle(
                              fontSize: 10, color: corCinza),
                        ),
                      ),
                    if (empresa.endereco.isNotEmpty)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 2),
                        child: pw.Text(
                          empresa.endereco,
                          style: const pw.TextStyle(
                              fontSize: 10, color: corCinza),
                        ),
                      ),
                    if (empresa.cnpj.isNotEmpty)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 2),
                        child: pw.Text(
                          'CNPJ: ${empresa.cnpj}',
                          style: const pw.TextStyle(
                              fontSize: 10, color: corCinza),
                        ),
                      ),
                  ],
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'ORÇAMENTO Nº ${orcamento.numero.toString().padLeft(4, '0')}',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Data: ${_dataFmt.format(orcamento.data)}',
                    style: const pw.TextStyle(fontSize: 10, color: corCinza),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Divider(color: corPrimaria, thickness: 2),
          pw.SizedBox(height: 12),

          // Dados do cliente
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'CLIENTE',
                  style: pw.TextStyle(
                    fontSize: 8,
                    color: corCinza,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  orcamento.cliente,
                  style: pw.TextStyle(
                      fontSize: 12, fontWeight: pw.FontWeight.bold),
                ),
                if (orcamento.telefone.isNotEmpty)
                  pw.Text(
                    orcamento.telefone,
                    style: const pw.TextStyle(fontSize: 10, color: corCinza),
                  ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // Tabela de itens
          pw.TableHelper.fromTextArray(
            headers: ['Produto / Serviço', 'Qtd.', 'Valor unit.', 'Total'],
            data: orcamento.itens
                .map((item) => [
                      item.descricao,
                      formatarQuantidade(item.quantidade),
                      _moeda.format(item.valorUnitario),
                      _moeda.format(item.total),
                    ])
                .toList(),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: corPrimaria),
            cellStyle: const pw.TextStyle(fontSize: 10),
            oddRowDecoration: const pw.BoxDecoration(color: corFundoTabela),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.center,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
            },
            columnWidths: {
              0: const pw.FlexColumnWidth(4),
              1: const pw.FlexColumnWidth(1),
              2: const pw.FlexColumnWidth(1.5),
              3: const pw.FlexColumnWidth(1.5),
            },
            cellPadding:
                const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          ),
          pw.SizedBox(height: 12),

          // Totais
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.SizedBox(
                width: 220,
                child: pw.Column(
                  children: [
                    _linhaTotal('Subtotal', _moeda.format(orcamento.subtotal)),
                    if (orcamento.valorDesconto > 0)
                      _linhaTotal(
                        orcamento.descontoPercentual
                            ? 'Desconto (${formatarQuantidade(orcamento.desconto)}%)'
                            : 'Desconto',
                        '- ${_moeda.format(orcamento.valorDesconto)}',
                      ),
                    pw.Divider(color: corPrimaria),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'TOTAL',
                          style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                            color: corPrimaria,
                          ),
                        ),
                        pw.Text(
                          _moeda.format(orcamento.total),
                          style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                            color: corPrimaria,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Observações
          if (orcamento.observacoes.isNotEmpty) ...[
            pw.SizedBox(height: 24),
            pw.Text(
              'Observações',
              style:
                  pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              orcamento.observacoes,
              style: const pw.TextStyle(fontSize: 10, color: corCinza),
            ),
          ],

          // Assinaturas
          pw.SizedBox(height: 36),
          pw.Column(
            children: [
              pw.Text(
                'Autorizo a execução dos serviços e/ou o fornecimento dos '
                'produtos descritos neste orçamento.',
                style: const pw.TextStyle(fontSize: 9, color: corCinza),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 48),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(child: _campoAssinatura(
                    orcamento.cliente,
                    'Assinatura do cliente',
                  )),
                  pw.SizedBox(width: 48),
                  pw.Expanded(child: _campoAssinatura(
                    empresa.nome,
                    'Assinatura do responsável',
                  )),
                ],
              ),
              pw.SizedBox(height: 24),
              pw.Text(
                'Data: ______ / ______ / __________',
                style: const pw.TextStyle(fontSize: 9, color: corCinza),
              ),
            ],
          ),
        ],
        footer: (context) => pw.Column(
          children: [
            pw.Divider(color: PdfColors.grey300),
            pw.Text(
              empresa.nome.isNotEmpty
                  ? '${empresa.nome} - Orçamento gerado em ${_dataFmt.format(DateTime.now())}'
                  : 'Orçamento gerado em ${_dataFmt.format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 8, color: corCinza),
            ),
          ],
        ),
      ),
    );

    return doc.save();
  }

  pw.Widget _campoAssinatura(String nome, String rotulo) {
    return pw.Column(
      children: [
        pw.Container(height: 0.8, color: PdfColors.grey700),
        pw.SizedBox(height: 4),
        if (nome.isNotEmpty)
          pw.Text(
            nome,
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.center,
          ),
        pw.Text(
          rotulo,
          style: const pw.TextStyle(
              fontSize: 8, color: PdfColor.fromInt(0xFF757575)),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }

  pw.Widget _linhaTotal(String rotulo, String valor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(rotulo, style: const pw.TextStyle(fontSize: 10)),
          pw.Text(valor, style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }
}
