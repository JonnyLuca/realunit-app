import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/widgets/form/labeled_text_field.dart';

class PhoneNumberField extends StatefulWidget {
  final ValueNotifier<String?> controller;

  const PhoneNumberField({super.key, required this.controller});

  @override
  State<PhoneNumberField> createState() => _PhoneNumberFieldState();
}

class _PhoneNumberFieldState extends State<PhoneNumberField> {
  // Used only to decompose a seeded value. Input is free-form and not limited to this list.
  // `+41` stays first: it is the fallback default (`prefix ??= prefixes.first`).
  final prefixes = ['+41', '+49', '+43', '+423'];
  String? prefix;
  String? number;

  @override
  void initState() {
    super.initState();
    final value = widget.controller.value;
    // Longest first. Keep this whenever the list mixes lengths: a shorter listed
    // code that is a true prefix of a longer one would steal the match.
    final knownPrefixes = List<String>.of(prefixes)..sort((a, b) => b.length.compareTo(a.length));
    for (final p in knownPrefixes) {
      if (value != null && value.startsWith(p)) {
        prefix = p;
        number = value.substring(p.length);
        break;
      }
    }

    // A seeded value this field cannot decompose (empty, or a dial code it does not
    // recognize) must not leave `prefix` null: `updatePhoneNumber()` silently refuses
    // to write when prefix is null, and the stale value would be submitted instead of
    // what the user typed. Fall back to the first prefix; the number field starts empty,
    // so the validator still blocks submit until it is re-entered.
    prefix ??= prefixes.first;

    // A pre-filled value (e.g. an existing user's stored phone number) goes through this
    // decomposition, not through updatePhoneNumber()/onChanged. Run the same trunk-0 strip here,
    // or a legacy un-normalized number would be signed and submitted unchanged.
    updatePhoneNumber();
  }

  void updatePhoneNumber() {
    if (prefix != null && number != null) {
      // A leading trunk 0 would be signed, but the API strips it before verifying the signature.
      final national = number!.startsWith('0') ? number!.substring(1) : number;
      final value = '$prefix$national';
      widget.controller.value = value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        Padding(
          padding: const .symmetric(horizontal: 12, vertical: 4),
          child: Text(
            S.of(context).phoneNumber,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: .bold,
              height: 18 / 13,
            ),
          ),
        ),
        Row(
          crossAxisAlignment: .start,
          spacing: 10,
          children: [
            Expanded(
              flex: 3,
              child: LabeledTextField(
                initialValue: prefix?.substring(1),
                prefixText: '+',
                keyboardType: .phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                onChanged: (v) {
                  prefix = '+$v';
                  updatePhoneNumber();
                },
                hideErrorText: false,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return S.of(context).registerPhoneNumberPrefixInvalid;
                  }
                  if (!RegExp(r'^[0-9]{1,3}$').hasMatch(value)) {
                    return S.of(context).registerPhoneNumberPrefixFormat;
                  }
                  // Existence of the dial code is validated by the API (libphonenumber); the
                  // client must not gate on it — see CONTRIBUTING "the API decides".
                  return null;
                },
              ),
            ),
            Expanded(
              flex: 6,
              child: LabeledTextField(
                hintText: '791234567',
                initialValue: number,
                keyboardType: .phone,
                onChanged: (v) {
                  number = v;
                  updatePhoneNumber();
                },
                hideErrorText: false,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return S.of(context).registerPhoneNumberInvalid;
                  }
                  if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                    return S.of(context).registerPhoneNumberOnlyDigits;
                  }
                  // Length is validated by the API (libphonenumber); the client
                  // must not gate on it — see CONTRIBUTING "the API decides".
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
