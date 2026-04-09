import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/reminder_offset.dart';
import '../theme/app_colors.dart';

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
    return DropdownButtonHideUnderline(
      child: DropdownButton<ReminderOffset>(
        value: selectedOffset,
        isExpanded: true,
        icon: Icon(
          Icons.expand_more_rounded,
          color: enabled ? AppColors.textSecondary : AppColors.textTertiary,
          size: 20,
        ),
        dropdownColor: AppColors.lightBackground3,
        style: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: enabled ? AppColors.textPrimary : AppColors.textTertiary,
        ),
        onChanged: enabled ? (v) => onChanged(v!) : null,
        items: ReminderOffset.values.map((offset) {
          final isSelected = offset == selectedOffset;
          return DropdownMenuItem<ReminderOffset>(
            value: offset,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 6, height: 6,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? AppColors.warning
                          : Colors.transparent,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.warning
                            : AppColors.textTertiary,
                        width: 1.5,
                      ),
                    ),
                  ),
                  Text(
                    offset.label,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w500
                          : FontWeight.w400,
                      color: isSelected
                          ? AppColors.warning
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}