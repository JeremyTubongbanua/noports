import 'package:flutter/material.dart';
import 'package:sshnp_flutter/src/utility/constants.dart';

import '../../../../utility/sizes.dart';

class CustomTextFormField extends StatefulWidget {
  const CustomTextFormField({
    super.key,
    required this.labelText,
    this.initialValue,
    this.validator,
    this.onChanged,
    this.onSaved,
    this.hintText,
    this.width = kFieldDefaultWidth,
    this.height = kFieldDefaultHeight,
    this.isPasswordField = false,
    this.readOnly = false,
    this.toolTip = '',
  });

  final String labelText;
  final String? hintText;
  final String? initialValue;
  final String toolTip;
  final double width;
  final double height;
  final void Function(String)? onChanged;
  final void Function(String?)? onSaved;
  final String? Function(String?)? validator;
  final bool isPasswordField;
  final bool readOnly;

  @override
  State<CustomTextFormField> createState() => _CustomTextFormFieldState();
}

class _CustomTextFormFieldState extends State<CustomTextFormField> {
  bool _isPasswordVisible = false;

  void _setPasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    final bodySmall = Theme.of(context).textTheme.bodySmall!;
    return SizedBox(
      width: widget.width.toWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.labelText,
            style: bodySmall.copyWith(
              color: Colors.grey,
              fontSize: bodySmall.fontSize?.toFont,
            ),
          ),
          TextFormField(
            initialValue: widget.initialValue,
            obscureText: widget.isPasswordField && !_isPasswordVisible,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                vertical: 10.toFont,
                horizontal: 10.toFont,
              ),
              filled: true,
              fillColor: kProfileFormFieldColor,
              border: UnderlineInputBorder(
                borderRadius: BorderRadius.circular(2),
              ),
              hintText: widget.hintText,
              hintStyle: bodySmall.copyWith(
                fontSize: bodySmall.fontSize?.toFont,
              ),
              suffixIcon: widget.isPasswordField
                  ? InkWell(
                      onTap: _setPasswordVisibility,
                      child: Icon(_isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    )
                  : Tooltip(
                      message: widget.toolTip,
                      child: Icon(
                        Icons.question_mark_outlined,
                        color: kPrimaryColor,
                        size: 12.toFont,
                      ),
                    ),
              errorMaxLines: 3,
            ),
            readOnly: widget.readOnly,
            onChanged: widget.onChanged,
            onSaved: widget.onSaved,
            validator: widget.validator,
          ),
        ],
      ),
    );
  }
}
