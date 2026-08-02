/// Time-of-day greeting computed from the device's own local clock — must
/// match the web dashboard's wording exactly (lib/greeting.ts) so the two
/// platforms greet identically.
String timeOfDayGreeting([DateTime? now]) {
  final hour = (now ?? DateTime.now()).hour;
  final String period;
  if (hour < 12) {
    period = 'morning';
  } else if (hour < 17) {
    period = 'afternoon';
  } else {
    period = 'evening';
  }
  return 'Good $period';
}
