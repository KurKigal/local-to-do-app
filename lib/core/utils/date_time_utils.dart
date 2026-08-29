DateTime startOfDay(DateTime date) {
  return DateTime(
    date.year,
    date.month,
    date.day,
  );
}

DateTime endOfDay(DateTime date) {
  return DateTime(
    date.year,
    date.month,
    date.day,
    23,
    59,
    59,
    999,
  );
}

DateTime startOfNextDay(DateTime date) {
  return DateTime(
    date.year,
    date.month,
    date.day + 1,
  );
}

bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year &&
      a.month == b.month &&
      a.day == b.day;
}

DateTime dateOnly(DateTime date) {
  return DateTime(
    date.year,
    date.month,
    date.day,
  );
}