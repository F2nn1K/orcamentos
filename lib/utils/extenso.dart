const _unidades = [
  '', 'um', 'dois', 'três', 'quatro', 'cinco', 'seis', 'sete', 'oito', 'nove'
];
const _dezADezenove = [
  'dez', 'onze', 'doze', 'treze', 'quatorze', 'quinze',
  'dezesseis', 'dezessete', 'dezoito', 'dezenove'
];
const _dezenas = [
  '', '', 'vinte', 'trinta', 'quarenta', 'cinquenta',
  'sessenta', 'setenta', 'oitenta', 'noventa'
];
const _centenas = [
  '', 'cento', 'duzentos', 'trezentos', 'quatrocentos', 'quinhentos',
  'seiscentos', 'setecentos', 'oitocentos', 'novecentos'
];

String _ate999(int n) {
  if (n == 0) return '';
  if (n == 100) return 'cem';
  final partes = <String>[];
  final c = n ~/ 100;
  final resto = n % 100;
  if (c > 0) partes.add(_centenas[c]);
  if (resto >= 10 && resto < 20) {
    partes.add(_dezADezenove[resto - 10]);
  } else {
    final d = resto ~/ 10;
    final u = resto % 10;
    if (d >= 2) partes.add(_dezenas[d]);
    if (u > 0) partes.add(_unidades[u]);
  }
  return partes.join(' e ');
}

String _numeroPorExtenso(int n) {
  if (n == 0) return 'zero';
  final milhoes = n ~/ 1000000;
  final milhares = (n % 1000000) ~/ 1000;
  final resto = n % 1000;

  var texto = '';
  if (milhoes > 0) {
    texto = '${_ate999(milhoes)} ${milhoes == 1 ? 'milhão' : 'milhões'}';
  }
  if (milhares > 0) {
    final parte = milhares == 1 ? 'mil' : '${_ate999(milhares)} mil';
    texto = texto.isEmpty ? parte : '$texto${resto == 0 ? ' e ' : ' '}$parte';
  }
  if (resto > 0) {
    // "e" só entra antes do último grupo quando ele é "redondo" (< 100 ou
    // múltiplo de 100): "mil e cem", mas "mil cento e cinquenta".
    final conector =
        texto.isEmpty ? '' : (resto < 100 || resto % 100 == 0 ? ' e ' : ' ');
    texto = '$texto$conector${_ate999(resto)}';
  }
  return texto;
}

/// Converte um valor em reais para texto em maiúsculas,
/// ex.: 4150.00 -> "QUATRO MIL CENTO E CINQUENTA REAIS".
String valorPorExtenso(double valor) {
  final totalCentavos = (valor * 100).round();
  final reais = totalCentavos ~/ 100;
  final centavos = totalCentavos % 100;

  final partes = <String>[];
  if (reais > 0) {
    final de = reais >= 1000000 && reais % 1000000 == 0 ? ' de' : '';
    partes.add(
        '${_numeroPorExtenso(reais)}$de ${reais == 1 ? 'real' : 'reais'}');
  }
  if (centavos > 0) {
    partes.add(
        '${_numeroPorExtenso(centavos)} ${centavos == 1 ? 'centavo' : 'centavos'}');
  }
  if (partes.isEmpty) return 'ZERO REAIS';
  return partes.join(' e ').toUpperCase();
}
