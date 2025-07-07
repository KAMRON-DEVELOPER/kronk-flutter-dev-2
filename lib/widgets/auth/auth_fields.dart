import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kronk/constants/my_theme.dart';
import 'package:kronk/riverpod/general/theme_provider.dart';
import 'package:kronk/utility/dimensions.dart';

class CodeInputWidget extends ConsumerStatefulWidget {
  final void Function(String) onCodeEntered;

  const CodeInputWidget({super.key, required this.onCodeEntered});

  @override
  ConsumerState<CodeInputWidget> createState() => _CodeInputWidgetState();
}

class _CodeInputWidgetState extends ConsumerState<CodeInputWidget> {
  final List<TextEditingController> _controllers = List.generate(4, (int index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (int index) => FocusNode());

  @override
  void dispose() {
    for (TextEditingController controller in _controllers) {
      controller.dispose();
    }
    for (FocusNode focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _handleCodeChange() {
    String code = _controllers.map((TextEditingController controller) => controller.text.trim()).join();

    if (code.length == 4) {
      widget.onCodeEntered(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    final MyTheme theme = ref.watch(themeNotifierProvider);
    final dimensions = Dimensions.of(context);
    double fieldSize = dimensions.buttonHeight1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(
        4,
        (int index) => SizedBox(
          width: fieldSize,
          height: fieldSize,
          child: TextField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            maxLength: 1,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: TextStyle(fontSize: 28, color: theme.secondaryText),
            showCursor: false,
            onChanged: (String value) {
              if (value.isNotEmpty) {
                if (index < 3) {
                  _focusNodes[index + 1].requestFocus();
                } else {
                  _focusNodes[index].unfocus();
                }
              } else if (value.isEmpty && index > 0) {
                _focusNodes[index - 1].requestFocus();
              }

              _handleCodeChange();
            },
            decoration: InputDecoration(
              counterText: '',
              contentPadding: EdgeInsets.symmetric(vertical: (fieldSize - 40) / 2),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: theme.secondaryText.withAlpha(128)),
                borderRadius: BorderRadius.circular(fieldSize / 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: theme.secondaryText, width: 2),
                borderRadius: BorderRadius.circular(fieldSize / 2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
