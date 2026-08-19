import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';

class NumberField extends StatefulWidget {
  final dynamic value;
  final bool isDecimal;
  final Function(dynamic) onChanged;

  const NumberField({
    super.key,
    required this.value,
    required this.isDecimal,
    required this.onChanged,
  });

  @override
  State<NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<NumberField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final v = widget.value;
    _controller = TextEditingController(
      text: (v == 0 || v == 0.0) ? '' : v.toString(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      keyboardType: TextInputType.numberWithOptions(decimal: widget.isDecimal),
      textInputAction: TextInputAction.done,
      textAlign: TextAlign.center,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      decoration: InputDecoration(
        hintText: widget.isDecimal ? '0.0' : '0',
        hintStyle: const TextStyle(color: Colors.white24),
        filled: true,
        fillColor: AppTheme.backgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
      ),
      onChanged: (v) {
        final parsed = widget.isDecimal ? double.tryParse(v) : int.tryParse(v);
        if (parsed != null) widget.onChanged(parsed);
      },
      onSubmitted: (_) => FocusScope.of(context).unfocus(),
    );
  }
}
