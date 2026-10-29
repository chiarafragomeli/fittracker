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
    _controller = TextEditingController(text: _formatVal(widget.value));
  }

  String _formatVal(dynamic v) {
    if (v == null || v == 0 || v == 0.0) return '';
    if (widget.isDecimal && v is num) {
      final d = (v * 4).round() / 4.0;
      if (d % 1 == 0) return d.toInt().toString();
      return d.toString();
    }
    return v.toString();
  }

  @override
  void didUpdateWidget(NumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      final newText = _formatVal(widget.value);
      if (_controller.text != newText && !_isFocused) {
        _controller.text = newText;
      }
    }
  }

  bool _isFocused = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (focused) {
        _isFocused = focused;
        if (!focused) {
          final normalized = _controller.text.replaceAll(',', '.').trim();
          final parsed = widget.isDecimal
              ? double.tryParse(normalized)
              : int.tryParse(normalized);
          if (parsed != null) {
            final finalVal = widget.isDecimal
                ? (parsed * 4).round() / 4.0
                : parsed;
            widget.onChanged(finalVal);
            _controller.text = _formatVal(finalVal);
          }
        }
      },
      child: TextField(
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
          final normalized = v.replaceAll(',', '.').trim();
          final parsed = widget.isDecimal
              ? double.tryParse(normalized)
              : int.tryParse(normalized);
          if (parsed != null) {
            final finalVal = widget.isDecimal
                ? (parsed * 4).round() / 4.0
                : parsed;
            widget.onChanged(finalVal);
          }
        },
        onSubmitted: (_) => FocusScope.of(context).unfocus(),
      ),
    );
  }
}
