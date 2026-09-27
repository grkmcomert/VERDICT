const Duration _turkeyUtcOffset = Duration(hours: 3);

String _twoDigits(int value) => value.toString().padLeft(2, '0');

String formatTurkeyTimestamp(DateTime value) {
  final DateTime trNow = value.toUtc().add(_turkeyUtcOffset);
  return '${_twoDigits(trNow.day)}-'
      '${_twoDigits(trNow.month)}-'
      '${trNow.year.toString().padLeft(4, '0')} '
      '${_twoDigits(trNow.hour)}.'
      '${_twoDigits(trNow.minute)}.'
      '${_twoDigits(trNow.second)}';
}

String nowTurkeyIso8601() => formatTurkeyTimestamp(DateTime.now());
