import 'package:flutter/material.dart';
import '../models/reminder_offset.dart';

class ReminderOffsetDropdown extends StatelessWidget {
  final ReminderOffset selectedOffset;
  final ValueChanged<ReminderOffset> onChanged;
  final bool enabled;

  const ReminderOffsetDropdown({
    super.key,
    required this.selectedOffset,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButton<ReminderOffset>(
      value: selectedOffset,
      onChanged: enabled ? (value) => onChanged(value!) : null,
      isExpanded: true,
      items: ReminderOffset.values
          .map((offset) => DropdownMenuItem(
                value: offset,
                child: Text(offset.label),
              ))
          .toList(),
    );
  }
}
