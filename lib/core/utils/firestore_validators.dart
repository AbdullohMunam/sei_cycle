void requireTrimmed(String value, String fieldName) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, fieldName, '$fieldName wajib diisi.');
  }
}

void requirePositive(num value, String fieldName) {
  if (value <= 0) {
    throw ArgumentError.value(
      value,
      fieldName,
      '$fieldName harus lebih dari 0.',
    );
  }
}

void requireNonNegative(num value, String fieldName) {
  if (value < 0) {
    throw ArgumentError.value(
      value,
      fieldName,
      '$fieldName tidak boleh negatif.',
    );
  }
}

void requireOneOf(String value, Set<String> allowed, String fieldName) {
  if (!allowed.contains(value)) {
    throw ArgumentError.value(
      value,
      fieldName,
      '$fieldName harus salah satu dari: ${allowed.join(', ')}.',
    );
  }
}
