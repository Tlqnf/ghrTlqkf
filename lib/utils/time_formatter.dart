String formatTime(int totalSeconds) {
  final duration = Duration(seconds: totalSeconds);
  final hours = duration.inHours.toString().padLeft(2, '0');
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$hours:$minutes:$seconds';
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
