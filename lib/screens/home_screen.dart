import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/orcamento.dart';
import '../services/storage_service.dart';
import 'dados_empresa_screen.dart';
import 'editar_orcamento_screen.dart';
import 'pdf_preview_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _storage = StorageService();
  final _moeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _dataFmt = DateFormat('dd/MM/yyyy');

  List<Orcamento> _orcamentos = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final orcamentos = await _storage.carregarOrcamentos();
    if (!mounted) return;
    setState(() {
      _orcamentos = orcamentos;
      _carregando = false;
    });
  }

  Future<void> _novoOrcamento() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const EditarOrcamentoScreen()),
    );
    _carregar();
  }

  Future<void> _editarOrcamento(Orcamento orcamento) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditarOrcamentoScreen(orcamento: orcamento),
      ),
    );
    _carregar();
  }

  Future<void> _gerarPdf(Orcamento orcamento) async {
    final empresa = await _storage.carregarEmpresa();
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PdfPreviewScreen(orcamento: orcamento, empresa: empresa),
      ),
    );
  }

  Future<void> _excluirOrcamento(Orcamento orcamento) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir orçamento'),
        content: Text(
          'Deseja excluir o orçamento nº ${orcamento.numero} de ${orcamento.cliente}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    _orcamentos.removeWhere((o) => o.id == orcamento.id);
    await _storage.salvarOrcamentos(_orcamentos);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orçamentos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.business),
            tooltip: 'Meus dados',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DadosEmpresaScreen()),
            ),
          ),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _orcamentos.isEmpty
              ? _telaVazia()
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: _orcamentos.length,
                  itemBuilder: (context, index) {
                    final orcamento = _orcamentos[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(orcamento.numero.toString()),
                        ),
                        title: Text(
                          orcamento.cliente.isEmpty
                              ? '(sem cliente)'
                              : orcamento.cliente,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${_dataFmt.format(orcamento.data)}  •  ${_moeda.format(orcamento.total)}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.picture_as_pdf),
                              tooltip: 'Gerar PDF',
                              onPressed: () => _gerarPdf(orcamento),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              tooltip: 'Excluir',
                              onPressed: () => _excluirOrcamento(orcamento),
                            ),
                          ],
                        ),
                        onTap: () => _editarOrcamento(orcamento),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _novoOrcamento,
        icon: const Icon(Icons.add),
        label: const Text('Novo orçamento'),
      ),
    );
  }

  Widget _telaVazia() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.request_quote_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: .4),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhum orçamento ainda',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Toque em "Novo orçamento" para começar',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
