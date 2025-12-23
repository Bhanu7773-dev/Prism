class MoonUtils {
  /// Calculate moon phase (0.0 to 1.0)
  /// 0.0 = New Moon
  /// 0.25 = First Quarter
  /// 0.5 = Full Moon
  /// 0.75 = Last Quarter
  /// 1.0 = New Moon
  static double getMoonPhase(DateTime date) {
    int year = date.year;
    int month = date.month;
    int day = date.day;

    if (month < 3) {
      year--;
      month += 12;
    }

    ++month;

    double c = 365.25 * year;
    double e = 30.6 * month;
    double jd = c + e + day - 694039.09; // jd is total days elapsed
    jd /= 29.5305882; // divide by the moon cycle
    double b = (jd)
        .toInt()
        .toDouble(); // subtract integer part to leave fractional part of original jd
    jd -= b; // subtract integer part to leave fractional part of original jd
    b = (jd * 8 + 0.5).toInt().toDouble();
    b = b / 8;
    return jd;
  }

  static String getMoonPhaseName(double phase) {
    // phase is 0 to 1
    if (phase < 0.0625 || phase > 0.9375) return "New Moon";
    if (phase < 0.1875) return "Waxing Crescent";
    if (phase < 0.3125) return "First Quarter";
    if (phase < 0.4375) return "Waxing Gibbous";
    if (phase < 0.5625) return "Full Moon";
    if (phase < 0.6875) return "Waning Gibbous";
    if (phase < 0.8125) return "Last Quarter";
    return "Waning Crescent";
  }

  static String getMoonIconAsset(double phase) {
    // We will just use an index or generic name to help UI pick an icon/image
    if (phase < 0.0625 || phase > 0.9375) return "new_moon";
    if (phase < 0.4375) return "waxing";
    if (phase < 0.5625) return "full_moon";
    return "waning";
  }
}
