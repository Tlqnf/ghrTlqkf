String formatTime(int totalSeconds) {
  final duration = Duration(seconds: totalSeconds);
  final hours = duration.inHours.toString().padLeft(2, '0');
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$hours:$minutes:$seconds';
}

String formatDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, "0");
  String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
  String twoDigitHours = twoDigits(duration.inHours);

  if (duration.inHours > 0) {
    return "$twoDigitHours시간 $twoDigitMinutes분";
  } else if (duration.inMinutes > 0) {
    return "$twoDigitMinutes분";
  } else {
    return "<1분";
  }
}

// 00:00:00 -> inSecond
int timeToInt(String time) {
  List<String> format = time.split(":");
  final int timeInSecond =
      int.parse(format[0]) * 3600 +
      int.parse(format[1]) * 60 +
      int.parse(format[2]);
  return timeInSecond;
}
