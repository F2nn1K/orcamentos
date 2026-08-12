import 'dart:math';

class ItemOrcamento {
  String descricao;
  double quantidade;
  double valorUnitario;

  ItemOrcamento({
    required this.descricao,
    this.quantidade = 1,
    required this.valorUnitario,
  });

  double get total => quantidade * valorUnitario;

  Map<String, dynamic> toJson() => {
        'descricao': descricao,
        'quantidade': quantidade,
        'valorUnitario': valorUnitario,
      };

  factory ItemOrcamento.fromJson(Map<String, dynamic> json) => ItemOrcamento(
        descricao: json['descricao'] as String,
        quantidade: (json['quantidade'] as num).toDouble(),
        valorUnitario: (json['valorUnitario'] as num).toDouble(),
      );
}

class Orcamento {
  String id;
  int numero;
  String cliente;
  String telefone;
  String observacoes;
  DateTime data;
  List<ItemOrcamento> itens;

  /// Se true, [desconto] é um percentual (ex.: 10 = 10%);
  /// se false, é um valor fixo em reais.
  bool descontoPercentual;
  double desconto;

  Orcamento({
    required this.id,
    required this.numero,
    this.cliente = '',
    this.telefone = '',
    this.observacoes = '',
    required this.data,
    List<ItemOrcamento>? itens,
    this.descontoPercentual = true,
    this.desconto = 0,
  }) : itens = itens ?? [];

  double get subtotal => itens.fold(0, (soma, item) => soma + item.total);

  double get valorDesconto {
    final valor =
        descontoPercentual ? subtotal * desconto / 100 : desconto;
    return min(valor, subtotal);
  }

  double get total => subtotal - valorDesconto;

  Map<String, dynamic> toJson() => {
        'id': id,
        'numero': numero,
        'cliente': cliente,
        'telefone': telefone,
        'observacoes': observacoes,
        'data': data.toIso8601String(),
        'itens': itens.map((i) => i.toJson()).toList(),
        'descontoPercentual': descontoPercentual,
        'desconto': desconto,
      };

  factory Orcamento.fromJson(Map<String, dynamic> json) => Orcamento(
        id: json['id'] as String,
        numero: json['numero'] as int,
        cliente: json['cliente'] as String? ?? '',
        telefone: json['telefone'] as String? ?? '',
        observacoes: json['observacoes'] as String? ?? '',
        data: DateTime.parse(json['data'] as String),
        itens: (json['itens'] as List)
            .map((i) => ItemOrcamento.fromJson(i as Map<String, dynamic>))
            .toList(),
        descontoPercentual: json['descontoPercentual'] as bool? ?? true,
        desconto: (json['desconto'] as num?)?.toDouble() ?? 0,
      );
}

class DadosEmpresa {
  String nome;
  String telefone;
  String email;
  String endereco;
  String cnpj;
  String instagram;

  DadosEmpresa({
    this.nome = '',
    this.telefone = '',
    this.email = '',
    this.endereco = '',
    this.cnpj = '',
    this.instagram = '',
  });

  factory DadosEmpresa.padrao() => DadosEmpresa(
        nome: 'I-SERV Segurança Eletrônica',
        telefone: '(95) 99168-6590',
        endereco: 'Rua João Padeiro, 860 - Buritis, '
            'CEP 69.309-195 - Boa Vista - RR',
        cnpj: '57.256.951/0001-43',
        instagram: '@iserv_seguranca',
      );

  Map<String, dynamic> toJson() => {
        'nome': nome,
        'telefone': telefone,
        'email': email,
        'endereco': endereco,
        'cnpj': cnpj,
        'instagram': instagram,
      };

  factory DadosEmpresa.fromJson(Map<String, dynamic> json) => DadosEmpresa(
        nome: json['nome'] as String? ?? '',
        telefone: json['telefone'] as String? ?? '',
        email: json['email'] as String? ?? '',
        endereco: json['endereco'] as String? ?? '',
        cnpj: json['cnpj'] as String? ?? '',
        instagram: json['instagram'] as String? ?? '',
      );
}
