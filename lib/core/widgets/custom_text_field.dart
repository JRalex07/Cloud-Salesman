import 'package:flutter/material.dart';

class CustomTextField extends StatefulWidget {
  final String label;
  final String? placeholder;
  final TextEditingController controller;
  final bool isPassword;
  final TextInputType keyboardType;
  final IconData? prefixIcon;
  final FormFieldValidator<String>? validator;
  final int maxLines;
  final bool enabled;

  const CustomTextField({
    Key? key,
    required this.label,
    this.placeholder,
    required this.controller,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.validator,
    this.maxLines = 1,
    this.enabled = true,
  }) : super(key: key);

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: widget.controller,
          obscureText: widget.isPassword ? _obscureText : false,
          keyboardType: widget.keyboardType,
          maxLines: widget.isPassword ? 1 : widget.maxLines,
          validator: widget.validator,
          enabled: widget.enabled,
          decoration: InputDecoration(
            hintText: widget.placeholder,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            prefixIcon: widget.prefixIcon != null
                ? Icon(widget.prefixIcon, size: 20)
                : null,
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off : Icons.visibility,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  )
                : null,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}
