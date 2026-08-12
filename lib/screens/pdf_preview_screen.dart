import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

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

  String get _nomeArquivo =>
      'orcamento_${orcamento.numero.toString().padLeft(4, '0')}_'
      '${orcamento.cliente.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_')}.pdf';

  Future<void> _compartilhar() async {
    final bytes = await PdfService().gerar(orcamento, empresa);
    try {
      // Compartilhamento nativo: envia o arquivo em si (sem link),
      // abrindo a tela padrão do celular (WhatsApp, e-mail, etc.).
      await SharePlus.instance.share(ShareParams(
        files: [
          XFile.fromData(bytes, mimeType: 'application/pdf', name: _nomeArquivo),
        ],
        fileNameOverrides: [_nomeArquivo],
      ));
    } catch (_) {
      // Navegadores sem compartilhamento nativo (ex.: PC): baixa o arquivo.
      await Printing.sharePdf(bytes: bytes, filename: _nomeArquivo);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Orçamento nº ${orcamento.numero}')),
      body: PdfPreview(
        build: (format) => PdfService().gerar(orcamento, empresa),
        pdfFileName: _nomeArquivo,
        allowSharing: false,
        allowPrinting: true,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        actions: [
          PdfPreviewAction(
            icon: const Icon(Icons.share),
            onPressed: (context, build, pageFormat) => _compartilhar(),
          ),
        ],
      ),
    );
  }
}
