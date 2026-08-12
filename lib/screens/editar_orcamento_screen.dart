import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/orcamento.dart';
import '../services/pdf_service.dart';
import '../services/storage_service.dart';
import '../utils/formatters.dart';
import 'pdf_preview_screen.dart';

class EditarOrcamentoScreen extends StatefulWidget {
  final Orcamento? orcamento;

  const EditarOrcamentoScreen({super.key, this.orcamento});

  @override
  State<EditarOrcamentoScreen> createState() => _EditarOrcamentoScreenState();
}

class _EditarOrcamentoScreenState extends State<EditarOrcamentoScreen> {
  final _storage = StorageService();
  final _moeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  late final TextEditingController _clienteCtrl;
  late final TextEditingController _telefoneCtrl;
  late final TextEditingController _observacoesCtrl;
  late final TextEditingController _descontoCtrl;

  late List<ItemOrcamento> _itens;
  late bool _descontoPercentual;
  double _desconto = 0;

  bool get _editando => widget.orcamento != null;

  @override
  void initState() {
    super.initState();
    final o = widget.orcamento;
    _clienteCtrl = TextEditingController(text: o?.cliente ?? '');
    _telefoneCtrl = TextEditingController(text: o?.telefone ?? '');
    _observacoesCtrl = TextEditingController(text: o?.observacoes ?? '');
    _itens = o?.itens.map((i) => ItemOrcamento.fromJson(i.toJson())).toList() ?? [];
    _descontoPercentual = o?.descontoPercentual ?? true;
    _desconto = o?.desconto ?? 0;
    _descontoCtrl = TextEditingController(
      text: _desconto == 0
          ? ''
          : _descontoPercentual
              ? PdfService.formatarQuantidade(_desconto)
              : NumberFormat('#,##0.00', 'pt_BR').format(_desconto),
    );
  }

  @override
  void dispose() {
    _clienteCtrl.dispose();
    _telefoneCtrl.dispose();
    _observacoesCtrl.dispose();
    _descontoCtrl.dispose();
    super.dispose();
  }

  double get _subtotal => _itens.fold(0, (soma, item) => soma + item.total);

  double get _valorDesconto {
    final valor = _descontoPercentual ? _subtotal * _desconto / 100 : _desconto;
    return valor > _subtotal ? _subtotal : valor;
  }

  double get _total => _subtotal - _valorDesconto;

  static double _parseNumero(String texto) {
    return double.tryParse(texto.trim().replaceAll('.', '').replaceAll(',', '.')) ??
        double.tryParse(texto.trim().replaceAll(',', '.')) ??
        0;
  }

