import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../models/orcamento.dart';
import '../services/pdf_service.dart';

class PdfPreviewScreen extends StatelessWidget {
  final Orcamento orcamento;
  final DadosEmpresa empresa;

  const PdfPreviewScreen({
    super.key,
    required this.orcamento,
    required this.empresa,
  });

  @override
  Widget build(BuildContext context) {
    final nomeArquivo =
        'orcamento_${orcamento.numero.toString().padLeft(4, '0')}_'
        '${orcamento.cliente.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_')}.pdf';

    return Scaffold(
      appBar: AppBar(title: Text('Orçamento nº ${orcamento.numero}')),
      body: PdfPreview(
        build: (format) => PdfService().gerar(orcamento, empresa),
        pdfFileName: nomeArquivo,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
      ),
    );
  }
}
