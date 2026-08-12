import 'package:flutter/material.dart';

import '../models/orcamento.dart';
import '../services/storage_service.dart';
import '../utils/formatters.dart';

class DadosEmpresaScreen extends StatefulWidget {
  const DadosEmpresaScreen({super.key});

  @override
  State<DadosEmpresaScreen> createState() => _DadosEmpresaScreenState();
}

class _DadosEmpresaScreenState extends State<DadosEmpresaScreen> {
  final _storage = StorageService();

  final _nomeCtrl = TextEditingController();
  final _telefoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _enderecoCtrl = TextEditingController();
  final _cnpjCtrl = TextEditingController();
  final _instagramCtrl = TextEditingController();

  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final empresa = await _storage.carregarEmpresa();
    if (!mounted) return;
    setState(() {
      _nomeCtrl.text = empresa.nome;
      _telefoneCtrl.text = empresa.telefone;
      _emailCtrl.text = empresa.email;
      _enderecoCtrl.text = empresa.endereco;
      _cnpjCtrl.text = empresa.cnpj;
      _instagramCtrl.text = empresa.instagram;
      _carregando = false;
    });
  }

  Future<void> _salvar() async {
    await _storage.salvarEmpresa(DadosEmpresa(
      nome: _nomeCtrl.text.trim(),
      telefone: _telefoneCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      endereco: _enderecoCtrl.text.trim(),
      cnpj: _cnpjCtrl.text.trim(),
      instagram: _instagramCtrl.text.trim(),
    ));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Dados salvos!')),
    );
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _telefoneCtrl.dispose();
    _emailCtrl.dispose();
    _enderecoCtrl.dispose();
    _cnpjCtrl.dispose();
    _instagramCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meus dados')),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Estes dados aparecem no cabeçalho do PDF do orçamento.',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nomeCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nome da empresa ou profissional',
                    prefixIcon: Icon(Icons.business),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _telefoneCtrl,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [TelefoneInputFormatter()],
                  decoration: const InputDecoration(
                    labelText: 'Telefone / WhatsApp',
                    prefixIcon: Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'E-mail (opcional)',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _enderecoCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Endereço (opcional)',
                    prefixIcon: Icon(Icons.location_on_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _cnpjCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'CNPJ (opcional)',
                    prefixIcon: Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _instagramCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Instagram (opcional)',
                    prefixIcon: Icon(Icons.alternate_email),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _salvar,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Salvar'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
            ),
    );
  }
}