  Future<void> _adicionarOuEditarItem({ItemOrcamento? item, int? index}) async {
    final descricaoCtrl = TextEditingController(text: item?.descricao ?? '');
    final quantidadeCtrl = TextEditingController(
      text: item == null ? '1' : PdfService.formatarQuantidade(item.quantidade),
    );
    final valorCtrl = TextEditingController(
      text: item == null
          ? ''
          : NumberFormat('#,##0.00', 'pt_BR').format(item.valorUnitario),
    );

    final salvou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item == null ? 'Adicionar item' : 'Editar item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descricaoCtrl,
              autofocus: item == null,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Produto ou serviço',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: quantidadeCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [NumeroInputFormatter()],
                    decoration: const InputDecoration(
                      labelText: 'Qtd.',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: valorCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [MoedaInputFormatter()],
                    decoration: const InputDecoration(
                      labelText: 'Valor unitário',
                      prefixText: 'R\$ ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (salvou != true) return;
    final descricao = descricaoCtrl.text.trim();
    if (descricao.isEmpty) return;

    final novoItem = ItemOrcamento(
      descricao: descricao,
      quantidade: _parseNumero(quantidadeCtrl.text) == 0
          ? 1
          : _parseNumero(quantidadeCtrl.text),
      valorUnitario: _parseNumero(valorCtrl.text),
    );

    setState(() {
      if (index != null) {
        _itens[index] = novoItem;
      } else {
        _itens.add(novoItem);
      }
    });
  }

  Future<Orcamento?> _salvar({bool mostrarMensagem = true}) async {
    final cliente = _clienteCtrl.text.trim();
    if (cliente.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o nome do cliente.')),
      );
      return null;
    }
    if (_itens.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adicione pelo menos um item.')),
      );
      return null;
    }

    final orcamentos = await _storage.carregarOrcamentos();

    late Orcamento orcamento;
    if (_editando) {
      orcamento = widget.orcamento!;
      orcamentos.removeWhere((o) => o.id == orcamento.id);
    } else {
      orcamento = Orcamento(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        numero: await _storage.proximoNumero(),
        data: DateTime.now(),
      );
    }

    orcamento
      ..cliente = cliente
      ..telefone = _telefoneCtrl.text.trim()
      ..observacoes = _observacoesCtrl.text.trim()
      ..itens = _itens
      ..descontoPercentual = _descontoPercentual
      ..desconto = _desconto;

    orcamentos.add(orcamento);
    await _storage.salvarOrcamentos(orcamentos);

    if (mostrarMensagem && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Orçamento salvo!')),
      );
    }
    return orcamento;
  }

  Future<void> _salvarEVoltar() async {
    final orcamento = await _salvar(mostrarMensagem: false);
    if (orcamento != null && mounted) Navigator.of(context).pop();
  }

  Future<void> _gerarPdf() async {
    final orcamento = await _salvar(mostrarMensagem: false);
    if (orcamento == null) return;
    final empresa = await _storage.carregarEmpresa();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PdfPreviewScreen(orcamento: orcamento, empresa: empresa),
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editando
            ? 'Orçamento nº ${widget.orcamento!.numero}'
            : 'Novo orçamento'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Cliente
          TextField(
            controller: _clienteCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nome do cliente',
              prefixIcon: Icon(Icons.person_outline),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _telefoneCtrl,
            keyboardType: TextInputType.phone,
            inputFormatters: [TelefoneInputFormatter()],
            decoration: const InputDecoration(
              labelText: 'Telefone (opcional)',
              prefixIcon: Icon(Icons.phone_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),

          // Itens
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Itens',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: () => _adicionarOuEditarItem(),
                icon: const Icon(Icons.add),
                label: const Text('Adicionar'),
              ),
            ],
          ),
          if (_itens.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Nenhum item adicionado',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          ..._itens.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(item.descricao),
                subtitle: Text(
                  '${PdfService.formatarQuantidade(item.quantidade)} x ${_moeda.format(item.valorUnitario)}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _moeda.format(item.total),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: () => setState(() => _itens.removeAt(index)),
                    ),
                  ],
                ),
                onTap: () => _adicionarOuEditarItem(item: item, index: index),
              ),
            );
          }),
          const SizedBox(height: 24),

          // Desconto
          const Text(
            'Desconto',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  // A chave força a recriação do campo ao trocar % <-> R$,
                  // para aplicar o formatador correto.
                  key: ValueKey(_descontoPercentual),
                  controller: _descontoCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    if (_descontoPercentual)
                      NumeroInputFormatter()
                    else
                      MoedaInputFormatter(),
                  ],
                  decoration: InputDecoration(
                    labelText: _descontoPercentual
                        ? 'Desconto em %'
                        : 'Desconto em R\$',
                    prefixIcon: Icon(_descontoPercentual
                        ? Icons.percent
                        : Icons.attach_money),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (texto) =>
                      setState(() => _desconto = _parseNumero(texto)),
                ),
              ),
              const SizedBox(width: 12),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('%')),
                  ButtonSegment(value: false, label: Text('R\$')),
                ],
                selected: {_descontoPercentual},
                onSelectionChanged: (selecao) => setState(() {
                  _descontoPercentual = selecao.first;
                  _descontoCtrl.clear();
                  _desconto = 0;
                }),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Observações
          TextField(
            controller: _observacoesCtrl,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Observações (opcional)',
              hintText: 'Ex.: Orçamento válido por 15 dias.',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 24),

          // Resumo
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _linhaResumo('Subtotal', _moeda.format(_subtotal)),
                  if (_valorDesconto > 0)
                    _linhaResumo(
                        'Desconto', '- ${_moeda.format(_valorDesconto)}'),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TOTAL',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _moeda.format(_total),
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Ações
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _salvarEVoltar,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Salvar'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _gerarPdf,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Gerar PDF'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _linhaResumo(String rotulo, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(rotulo), Text(valor)],
      ),
    );
  }
}
