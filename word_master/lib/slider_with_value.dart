import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SliderWithValue extends StatefulWidget {
  final int min;
  final int max;
  final int? initialValue;
  final Function(int) onChanged;

  const SliderWithValue({
    super.key,
    this.initialValue,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  State<SliderWithValue> createState() => _SliderWithValueState();
}

class _SliderWithValueState extends State<SliderWithValue> {
  int _sliderValue = 0;
  late TextEditingController _textEditingController;
  final NumberFormat _numberFormat = NumberFormat('#,##0');

  @override
  void initState() {
    super.initState();
    _sliderValue = widget.initialValue ?? widget.min;
    _textEditingController = TextEditingController();
    _textEditingController.text = _numberFormat.format(_sliderValue);
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Slider(
          value: _sliderValue.toDouble(),
          min: widget.min.toDouble(),
          max: widget.max.toDouble(),
          onChanged: (newValue) {
            setState(() {
              _sliderValue = newValue.toInt();
              widget.onChanged(_sliderValue);
              _textEditingController.text = _numberFormat.format(_sliderValue);
            });
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 60,
              child: TextField(
                controller: _textEditingController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  border: InputBorder.none, // Remove underline
                ),
                onChanged: (newValue) {
                  setState(() {
                    int? val = int.tryParse(newValue);
                    if (val == null || val < widget.min || val > widget.max) {
                      if (val != null) {
                        val = min(val, widget.max);
                        val = max(val, widget.min);
                      } else {
                        val = widget.min;
                      }
                      _textEditingController.text = _numberFormat.format(val);
                    }
                    _sliderValue = val;
                    widget.onChanged(_sliderValue);
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
