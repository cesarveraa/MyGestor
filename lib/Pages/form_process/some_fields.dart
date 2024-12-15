// Custom widget for SignatureField
import 'package:flutter/material.dart';

// Custom widget for DateField
class DateField extends StatefulWidget {
  final String label;

  const DateField({Key? key, required this.label}) : super(key: key);

  @override
  _DateFieldState createState() => _DateFieldState();
}

class _DateFieldState extends State<DateField> {
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final selectedDate = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime(2100),
            );
            setState(() {
              _selectedDate = selectedDate;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _selectedDate != null
                  ? "${_selectedDate!.toLocal()}".split(' ')[0]
                  : "Select a date",
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class SignatureField extends StatelessWidget {
  final String label;

  const SignatureField({Key? key, required this.label}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        Container(
          height: 150,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Text("Signature Pad (Placeholder)"),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// Custom widget for RadioField
class RadioField extends StatefulWidget {
  final String label;
  final List<dynamic> options; // Allow dynamic options for flexibility

  const RadioField({Key? key, required this.label, required this.options})
      : super(key: key);

  @override
  _RadioFieldState createState() => _RadioFieldState();
}

class _RadioFieldState extends State<RadioField> {
  String? _selectedOption;

  @override
  Widget build(BuildContext context) {
    // Ensure all options are strings
    final List<String> stringOptions =
        widget.options.map((e) => e.toString()).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        Column(
          children: stringOptions.map((option) {
            return RadioListTile<String>(
              title: Text(option),
              value: option,
              groupValue: _selectedOption,
              onChanged: (String? value) {
                setState(() {
                  _selectedOption = value;
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
