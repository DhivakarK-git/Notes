class UndoRules {
  static RegExp _undoRules = RegExp(
    r'^[a-zA-Z0-9]+$',
    multiLine: true,
  );

  static bool shouldStore(String lastStoredValue, String currentValue) {
    String changedText = "";
    if (currentValue.length > lastStoredValue.length) {
      int concurrency = 0, i = 0;
      while (i < lastStoredValue.length) {
        if (currentValue[i] != lastStoredValue[i]) {
          if (!(concurrency == 0 || concurrency == i)) break;
          changedText += currentValue[i];
          if (i + 1 < lastStoredValue.length) {
            currentValue =
                currentValue.substring(0, i) + currentValue.substring(i + 1);
            concurrency = i--;
          }
        }
        i++;
      }
      if (changedText.isEmpty)
        changedText = currentValue.substring(lastStoredValue.length);
      if (!_undoRules.hasMatch(changedText) ||
          changedText.contains(' ') ||
          changedText.contains('\n')) return true;
    } else if (currentValue.length < lastStoredValue.length) return true;

    return false;
  }
}
