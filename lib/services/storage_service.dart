import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/orcamento.dart';

class StorageService {
  static const _chaveOrcamentos = 'orcamentos';
  static const _chaveEmpresa = 'empresa';
  static const _chaveContador = 'contador_orcamentos';

  Future<List<Orcamento>> carregarOrcamentos() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_chaveOrcamentos);
    if (json == null) return [];
    final lista = jsonDecode(json) as List;
    final orcamentos = lista
        .map((o) => Orcamento.fromJson(o as Map<String, dynamic>))
        .toList();
    orcamentos.sort((a, b) => b.data.compareTo(a.data));
    return orcamentos;
  }

  Future<void> salvarOrcamentos(List<Orcamento> orcamentos) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _chaveOrcamentos,
      jsonEncode(orcamentos.map((o) => o.toJson()).toList()),
    );
  }

  Future<int> proximoNumero() async {
    final prefs = await SharedPreferences.getInstance();
    final atual = prefs.getInt(_chaveContador) ?? 0;
    final proximo = atual + 1;
    await prefs.setInt(_chaveContador, proximo);
    return proximo;
  }

  Future<DadosEmpresa> carregarEmpresa() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_chaveEmpresa);
    if (json == null) return DadosEmpresa.padrao();
    return DadosEmpresa.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  Future<void> salvarEmpresa(DadosEmpresa empresa) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chaveEmpresa, jsonEncode(empresa.toJson()));
  }
}
