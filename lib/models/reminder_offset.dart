enum ReminderOffset {
  oneDay(1, '1 Day'),
  sevenDays(7, '7 Days'),
  fifteenDays(15, '15 Days'),
  thirtyDays(30, '30 Days');

  final int days;
  final String label;

  const ReminderOffset(this.days, this.label);

  static ReminderOffset fromDays(int days) {
    return ReminderOffset.values.firstWhere(
      (e) => e.days == days,
      orElse: () => ReminderOffset.sevenDays,
    );
  }
}
