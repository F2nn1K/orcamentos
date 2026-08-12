import 'dart:math';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Máscara de telefone brasileiro: (99) 99999-9999 ou (99) 9999-9999.
class TelefoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var digitos = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digitos.length > 11) digitos = digitos.substring(0, 11);

    final texto = _formatar(digitos);
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }

  String _formatar(String d) {
    if (d.isEmpty) return '';
    final b = StringBuffer('(');
    b.write(d.substring(0, min(2, d.length)));
    if (d.length <= 2) return b.toString();
    b.write(') ');
    final resto = d.substring(2);
    if (resto.length <= 4) {
      b.write(resto);
    } else {
      b.write(resto.substring(0, resto.length - 4));
      b.write('-');
      b.write(resto.substring(resto.length - 4));
    }
    return b.toString();
  }
}

/// Formata o valor como moeda enquanto digita, tratando os dígitos como
/// centavos: digitar 541651 exibe 5.416,51.
class MoedaInputFormatter extends TextInputFormatter {
  static final _formato = NumberFormat('#,##0.00', 'pt_BR');

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var digitos = newValue.text.replaceAll(RegExp(r'\D'), '');
    // Remove zeros à esquerda e limita a um valor razoável (bilhões).
    digitos = digitos.replaceFirst(RegExp(r'^0+'), '');
    if (digitos.length > 12) digitos = digitos.substring(0, 12);

    if (digitos.isEmpty) return const TextEditingValue(text: '');

    final valor = int.parse(digitos) / 100;
    final texto = _formato.format(valor);
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}

/// Permite apenas dígitos e uma vírgula decimal (para quantidade e desconto %).
class NumeroInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final texto = newValue.text;
    final valido = RegExp(r'^\d*,?\d*$').hasMatch(texto);
    return valido ? newValue : oldValue;
  }
}
