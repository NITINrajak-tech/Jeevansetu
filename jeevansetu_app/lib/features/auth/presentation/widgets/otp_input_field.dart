import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class OtpInputField extends StatefulWidget {
  final int length;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onCompleted;

  const OtpInputField({
    super.key,
    this.length = 6,
    required this.onChanged,
    required this.onCompleted,
  });

  @override
  State<OtpInputField> createState() => _OtpInputFieldState();
}

class _OtpInputFieldState extends State<OtpInputField> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  late List<String> _code;

  @override
  void initState() {
    super.initState();
    _code = List.generate(widget.length, (index) => '');
    _controllers = List.generate(
      widget.length,
      (index) => TextEditingController(),
    );
    _focusNodes = List.generate(
      widget.length,
      (index) => FocusNode(),
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onTextChanged(int index, String value) {
    if (value.length > 1) {
      // Handle paste
      value = value.substring(value.length - 1);
      _controllers[index].text = value;
    }

    setState(() {
      _code[index] = value;
    });

    final currentCode = _code.join();
    widget.onChanged(currentCode);

    if (value.isNotEmpty) {
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        widget.onCompleted(currentCode);
      }
    } else {
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(widget.length, (index) {
        return SizedBox(
          width: 46,
          height: 54,
          child: TextField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            keyboardType: TextInputType.number,
            textAlign: Alignment.center.y > 0 ? TextAlign.center : TextAlign.center,
            style: AppTextStyles.otpDigit.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
            maxLength: 1,
            decoration: InputDecoration(
              counterText: '',
              contentPadding: EdgeInsets.zero,
              filled: true,
              fillColor: isDark ? AppColors.surfaceDarkCard : Colors.white,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: _code[index].isNotEmpty
                      ? AppColors.primary
                      : (isDark ? AppColors.borderDark : AppColors.borderLight),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: AppColors.accent,
                  width: 2,
                ),
              ),
            ),
            onChanged: (value) => _onTextChanged(index, value),
          ),
        );
      }),
    );
  }
}
