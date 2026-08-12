import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/orcamento.dart';
import '../utils/extenso.dart';

class PdfService {
  static final _moeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  static final _dataFmt = DateFormat('dd/MM/yyyy');

  static const _cinza = PdfColor.fromInt(0xFF555555);

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

    final dataExtenso = DateFormat("d 'DE' MMMM 'DE' y", 'pt_BR')
        .format(orcamento.data)
        .toUpperCase();
    final cidade = empresa.cidade.isNotEmpty ? empresa.cidade : 'Boa Vista';

    final contatoEmpresa = [
      if (empresa.telefone.isNotEmpty) empresa.telefone,
      if (empresa.instagram.isNotEmpty) empresa.instagram,
      if (empresa.email.isNotEmpty) empresa.email,
    ].join('  |  ');

    final titulo = orcamento.titulo.trim().isNotEmpty
        ? 'ORÇAMENTO Nº ${orcamento.numero.toString().padLeft(4, '0')}: '
            '${orcamento.titulo.trim().toUpperCase()}'
        : 'ORÇAMENTO Nº ${orcamento.numero.toString().padLeft(4, '0')}';

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 32, 36, 36),
        build: (context) => [
          // ---------- Cabeçalho ----------
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 92,
                child: logo != null
                    ? pw.ClipRRect(
                        horizontalRadius: 6,
                        verticalRadius: 6,
                        child: pw.Image(logo, height: 58,
                            fit: pw.BoxFit.contain),
                      )
                    : pw.SizedBox(),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      empresa.nome.toUpperCase(),
                      style: pw.TextStyle(
                          fontSize: 14, fontWeight: pw.FontWeight.bold),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 3),
                    if (empresa.cnpj.isNotEmpty)
                      pw.Text(
                        'CNPJ: ${empresa.cnpj}',
                        style: pw.TextStyle(
                            fontSize: 9, fontWeight: pw.FontWeight.bold),
                      ),
                    if (empresa.endereco.isNotEmpty)
                      pw.Text(
                        empresa.endereco,
                        style: const pw.TextStyle(fontSize: 9),
                        textAlign: pw.TextAlign.center,
                      ),
                    if (contatoEmpresa.isNotEmpty)
                      pw.Text(
                        contatoEmpresa,
                        style: pw.TextStyle(
                            fontSize: 9, fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.center,
                      ),
                  ],
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Container(
                width: 92,
                alignment: pw.Alignment.topRight,
                child: empresa.lema.isNotEmpty
                    ? pw.Text(
                        empresa.lema.toUpperCase(),
                        style: pw.TextStyle(
                            fontSize: 8, fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.right,
                      )
                    : pw.SizedBox(),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Container(height: 1.2, color: PdfColors.black),
          pw.SizedBox(height: 14),

          // ---------- Data e destinatário ----------
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              '$cidade, $dataExtenso.',
              style: pw.TextStyle(
                  fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 14),
          pw.RichText(
            text: pw.TextSpan(
              style: const pw.TextStyle(fontSize: 10),
              children: [
                const pw.TextSpan(text: 'Para: '),
                pw.TextSpan(
                  text: orcamento.cliente.toUpperCase(),
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                if (orcamento.telefone.isNotEmpty)
                  pw.TextSpan(text: '  -  ${orcamento.telefone}'),
              ],
            ),
          ),
          pw.SizedBox(height: 14),

          // ---------- Título ----------
          pw.Center(
            child: pw.Text(
              titulo,
              style: pw.TextStyle(
                  fontSize: 12, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.SizedBox(height: 10),

          // ---------- Tabela de itens ----------
          pw.TableHelper.fromTextArray(
            headers: ['ITEM', 'UND', 'QTD', 'DESCRIÇÃO', 'VALOR UND', 'VALOR TOTAL'],
            data: [
              for (var i = 0; i < orcamento.itens.length; i++)
                [
                  (i + 1).toString().padLeft(2, '0'),
                  orcamento.itens[i].unidade.toUpperCase(),
                  formatarQuantidade(orcamento.itens[i].quantidade),
                  orcamento.itens[i].descricao.toUpperCase(),
                  _moeda.format(orcamento.itens[i].valorUnitario),
                  _moeda.format(orcamento.itens[i].total),
                ],
            ],
            border: pw.TableBorder.all(width: 0.7),
            headerStyle: pw.TextStyle(
                fontSize: 8.5, fontWeight: pw.FontWeight.bold),
            headerAlignment: pw.Alignment.center,
            cellStyle: const pw.TextStyle(fontSize: 8.5),
            cellAlignments: {
              0: pw.Alignment.center,
              1: pw.Alignment.center,
              2: pw.Alignment.center,
              3: pw.Alignment.centerLeft,
              4: pw.Alignment.centerRight,
              5: pw.Alignment.centerRight,
            },
            columnWidths: {
              0: const pw.FlexColumnWidth(0.8),
              1: const pw.FlexColumnWidth(0.8),
              2: const pw.FlexColumnWidth(0.7),
              3: const pw.FlexColumnWidth(4.6),
              4: const pw.FlexColumnWidth(1.5),
              5: const pw.FlexColumnWidth(1.6),
            },
            cellPadding:
                const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
          ),

          // ---------- Subtotal / desconto (se houver) ----------
          if (orcamento.valorDesconto > 0)
            pw.Container(
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  left: pw.BorderSide(width: 0.7),
                  right: pw.BorderSide(width: 0.7),
                  bottom: pw.BorderSide(width: 0.7),
                ),
              ),
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: pw.Column(
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('SUBTOTAL',
                          style: const pw.TextStyle(fontSize: 9)),
                      pw.Text(_moeda.format(orcamento.subtotal),
                          style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                  pw.SizedBox(height: 2),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        orcamento.descontoPercentual
                            ? 'DESCONTO (${formatarQuantidade(orcamento.desconto)}%)'
                            : 'DESCONTO',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                      pw.Text('- ${_moeda.format(orcamento.valorDesconto)}',
                          style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                ],
              ),
            ),

          // ---------- Total ----------
          pw.Container(
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                left: pw.BorderSide(width: 0.7),
                right: pw.BorderSide(width: 0.7),
                bottom: pw.BorderSide(width: 0.7),
              ),
            ),
            padding:
                const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('TOTAL',
                    style: pw.TextStyle(
                        fontSize: 13, fontWeight: pw.FontWeight.bold)),
                pw.Text(_moeda.format(orcamento.total),
                    style: pw.TextStyle(
                        fontSize: 13, fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ),
          pw.SizedBox(height: 12),

          // ---------- Valor por extenso ----------
          pw.RichText(
            text: pw.TextSpan(
              style: const pw.TextStyle(fontSize: 10),
              children: [
                const pw.TextSpan(
                    text: 'O presente orçamento fica no valor de: '),
                pw.TextSpan(
                  text: '${valorPorExtenso(orcamento.total)}.',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    decoration: pw.TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),

          // ---------- Observações ----------
          if (orcamento.observacoes.isNotEmpty) ...[
            pw.SizedBox(height: 14),
            pw.Text(
              'Observações: ${orcamento.observacoes}',
              style: const pw.TextStyle(fontSize: 9, color: _cinza),
            ),
          ],

          // ---------- Assinaturas ----------
          pw.SizedBox(height: 26),
          pw.Text('Atenciosamente,', style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 38),
          pw.Center(
            child: pw.Column(
              children: [
                pw.Container(width: 260, height: 0.8, color: PdfColors.black),
                pw.SizedBox(height: 4),
                pw.Text(
                  empresa.nome.toUpperCase(),
                  style: pw.TextStyle(
                      fontSize: 10, fontWeight: pw.FontWeight.bold),
                ),
                if (empresa.responsavel.isNotEmpty)
                  pw.Text(empresa.responsavel,
                      style: const pw.TextStyle(fontSize: 9)),
              ],
            ),
          ),
          pw.SizedBox(height: 26),
          pw.Center(
            child: pw.Text(
              'Autorizo a execução dos serviços e/ou o fornecimento dos '
              'produtos descritos neste orçamento.',
              style: const pw.TextStyle(fontSize: 9, color: _cinza),
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.SizedBox(height: 34),
          pw.Center(
            child: pw.Column(
              children: [
                pw.Container(width: 260, height: 0.8, color: PdfColors.black),
                pw.SizedBox(height: 4),
                pw.Text(
                  orcamento.cliente.toUpperCase(),
                  style: pw.TextStyle(
                      fontSize: 10, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text('Assinatura do cliente',
                    style: const pw.TextStyle(fontSize: 8, color: _cinza)),
                pw.SizedBox(height: 8),
                pw.Text('Data: ______ / ______ / __________',
                    style: const pw.TextStyle(fontSize: 9)),
              ],
            ),
          ),
        ],
        footer: (context) => pw.Column(
          children: [
            if (logo != null)
              pw.Center(
                child: pw.ClipRRect(
                  horizontalRadius: 4,
                  verticalRadius: 4,
                  child: pw.Image(logo, height: 30),
                ),
              ),
            pw.SizedBox(height: 3),
            pw.Text(
              '${empresa.nome} - Orçamento gerado em '
              '${_dataFmt.format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 7, color: _cinza),
              textAlign: pw.TextAlign.center,
            ),
          ],
        ),
      ),
    );

    return doc.save();
  }
}
